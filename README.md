# Module for storing remote state in an S3 bucket for Terraform

This module provisions a S3 bucket for remote state storage and a DynamoDB table for state locking.

The S3 bucket is created with versioning, server-side encryption, and logging enabled. Bucket access logs are stored in separate S3 bucket.

## Usage

### Create remote state

```hcl
module "remote_state" {
  source = "https://github.com/dirgapeter/tf-remote.git?ref=0.0.1"

  project = "simple"
  environment = "dev"
}
```

See `variables.tf` for additional configurable variables.

### Remote state usage

In outputs there is **config_backend** with generated terraform configuration.

```hcl
output "config_backend" {
  description = "Backend configuration."
  value       = "${module.remote_state.config_backend}"
}
```

```shell
terraform output config_backend > backend.tf
```

After that `terraform init` must be execute to initialize backend.

For read-only access you can use output **config_data**:

```shell
terraform output config_data > backend_data.tf
```

## Manual remote state usage

**Note**: Your backend configuration cannot contain interpolated variables. This is because this configuration is initialized prior to Terraform parsing these variables.

```hcl
terraform {
  backend "s3" {
    region         = "eu-west-1"
    encrypt        = true
    bucket         = "simple-dev-tf-remote-state"
    key            = "terraform.tfstate"
    dynamodb_table = "simple-dev-tf-remote-state-lock"
  }
}
```

```hcl
data "terraform_remote_state" "state" {
  backend "s3"
  config = {
    region         = "eu-west-1"
    encrypt        = true
    bucket         = "simple-dev-tf-remote-state"
    key            = "terraform.tfstate"
    dynamodb_table = "simple-dev-tf-remote-state-lock"
  }
}
```

## Permissions

Two IAM groups are created. One for full access and one for read-only access.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| dynamodb\_billing\_mode | The DynamoDB billing mode. PAY_PER_REQUEST or PROVISIONED | string | `"PAY_PER_REQUEST"` | no |
| environment | Environment of the remote state. Also used as a prefix in names of related resources. | string | n/a | yes |
| logging\_prefix | A prefix in names for logging bucket | string | `"logs/"` | no |
| manage\_iam\_role | Defines whether this module should generate and manage iam role for access | bool | `"true"` | no |
| manage\_log\_bucket | Defines whether this module should generate and manage its own s3 bucket for logging | bool | `"true"` | no |
| path | State file name, i.e. terraform | string | `"terraform"` | no |
| project | Project of the remote state. Also used as a prefix in names of related resources. | string | n/a | yes |
| suffix | A suffix in names with delimiter '-' included | string | `"-tf-remote-state"` | no |
| tags | A map of tags to add to all resources. | map(string) | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket\_id |  |
| config\_backend | Terraform excerpt with state backend configuration. |
| config\_data | Terraform data excerpt with state backend configuration. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## License

MIT
