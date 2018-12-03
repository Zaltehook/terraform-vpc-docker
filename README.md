# terraform-vpc-docker

This is an Infrastructure As Code challenge for building a scenario 2 VPC.  It uses Terraform modules and resources to achieve this.  It will create the following AWS infrastructure: A VPC, NAT gateways, Internet gateways, subnets, security groups, elastic IPs, an autoscalling group with N number of instances, and an S3 bucket where the results of the hello world docker container will be stored.

## Getting Started

Clone this repo and run and install the following prerequisites.

### Prerequisites

* Terraform

The appropriate Terraform package for your current OS, found [here](https://www.terraform.io/downloads.html)

Linux example
```
wget https://releases.hashicorp.com/terraform/0.11.10/terraform_0.11.10_linux_amd64.zip
mkdir ~/bin/
unzip terraform_0.11.10_linux_amd64.zip -d ~/bin/
export PATH="$PATH:~/bin/"
```

* AWS CLI

Installation found [here](https://docs.aws.amazon.com/cli/latest/userguide/installing.html)

### Installing

Clone the repo to your local machine

Create an IAM programmatic access User in your AWS account with the following policy:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "sts:*",
                "iam:*",
                "s3:*",
                "autoscaling:*"
            ],
            "Resource": "*"
        }
    ]
}
```

Put the AWS Access Key and AWS Secret Key in the terraform.tfvars file

```
aws_access_key = "AKIAIOSFODNN7EXAMPLE"
aws_secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```

To launch the VPC, run the `./create-vpc.sh` script inside the repo.  For example:
```
./create-vpc.sh -c -i 4
```
This will create the VPC and 4 instances.  The script will wait until the instances launch, and then check the S3 results bucket if the docker hello world container was successful or not.

## Built With

* [Terraform](https://www.terraform.io/) - The infrastructure as code framework

## Authors

* **Colin Smith** - *Initial work* - [Zaltehook](https://github.com/Zaltehook)



