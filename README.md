# AWS instance via Terraform Cloud

Creates a dedicated VPC and one EC2 instance reachable only through AWS
Systems Manager Session Manager (no SSH, no open inbound ports, no key pair).

## Setup

1. In [main.tf](main.tf), replace the placeholders in the `cloud` block with
   your Terraform Cloud organization and workspace name:
   ```hcl
   cloud {
     organization = "HPC"
     workspaces {
       name = "ansible"
     }
   }
   ```
2. On that Terraform Cloud workspace, set `AWS_ACCESS_KEY_ID` and
   `AWS_SECRET_ACCESS_KEY` as environment variables (marked sensitive). The
   AWS provider picks them up automatically — no code changes needed.
3. Run `terraform login` locally (or push via VCS-driven runs) and queue a
   plan/apply from the Terraform Cloud workspace.

## Connecting to the instance

The AWS CLI Session Manager plugin must be installed locally, then:

```sh
aws ssm start-session --target <instance_id>
```

The exact command (with instance ID and region filled in) is printed as the
`ssm_connect_command` output after apply.

## Files

- `main.tf` — Terraform Cloud backend + AWS provider
- `vpc.tf` — dedicated VPC, public subnet, internet gateway, routing
- `iam.tf` — IAM role/instance profile attaching `AmazonSSMManagedInstanceCore`
- `ec2.tf` — security group (egress-only) and the EC2 instance
- `variables.tf` / `outputs.tf` — inputs and outputs
