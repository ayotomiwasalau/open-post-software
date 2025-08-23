## Deploying an app to Kubernetes using a CI/CD pipeline 
TechTrends is an online website used as a news sharing platform, that enables consumers to access the latest news within the cloud-native ecosystem. In addition to accessing the available articles, readers are able to create new media articles and share them.

As a platform engineer, The goal of these project is to package and deploy TechTrends to Kubernetes using a CI/CD pipeline.
Tool like Helms, Github actions, ArgoCD and Docker were used.

Refer to the `argocd` folder for the argo deployment yaml, ``helm`` for the charts and manifests and ``kubenetes`` for the components defintitions. ``techtrends`` contains the Docker file and the flask application that was deployed.


#TODO
once pods are running - done
deploy app using manifest on vagrant - done

deploy app using using helm and argo cd on vagrant - done
deploy monitoring tools - prometheus, grafana, jaeger, falco, --- sentry, X loki

set up infra terraform for aws using ec2 and co - done
setup app deployment to ec2
setup monitoring deployment to ec2

setup ci for infra
setup ci for application
setup ci for monitoring


aws ec2 describe-instances \
  --instance-ids $(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names rantzapp-asg \
    --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
    --output text --region eu-west-1 --profile manager) \
  --query 'Reservations[*].Instances[*].[InstanceId,KeyName]' \
  --output table --region eu-west-1 --profile manager