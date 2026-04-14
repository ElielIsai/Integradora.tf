import boto3, os, json
 
client = boto3.client('elbv2')
 
def handler(event, context):
    # Leer el mensaje de SNS que viene de CloudWatch
    message = json.loads(event['Records'][0]['Sns']['Message'])
    alarm_name = message['AlarmName']
    new_state   = message['NewStateValue']  # 'ALARM' o 'OK'
 
    rule_arn   = os.environ['RULE_ARN']
    web_tg_arn = os.environ['WEB_TG_ARN']
    ec2_tg_arn = os.environ['EC2_TG_ARN']
    asg_name   = os.environ['ASG_NAME']
 
    if new_state == 'ALARM':
        if 'cpu' in alarm_name.lower():
            # Estrés de CPU: distribuir carga entre GNS3 y EC2
            w_web, w_ec2 = 50, 50
            motivo = "escalado por CPU alto"
        else:
            # Caída del servidor: todo a EC2
            w_web, w_ec2 = 0, 100
            motivo = "caída del servidor GNS3"
    else:
        # Servidor recuperado: regresar todo a GNS3
        w_web, w_ec2 = 100, 0
        motivo = "servidor GNS3 recuperado (failback)"
        client_asg.update_auto_scaling_group(
            AutoScalingGroupName=asg_name,
            MinSize=0,
            DesiredCapacity=0
        )
 
    print(f"Alarma: {alarm_name} | Estado: {new_state} | Motivo: {motivo}")
    print(f"Cambiando pesos → GNS3={w_web}, EC2={w_ec2}")
 
    response = client.modify_rule(
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
 
    print(f"Pesos aplicados correctamente")
    return {'statusCode': 200, 'body': f'GNS3={w_web}, EC2={w_ec2}'}
 