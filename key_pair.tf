#Uploads the newly created ssh key for use
resource "aws_key_pair" "docker-key" {
    key_name = "${var.key_name}"
    public_key = "${file("${var.path_to_public_key}")}"
}
