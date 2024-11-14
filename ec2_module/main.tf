resource "aws_instance" "this" {
  ami                    = "ami-04dd23e62ed049936"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [var.sg]
  subnet_id = var.sub_id 
  tags = {
    Name = var.name
  }
}