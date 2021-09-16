# terraform-workshop
* references
    * https://www.terraform.io/docs/language/dependency-lock.html
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
    * https://www.terraform.io/docs/language/state/backends.html

## preface
* goals of this workshops
    * introduction to infrastructure as a code
    * introduction to terraform
        * provider, resources, data, variables, outputs
        * for_each, count
        * modules
        * remote backends and workspaces
        * aws with localstack
* plan for the workshop:
    1. pt1_basics
    1. pt2_modules
    1. pt3_remotebackend
    1. pt4_aws

## infra as a code
* packer
  * commandline tool that can build AWS AMIs based on templates
  * instead of installing the software after booting up an instance, you
  can create an AMI with all the necessary software on
  * speed up boot times of instances
  * common approach when you run a horizontally scaled app layer or a
  cluster
  * template
    * builders (amazon-ebs)
    * provisioners (shell, scripts/install_software.sh)

## introduction
* variables
    * variables can be validated
    * variables can be declared sensitive
      * they exist in the state
      * how to set variable:
        * solution1: terraform plan -var variable-name=value
        * solution2: export TF_VAR_variable-name=value
        * solution3: declare in .tfvars
          * terraform plan --var-file west.tfvars
* tfstate
    ```
    {
      "version": 4,
      "terraform_version": "1.0.5",
      "serial": 10,
      "lineage": "d7fe6d32-593e-60c6-52f2-dff37b956408",
      "outputs": {},
      "resources": []
    }
    ```
    * The "lineage" is a unique ID assigned to a state when it is created. If a lineage is different, then it means the states were created at different times and its very likely you're modifying a different state. Terraform will not allow this.
    * Every state has a monotonically increasing "serial" number. If the destination state has a higher serial, Terraform will not allow you to write it since it means that changes have occurred since the state you're attempting to write.
    * terraform state
      * list - list the state
      * mv - move an item in the state (or rename)
      * pull - pull current state and output to stdout
      * push - push local file to statefile
      * replace-provider - replace in the state file
      * rm - remove item from state
      * show
      * when you will need to modify the state
        * when upgrading between versions
        * when you want to rename a resource without recreating it
        * when you want to stop managing but don't want to destroy

* dependency lock file
* providers
  * go to hidden files: .terraform providers ... and find binary of the provider
* resources and datasources
  * datasources allow data to be fetched or computed from outside of the terraform
    * example: AMI list that can be filtered to extract AMI IDs
    * data "aws_ami" "ubuntu"
    * can be addressed: data.<RESOURCE TYPE>.<NAME>.<ATTRIBUTE>
  * resources describe one or more infrastructure objects
    * ec2, vpc, database
    * can be addresses: <RESOURCE TYPE>.<NAME>.<ATTRIBUTE>
* 3 types of variables
  * input
    * could have validation block
  * output
  * local
    * like temporary variables
    * used for calculations, concatenations, conditionals
      * results are used later within resources
* provisioners VM
  * local-provisioner (execute something locally after spinning up a VM)
  * remote-provisioner (execute something remote on the VM)
  * packer (build AMI, then launch AMI)
  * cloud init (user_data in aws_instance)
    * will run after ec2 instance will launch for the first time
* terraform core contains language interpreter, the CLI and how to interact with providers
  * it doesn't contain the code to interact with the API of the cloud providers to create resources
  * that code is in providers, which be installed separately when invoking "terraform init"
* lockfile
  * from 0.14 terraform will use a provider dependency lockfile
  * file created when terraform init
  * is called: .terraform.lock.hcl
  * file tracks versions of providers and modules
  * should be committed to git
  * when committed to git, re-runs of terraform will use the same
  provider/module versions you used during execution (when terraform is ran
  by other members of your team or using automation)
  * terraform stores checksums of the archive to be able to verify the checksum
  * will update the lockfile when you make changes to the provider requirements
* count vs for_each
    * count
      * module xxx { count = ["instance1", "instance2", "instance3"] }
        * module.xxx_count[0].resource
        * module.xxx_count[1].resource
        * module.xxx_count[2].resource
        * indexed by index in the list; if you remove instance2, resource3 will be recreated
    * for each
      * is a map where you could define your own key
      * locals { mymap = { Instance1 = ..., Instance2 = ... } }
      * module xxx { for_each = local.mymap instance_name = each.key }}


## standard operations
* terraform plan with export -> terraform apply with that plan



## module
* information flow
  * powerful way to reuse code
  * use external modules or write modules yourself
  * https://registry.terraform.io/namespaces/terraform-aws-modules
    * https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest

## remote backend
* create resources first, then uncomment the backend cofiguration, then init
    * workspaces should be discussed here
* When using a non-local backend, Terraform will not persist the state anywhere on disk except in the case of a non-recoverable error where writing the state to the backend failed. This behavior is a major benefit for backends: if sensitive values are in your state, using a remote backend allows you to use Terraform without that state ever being persisted to disk.
* In the case of an error persisting the state to the backend, Terraform will write the state locally. This is to prevent data loss.
* Backends are responsible for supporting state locking if possible.
    * Terraform will lock your state for all operations that could write state.
    * This prevents others from acquiring the lock and potentially corrupting your state.
* Terraform has a force-unlock command to manually unlock the state if unlocking failed.
    * If you unlock the state when someone else is holding the lock it could cause multiple writers.
    * To protect you, the force-unlock command requires a unique lock ID. Terraform will output this lock ID if unlocking fails
  * can keep sensitive information off disk
  * s3 supports encryption at rest, authentication & authorization
  * dynamodb locking
    * sometimes when terraform crashes or users internet connection breaks during terraform apply
    the lock will stay
      * terraform force-unlock <id>
      * this command will not touch the state, it'll just remove the lock file, so it's safe
      as long as nobody is really still doing an apply
  * you need to be aware that secrets can be stored in your state file
    * for example, when you create a database, the initial database password will be in the state file
    * if you have a remote state, then it will not be stored on disk locally (it will only be kept in memory when
    you run terraform apply)
      * increases security
  * make sure only terraform administrators have access to s3 bucket where the state resides

## workspaces
  * when you create a new workspace, you start with empty state
  * cannot be used for a "fully isolated" setup that you'd need when you want
  to run terraform for multiple environments (staging / testing / prod)
  * even though a workspace gives you an empty state you're still using the same state
  the same backend configuration (workspaces are the technically equivalent of renaming your state file)
  * in real world scenarios you typically use re-usable modules and really split out the state over
  multiple backends (for example your staging backend will be on s3 on your staging aws account and your
  prod backend will be in an s3 bucket on the prod aws account, following multi-account strategy)



## aws
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 ec2 describe-instances


1. if you run any terraform command without init before:
    terraform validate
    ╷
    │ Error: Could not load plugin
    │
    │
    │ Plugin reinitialization required. Please run "terraform init".
1. https://www.terraform.io/docs/language/dependency-lock.html
    A Terraform configuration may refer to two different kinds of external dependency that come from outside of its own codebase:

    Providers, which are plugins for Terraform that extend it with support for interacting with various external systems.
    Both of these dependency types can be published and updated independently from Terraform itself and from the
    configurations that depend on them.
    For that reason, Terraform must determine which versions of those dependencies are potentially compatible with
    the current configuration and which versions are currently selected for use.

    Version constraints within the configuration itself determine which versions of dependencies are potentially
    compatible, but after selecting a specific version of each dependency Terraform remembers the decisions
    it made in a dependency lock file so that it can (by default) make the same decisions again in future.

    At present, the dependency lock file tracks only provider dependencies. Terraform does not remember version
    selections for remote modules, and so Terraform will always select the newest available module version
    that meets the specified version constraints. You can use an exact version constraint to ensure that
    Terraform will always select the same module version.

    You should include this file in your version control repository so that you can discuss potential changes
    to your external dependencies via code review, just as you would discuss potential changes to your
    configuration itself.

    When terraform init is working on installing all of the providers needed for a configuration, Terraform considers
    both the version constraints in the configuration and the version selections recorded in the lock file.

    If a particular provider has no existing recorded selection, Terraform will select the newest available version
    that matches the given version constraint, and then update the lock file to include that selection.

    If a particular provider already has a selection recorded in the lock file, Terraform will always re-select
    that version for installation, even if a newer version has become available.

    Terraform will also verify that each package it installs matches at least one of the checksums it previously
    recorded in the lock file, if any, returning an error if none of the checksums match

    This separates the idea of which provider versions a module/configuration is compatible with (the version
    constraints) from which versions a configuration is currently using (the lock file).

    It will check the downloaded provider packages against the checksums it saw the first time you saw the
    provider, raising an error if any package does not match.
        This therefore implements a “trust on first use” model where you can, if you wish, perform audits or
        other checks on new provider versions you intend to use and then use the lock file to remember the
        checksums of the packages you audited, so you’ll know if the upstream provider package is modified
        in some way after you reviewed it.
1. .terraform directory is in turn just a local cache of remote the items the lock file describes.
1. http://127.0.0.1:8080/test.html
1. for_each vs count
    * count
        * In the past (before Terraform 0.12.6) the only way to create multiple instances of the same resource was to use a count parameter.
        * Quite often there was some list defined somewhere and we’d create so many instances of a resource as many elements the list has
        * Now, count is sensible for any changes in list order, this means that if for some reason order of the list is changed, terraform will force replacement of all resources of which the index in the list has changed
        * In example below I added one more element to the list (as first element, at list index 0) and this is what terraform is trying to do as a result:
        * Not only my new resource is getting added, but ALL the other resources are being recreated, this is a DISASTER
    * for_each
        * It takes a map / set as input and uses the key of a map as an index of instances of created resource.
1. show why validation is important (internal_port - if you change from 8080 it will not work)
1. The [*] and .* operators are intended for use with lists only. Because this resource uses for_each rather than count, its value in other expressions is a map, not a list.

* immutable infrastructure vs mutable
  * jak mamy serwery to nikt tam nie ma prawa zainstalować nowszej paczki
        * docker dobrym przykładem
  * mutable - serwer ewaluuje
* infrastructure as a code
    * recipe for servers; someone comes to you and say show me your servers and you show him yaml file
* idempotentność - niezależnie ile razy uruchomimy skrypt to ma za zadanie sprawdzić co jest i ewentualnie nanieść
  poprawki
  * przeciwieństwo zwykłych skryptów które uruchomione wiele razy powodują problemy
* terraform can manage things that are beyond the traditional scope of what we would consider
  infrastructure
  * typically infrastructure = compute, networking, storage
  * what can provide more? github teams and permissions
* terraform is separated into 3 separate parts
  * core
        * parser
        * config
        * dag
        * schema
        * operations: diff(), apply(), refresh()
  * providers
        * resource
        * operations: CRUD
  * upstream
        * terraform not control but interaction takes place
        * actually creates resources - terraform does not create resources - it makes
        google cloud api to create it
        * api (google cloud api, github api, ...)
        * services
  * if you write your provider you have to implement CRUD and terraform makes
    hard decisions for you (what operation invoke)
* plan v apply
    * separates plan phase from apply phase
    * terraform plan is closest to test
* state
    * how terraform knows what operations to take
* tf apply
    * first output: Acquiring state lock. - locks in case of concurrent access
* commands
    * terraform init
    * terraform apply
      * --auto-approve
    * terraform plan
    * terraform destroy
    * terraform refresh
* general
  ```
  THING "TYPE" "NAME" {
    [ATTRIBUTES...]
  }
  ```
* components
  * data
    * poznać adres IP maszyny o nazwie...
  * variable
  * provider
  * resource
  * provisioner
  * output
* terraform.tfstate (example: S3 + change log DynamoDB)
* główni konkurenci
    * CloudFormation
    * Vagrant
    * Ansible
* trigger -> terraform: provision server -> update software -> Ansible: apply configuration -> use it
* https://learn.hashicorp.com/collections/terraform/aws-get-started
    * filmiki
* https://registry.terraform.io/providers/hashicorp/aws/latest/docs
    * spis do kopiowania
* order in terraform does not matter
* terraform files
    * `.terraform` - cache for plugins
    * `terraform.tfstate` - represents all of the state of terraform (simple json)
    * `terraform.tfstate.backup`
    * `anyName.tfvars`
* https://registry.terraform.io/namespaces/terraform-aws-modules
* creating IAM hack: create using visual editor AWS, and then copy output json file and paste to terraform
* dependencies = depends_on
* count = length(var.server_names)
  * Name = var.server_names[count.index]
  * value = [aws_instance.nameHere.*.private_ip]
* data sources - way terraform can query aws and return results (perform API request)
    * data "aws_instance" "dbsearch" {
      * filter {
        * name = "tag:Name"
        * values = ["DB Server"]
      * }
    * }
* make your infrastructure auditable
  * you can keep your infrastructure change history in git
* ainsible has a focus on automating the installation and configuration of software
* terraform automate provisioning of the infrastructure itself (ex. using AWS)
  * works well with automation software like ainsible to install software after the infrastructure is provisioned
* HCL - hashicorp configuration language
* terraform console
* terraform apply = terraform plan -out file ; terraform apply file ; rm file
* ${lookup(map, key, default)}
* 2 ways to provision software on your instances
  * build your own custom AMI and bundle your software with the image
    * Packer is great tool to do this
  * boot standarized AMIs and then install the software on it
    * using file uploads + remote exec
      * upload a script then execute it
    * using automation tools like ansible
      * you run terraform first, output the IP addresses, then run ansible-playbook
      * on those hosts
* when using s3 remote state it's best to configure the AWS credentials
  * backend need an access to s3 before it will do any other initialization
* data "terraform_remote_state" "aws-state" { backend = s3 }
  * useful to generate outputs
* datasources provide you with dynamic information
    * example: list of AMIs
* terraform templates
  * data "template_file" "template1" { }
  * resource "aws_instance" "web" { ... user_data = data.template_file.template1.rendered }
* terraform fmt - reformat code (used before commit)
* terraform taint - destroy and recreate the resource
* Provisioners are used to execute scripts on a local or remote machine as part of resource creation or destruction
  * provisioner "local-exec" {
    command = "echo ${aws_instance.testInstance.public_ip} >> public_ip.txt"
    }
* What happens when terraform.tfstate is removed?
  * terraform doesn't recreate the terraform tfstate file itself automatically.
  * You can use terraform import to manually recreate the terraform.tfstate.
* terraform + AWS
  * Amazon Virtual Private Cloud (VPC) is a service that lets you launch AWS resources in a logically isolated
  virtual network that you define.
  * VPC isolates instances on the network level
    * like own private network in the cloud
  * one VPC (per region) will be suitable (for smaller / medium startups)
  * an instance launched in one VPC cannot communicate with an instance in an other VPC using their private IP
    * they could communicate using public IP
    * you could also link 2 VPC (peering)
  * every availability zones has its own public and private subnet
  * all the public subnets are connected to an Internet Gateway
    * these instances will also have a public address, allowing them to be
    reachable from the internet
  * typically you use the public subnets for internet-facing services/apps
  * databases, caching services and backends all go into private subnets
  * a security group is just like a firewall
    * you specify ingress (incoming) and egress(outgoing) traffic rules
  * allows ingress: it's best practice to only allow your work/home/office IP
  * allow all outgoing traffic from the instance (all IPs)
    * no point in restricting
  * aws_instance has a field subnet_id which refers to the subnet of the VPC, which will be used to determine in
  what VPC the instance will launch
  * ingress {
      from_port = 22
      to_port = 22
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"] // all ip addresses
      }
  * For every subnet you can only define one availability zone.
    * One IP range (a subnet) can only be assigned to 1 availability zone
  * resource "aws_subnet" "subnet-1" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.203.0/24"
    map_public_ip_on_launch = "true" // map_public_ip_on_launch will give this subnet a public IP address, which means it'll be a public subnet
    availability_zone = "us-west-1a"
    }
  * a private subnet (a subnet without public IPs) will never be able to send traffic to the internet
    * FALSE - if you activate a NAT gateway and activate routes to route the traffic through the NAT gateway,
    instances will be able to send outgoing traffic over the NAT gateway.
    It's not possible to enable incoming traffic (e.g. webserver)
  * userdata - can be used to do any customization at launch
    * install extra software
    * prepare instances to join a cluster
      * ECS cluster
    * execute commands / scripts
    * is executed only at creation time not when instance reboots
  * private ip addresses will be auto-assigned to ec2 instances
  * every subnet within the vpc has its own range (10.0.1.0 - 10.0.1.255)
  * to use a public ip address, you can use EIP (elastic ip addresses)
    * public static IP address that you can attach to your instance
  * route53
    * typically you not use IP addresses but hostnames
    * you can host a domain name on AWS using route53
      * you first need to register a domain name using aws or any accredited registrar
      * you can then create a zone i route53 (eg example.com) and add DNS records (server1.example.com)
  * in AWS you can create
    * groups
    * users
    * roles
* interpolation ${}
* conditionals
* for / for each loop
  * for: for s in list : upper(s)
  * for each: for repeat nested block
    * dynamic "ingress" {
      * for_each = [22, 443]
      * content {
        * from_port
        * to_port
        * protocol
      * }
    * }
* project structure
  * you want to separate your development and production environments completely
  * for complete isolation, it's best to create multiple AWS accounts, and use one account
  for dev, another for prod, and a third one for billing


* you cannot use a function in default in variables, so you have to define local variable and use function there
* Other than the .terraform directory, what other file was created in the root of your directory when you initialized?
  * terraform.lock.hcl
* What is one item found within the .terraform directory?
  * cached provider plugins
* Open the image.tfplan file. Is the information contained within image.tfplan useful to humans?
  * No. The image.tfplan is only usable when deploying the infrastructure with Terraform and does not contain any human readable information.
* terraform apply -var-file=houston.tfvars
* cidrsubnet, random_shuffle, data aws_ami, aws_key_pair, templatefile, sensitive