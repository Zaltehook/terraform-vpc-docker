#!/bin/bash

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

usage (){
    echo "
          Use this script for setting up a scenario 2 VPC and N number of instances passed as an argument.

          To not save AWS keys passing the -a and -s flag will prompt you to enter the AWS Secret Key and Access Key

          usage: $0 [-as] [-c #]

            -a      Prompt for AWS Access Key ID
            -s      Prompt for AWS Secret Access Key
            -c      Enter in number of instances

          Example: $0 -a -s -c 10
          "
}


#Inputs for AWS secret
while getopts 'asc:-h' flag; do
  case "${flag}" in
    a)
        read -s -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
        echo '';;
    s)
        read -s -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
        echo '';;
    c)
        INSTANCE_COUNT=${OPTARG};;
    h)
        usage
        exit 0;;
    esac
done

[ -z $1 ] && { usage; exit 0; }

echo "The user entered $AWS_ACCESS_KEY_ID and $AWS_SECRET_ACCESS_KEY"

#Generates an SSH keypair for the docker instances to use
ssh-keygen -t rsa -f ./docker-key -C docker-key -N ""

#Pulls the required modules and initializes the terraform backend
terraform init -var aws_secret_key=${AWS_SECRET_ACCESS_KEY} -var aws_access_key=${AWS_ACCESS_KEY_ID}

#Applies the Terraform plan to create the VPC and N instances
terraform apply -auto-approve -var aws_secret_key=${AWS_SECRET_ACCESS_KEY} -var aws_access_key=${AWS_ACCESS_KEY_ID} -var instance_count=${INSTANCE_COUNT}

export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

aws autoscaling describe-auto-scaling-instances --query 'AutoScalingInstances[*].InstanceId' --output text

sleep 30
aws s3api list-objects --bucket $(cat s3-bucket-name) --query 'Contents[*].Key' --output text | tr -s '\t' '\n' | sed s/\/\!\ \g

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
