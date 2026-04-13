import boto3, os

def handler(event, context):
    client = boto3.client('elbv2')
    
    # Cuando GNS3 cae: 0% GNS3, 100% EC2
    client.modify_listener(
        ListenerArn=os.environ['LISTENER_ARN'],
        DefaultActions=[{
            'Type': 'forward',
            'ForwardConfig': {
                'TargetGroups': [
                    {'TargetGroupArn': os.environ['WEB_TG_ARN'], 'Weight': 0},
                    {'TargetGroupArn': os.environ['EC2_TG_ARN'], 'Weight': 100},
                ]
            }
        }]
    )
    return {'statusCode': 200}