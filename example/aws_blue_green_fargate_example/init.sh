# aws elbv2 create-load-balancer \
#      --name bluegreen-alb \
#      --subnets subnet-abcd1234 subnet-abcd5678 \
#      --security-groups sg-abcd1234 \
#      --region us-east-1

# aws elbv2 create-target-group \
#      --name bluegreentarget1 \
#      --protocol HTTP \
#      --port 80 \
#      --target-type ip \
#      --vpc-id vpc-abcd1234 \
#      --region us-east-1

# aws elbv2 create-listener \
#      --load-balancer-arn arn:aws:elasticloadbalancing:region:aws_account_id:loadbalancer/app/bluegreen-alb/e5ba62739c16e642 \
#      --protocol HTTP \
#      --port 80 \
#      --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:region:aws_account_id:targetgroup/bluegreentarget1/209a844cd01825a4 \
#      --region us-east-1

# aws ecs create-cluster \
#      --cluster-name tutorial-bluegreen-cluster \
#      --region us-east-1
make codedeploy


aws ecs register-task-definition \
     --cli-input-json file://fargate-task.json \
     --region us-east-1

aws ecs create-service \
     --cli-input-json file://service-bluegreen.json \
     --region us-east-1

 aws elbv2 describe-load-balancers --name bluegreen-alb  --query 'LoadBalancers[*].DNSName' 

 aws deploy create-application \
     --application-name tutorial-bluegreen-app \
     --compute-platform ECS \
     --region us-east-1

aws elbv2 create-target-group \
     --name bluegreentarget2 \
     --protocol HTTP \
     --port 80 \
     --target-type ip \
     --vpc-id "vpc-0b6dd82c67d8012a1" \
     --region us-east-1

aws deploy create-deployment-group \
     --cli-input-json file://tutorial-deployment-group.json \
     --region us-east-1

aws deploy create-deployment \
     --cli-input-json file://create-deployment.json \
     --region us-east-1