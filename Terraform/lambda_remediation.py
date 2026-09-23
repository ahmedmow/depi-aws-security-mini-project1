import os
import boto3


ec2 = boto3.client("ec2")
sns = boto3.client("sns")


SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]


def lambda_handler(event, context):
    print("Received EventBridge event:")
    print(event)

    detail = event.get("detail", {})
    request_parameters = detail.get("requestParameters", {})

    group_id = request_parameters.get("groupId")

    if not group_id:
        print("Security Group ID was not found in the event.")
        return {
            "statusCode": 400,
            "message": "Security Group ID not found"
        }

    print(f"Security Group ID: {group_id}")

    response = ec2.describe_security_groups(
        GroupIds=[group_id]
    )

    revoked_rules = []

    for security_group in response.get("SecurityGroups", []):

        for permission in security_group.get("IpPermissions", []):

            ip_protocol = permission.get("IpProtocol")

            from_port = permission.get("FromPort")
            to_port = permission.get("ToPort")

            # Only TCP rules with a single port
            if ip_protocol != "tcp":
                continue

            if from_port != to_port:
                continue

            # Task 17:
            # Remove public SSH/RDP access
            if from_port not in [22, 3389]:
                continue

            for ip_range in permission.get("IpRanges", []):

                cidr_ip = ip_range.get("CidrIp")

                if cidr_ip != "0.0.0.0/0":
                    continue

                revoke_permission = {
                    "IpProtocol": "tcp",
                    "FromPort": from_port,
                    "ToPort": to_port,
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ]
                }

                print(
                    f"Revoking public TCP {from_port} "
                    f"rule from {group_id}"
                )

                ec2.revoke_security_group_ingress(
                    GroupId=group_id,
                    IpPermissions=[revoke_permission]
                )

                revoked_rules.append(
                    f"TCP {from_port} from 0.0.0.0/0"
                )

    if revoked_rules:

        message = (
            "depi-sec Lambda auto-remediation executed.\n\n"
            f"Security Group: {group_id}\n"
            "Revoked rules:\n"
            + "\n".join(revoked_rules)
        )

        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="depi-sec Security Group Auto-Remediation",
            Message=message
        )

        print("SNS notification sent.")

    else:
        print(
            "No dangerous public TCP 22 or TCP 3389 rule found."
        )

    return {
        "statusCode": 200,
        "security_group_id": group_id,
        "revoked_rules": revoked_rules
    }