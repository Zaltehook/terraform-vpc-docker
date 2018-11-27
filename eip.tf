#Creates EIPs that can can be kept an re-used outside the VPC module
resource "aws_eip" "nat" {
  count = 2
  vpc = true
}
