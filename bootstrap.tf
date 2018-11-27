data "template_file" "bootstrap" {
    template = "${file("scripts/start-docker.sh")}"

    vars {
        s3_bucket_name = "${aws_s3_bucket.docker.id}"
    }
}


data "template_cloudinit_config" "docker" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "start-docker.sh"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.bootstrap.rendered}"
  }

}
