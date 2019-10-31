output "bucket_id" {
  value = aws_s3_bucket.this.id
}

output "config_backend" {
  description = "Terraform excerpt with state backend configuration."

  value = <<EOF
terraform {
  backend "s3" {
    region         = "${data.aws_region.current.name}"
    encrypt        = true
    bucket         = "${aws_s3_bucket.this.id}"
    key            = "${var.path}.tfstate"
    dynamodb_table = "${aws_dynamodb_table.lock.id}"
  }
}
EOF

}

output "config_data" {
  description = "Terraform data excerpt with state backend configuration."

  value = <<EOF
data "terraform_remote_state" "${replace(local.name_lower, "-", "_")}" {
  backend = "s3"
  config = {
    region         = "${data.aws_region.current.name}"
    encrypt        = true
    bucket         = "${aws_s3_bucket.this.id}"
    key            = "${var.path}.tfstate"
    dynamodb_table = "${aws_dynamodb_table.lock.id}"
  }
}
EOF
}
