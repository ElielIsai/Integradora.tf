import boto3, os, json

client_elb = boto3.client('elbv2')

def handler(event, context):
    message    = json.loads(event['Records'][0]['Sns']['Message'])
    alarm_name = message['AlarmName']
    new_state  = message['NewStateValue']

    rule_arn   = os.environ['RULE_ARN']
    web_tg_arn = os.environ['WEB_TG_ARN']
    ec2_tg_arn = os.environ['EC2_TG_ARN']

    if new_state == 'ALARM':
        if 'cpu' in alarm_name.lower():
            w_web, w_ec2 = 50, 50
            motivo = "escalado por CPU alto"
        else:
            w_web, w_ec2 = 0, 100
            motivo = "caida del servidor GNS3"
    else:
        # OK: regresar todo a GNS3
        w_web, w_ec2 = 100, 0
        motivo = "servidor GNS3 recuperado"

    print(f"Alarma: {alarm_name} | Estado: {new_state} | Motivo: {motivo}")
    print(f"Cambiando pesos -> GNS3={w_web}, EC2={w_ec2}")

    client_elb.modify_rule(
        RuleArn=rule_arn,
        Actions=[{
            'Type': 'forward',
            'ForwardConfig': {
                'TargetGroups': [
                    {'TargetGroupArn': web_tg_arn, 'Weight': w_web},
                    {'TargetGroupArn': ec2_tg_arn, 'Weight': w_ec2},
                ],
                'TargetGroupStickinessConfig': {
                    'Enabled': True,
                    'DurationSeconds': 300
                }
            }
        }]
    )

    print("Pesos aplicados correctamente")
    return {'statusCode': 200, 'body': f'GNS3={w_web}, EC2={w_ec2}'}
