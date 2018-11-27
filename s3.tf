resource "aws_s3_bucket" "docker" {
    bucket_prefix = "results-"
    acl = "private"

    tags {
        Name    = "Terraform docker test results"
        Environment = "dev"
        Terraform = "true"
    }
    provisioner "local-exec" {
        command = "echo ${aws_s3_bucket.docker.id} > s3-bucket-name"
    }
}

