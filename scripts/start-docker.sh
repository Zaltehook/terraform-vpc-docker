#!/bin/bash

yum update -y
while [[ $(echo $?) != 0 ]]; do
    sleep 5
    yum update -y
done
yum install -y docker
service docker start
docker pull hello-world
docker run hello-world
if [[ $(echo $?) = 0 ]]; then
    aws s3api put-object --bucket ${s3_bucket_name} --key success/$(curl 169.254.169.254/latest/meta-data/instance-id)
else
    aws s3api put-object --bucket ${s3_bucket_name} --key fail/$(curl 169.254.169.254/latest/meta-data/instance-id)
fi
