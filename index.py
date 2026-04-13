import boto3, os

def handler(event, context):
    client = boto3.client('elbv2')
    
    # Modificar la REGLA (no el listener default) que tiene los pesos
    # El ARN de la regla viene de una variable de entorno
    client.modify_rule(
        RuleArn=os.environ['RULE_ARN'],
        Actions=[{
            'Type': 'forward',
            'ForwardConfig': {
                'TargetGroups': [
                    {'TargetGroupArn': os.environ['WEB_TG_ARN'], 'Weight': 0},
                    {'TargetGroupArn': os.environ['EC2_TG_ARN'], 'Weight': 100},
                ],
                'TargetGroupStickinessConfig': {
                    'Enabled': True,
                    'DurationSeconds': 300
                }
            }
        }]
    )
    print("Pesos cambiados: GNS3=0, EC2=100")
    return {'statusCode': 200}