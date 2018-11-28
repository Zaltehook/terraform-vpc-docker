#!/bin/bash

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

usage (){
    echo "
          Use this script for setting up a scenario 2 VPC and N number of instances passed as an argument

          Requirements: Enter the AWS Secret and Access Key in terraform.tfvars file

          usage: $0 [-c|D] [-i #]

            -c      Flag for creating the VPC and instances
            -i      Enter in number of instances

            OR

            -D      Flag for deleting the VPC and instances

            OPTIONAL

            -r      Region (Defaults to us-east-1)

          Example: $0 -c -i 10
          "
}


REGION=us-east-1

#Inputs for AWS secret
while getopts 'cDi:-hr:' flag; do
  case "${flag}" in
    c)
        CREATE=true
        echo '';;
    D)
        CREATE=false
        echo '';;
    i)
        INSTANCE_COUNT=${OPTARG};;
    r)
        REGION=${OPTARG,,};;
    h)
        usage
        exit 0;;
    esac
done

[ -z $1 ] && { usage; exit 0; }

export AWS_ACCESS_KEY_ID=$(cat terraform.tfvars | grep access | grep -Po '(?<=")[^"]*(?=")')
export AWS_SECRET_ACCESS_KEY=$(cat terraform.tfvars | grep secret | grep -Po '(?<=")[^"]*(?=")')

if [[ $CREATE == "true" ]]; then
    #Generates an SSH keypair for the docker instances to use
    ssh-keygen -t rsa -f ./docker-key -C docker-key -N ""

    #Pulls the required modules and initializes the terraform backend
    terraform init -var-file=terraform.tfvars

    #Applies the Terraform plan to create the VPC and N instances
    terraform apply -auto-approve -var-file=terraform.tfvars -var instance_count=${INSTANCE_COUNT} -var aws_region=$REGION

    echo "The following instances were created"
    aws --region $REGION autoscaling describe-auto-scaling-instances --query 'AutoScalingInstances[*].InstanceId' --output text | tr -s '\t' '\n'

    echo -e "\nWaiting 30s for cloud-init to finish and report results..."
    sleep 30
    echo "The following instances succeeded or failed"
    aws s3api --region $REGION list-objects --bucket $(cat s3-bucket-name) --query 'Contents[*].Key' --output text | tr -s '\t' '\n'

elif [[ $CREATE == "false" ]]; then

    #Empties the bucket so it can be deleted
    for i in $(aws --region $REGION s3api list-objects --bucket $(cat s3-bucket-name) --query 'Contents[*].Key' --output text); do aws --region $REGION s3api delete-object --bucket $(cat s3-bucket-name) --key $i; done

    terraform destroy -force -var-file=terraform.tfvars -var aws_region=$REGION

fi

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
