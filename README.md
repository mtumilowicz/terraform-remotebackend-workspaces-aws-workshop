# terraform-workshop
* references
    * https://discuss.hashicorp.com/t/terraform-0-14-the-dependency-lock-file/15696
    * https://medium.com/@business_99069/terraform-count-vs-for-each-b7ada2c0b186
    * https://hub.docker.com/r/danjellz/http-server
    * https://discuss.hashicorp.com/t/validate-list-object-variables/18291/2
    * https://github.com/morethancertified/mtc-terraform
    * https://github.com/edgar-anascimento/terraform-localstack-setup
    * [[#122​] Terraform i AWS - odtwarzalna infrastruktura w 10 minut - Maciej Rostański](https://www.youtube.com/watch?v=87wIafVYK9I)
    * [When Terraform alone isn't enough - Marcin Żbik](https://www.youtube.com/watch?v=nR1U9sdcR3k)
    * [Version-Controlled Infrastructure with GitHub & Terraform with Seth Vargo](https://www.youtube.com/watch?v=2TWqi7dLSro)
    * [[#128​] Infrastructure as a Code - AWS + Terraform + Ansible - Daniel Kossakowski](https://www.youtube.com/watch?v=BSHpZcy-BAo)
    * [DevOps Crash Course (Docker, Terraform, and Github Actions)](https://www.youtube.com/watch?v=OXE2a8dqIAI)
    * [Terraform Course - Automate your AWS cloud infrastructure](https://www.youtube.com/watch?v=SLB_c_ayRMo)
    * [Terraform for AWS - Beginner to Expert 2021 (0.12)](https://www.udemy.com/course/terraform-fast-track)
    * [Learn DevOps: Infrastructure Automation With Terraform](https://www.udemy.com/course/learn-devops-infrastructure-automation-with-terraform)
    * [More than Certified in Terraform](https://www.udemy.com/course/terraform-certified/)
    * [Terraform in Action](https://www.manning.com/books/terraform-in-action)
    * https://www.packer.io/intro
    * https://www.terraform.io/docs
    * https://acloudguru.com/hands-on-labs/exploring-terraform-state-functionality
    * https://www.andreagrandi.it/2017/08/25/getting-latest-ubuntu-ami-with-terraform/
    * https://learn.hashicorp.com/tutorials/terraform
    * https://pilotcoresystems.com/insights/what-are-terraform-workspaces
    * https://medium.com/@diogok/terraform-workspaces-and-locals-for-environment-separation-a5b88dd516f5
    * https://shanidgafur.github.io/blog/terraform-workspaces-for-multi-region-deployment

## preface
* goals of this workshops
    * remote backends
    * workspaces
    * aws with localstack
    * secrets management
* plan for the workshop
    * fill the scaffolds and follow the hints in directories:
        1. pt1_remotebackend
        1. pt2_workspaces
        1. pt3_aws
    * note that `docker provider` differs for unix and windows os:
        ```
        provider "docker" {
          // host = "unix:///var/run/docker.sock" // macos
          // host = "npipe:////.//pipe//docker_engine" // windows
        }
        ```
        you should uncomment appropriate one

## remote backend
* in short: where state is stored
    * example: local or S3
* when using a non-local backend, terraform will not persist the state anywhere on disk
    * major benefit: no sensitive values persisted to disk
    * remark: when writing state to the backend fails - terraform will write the state locally
* major benefit: keep sensitive information off disk
    * for example: when you create a database, the initial database password will be in the state file
* increases security
    * for example: s3 supports encryption at rest, authentication & authorization

## workspaces
* allows to create different and independent states on the same configuration
* equivalent of renaming state file
    * when working in one workspace, changes will not affect resources in another workspace
* initially the backend has only one workspace: "default"
* use-cases
    * testing
        * for example: a new temporary workspace to freely experiment with changes without affecting the default workspace
    * multi-region deployment
        ```
        provider "aws" {
         region = "${terraform.workspace}"
        }
        ```
* workspaces alone are not a suitable tool for system decomposition
    * cannot be used for a "fully isolated" setup for multiple environments (staging / testing / prod)
    * each subsystem should have its own separate configuration and backend (complete separation)
        * for complete isolation, it's best to create multiple AWS accounts, and use one account for dev, another
        for prod, and a third one for billing

## secrets management
* terraform handles a lot of secrets - more than most people realize
    * example: database passwords, personal identification information (PII), encryption keys...
    * sensitive information will inevitably find its way into Terraform no matter what you do
        * you should treat the state file as sensitive and secure it accordingly
            * gate who has access to it
            * encryption at rest
            * encrypting data in transit (SSL/TLS)
            * most of it enabled by default for S3
* all sensitive data is put in the state file (stored as plaintext JSON)
* only three configuration blocks can store stateful information (sensitive or otherwise)
    * resources
    * data sources
    * and output values
    * other kinds of configuration blocks do not store stateful data
        * but may leak sensitive information in other ways
        * at least: not saving sensitive information to the state file
* example
    * https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
    ```
    resource "aws_db_instance" "default" {
      allocated_storage    = 10
      engine               = "mysql"
      engine_version       = "5.7"
      instance_class       = "db.t3.micro"
      name                 = "mydb"
      username             = "foo" // required
      password             = "foobarbaz" // required
      parameter_group_name = "default.mysql5.7"
      skip_final_snapshot  = true
    }
    ```
* static secrets
    * are sensitive values that do not change (at least not often)
    * in general: most secrets
    * two major ways to pass static secrets into Terraform
        * as environment variables
            * should be used whenever possible
            * example: aws-vault
            * digression: in RDS database you have to set username and password as Terraform variables - there is no
            option for environment variables
        * as Terraform variables (a very bad idea)
            * example
                ```
                provider "aws" {
                  region = "us-west-2"
                  access_key = var.access_key // required, but can be sourced from the AWS_ACCESS_KEY_ID environment variable
                  secret_key = var.secret_key // required, but can be sourced from the AWS_SECRET_ACCESS_KEY environment variable
                }
                ```
    * sensitive variables can be defined by setting the sensitive argument to true
        * example
            ```
            variable "db_username" {
              description = "Database administrator username"
              type        = string
              sensitive   = true
            }
            ```
        * appear in state but are redacted from CLI output
        * prevents users from accidentally exposing secrets but does not stop motivated individuals
            * you could just redirects var.db_username to local _file