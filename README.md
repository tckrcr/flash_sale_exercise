This repo builds the infrastructure that supports a hypothetical e-commerce platform. The goal is to build a platform for scalable Web APIs, microservices, and streaming architectures. 

The repo is broken into 3 main components - the terraform code (using terragrunt), the kubernetes manifests, and the application code that provides a basic flask api for testing

To Run: 

    Clone this repo using "git clone"

    Prerequistes: 
        Terraform: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
        Terragrunt: https://terragrunt.gruntwork.io/docs/getting-started/install/
        AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
        kubectl: https://kubernetes.io/docs/tasks/tools/
    
    Pre-steps
        1) Login to the AWS Console: https://us-east-1.console.aws.amazon.com/
        2) Navigate to the top right of the window and click your user name
        3) Click "Security Credentials"
        4) Click "Create Access Key"
        5) For Create access key Step 1, choose Command Line Interface (CLI).
        6) For Create access key Step 2, enter an optional tag and select Next.
        7) Record the values you get from the next step
        8) Open terminal or cmd and type "aws configure"
        9) You'll be prompted for those values you got above
        10) For default region enter "us-east-1" or your specific environment

    Steps: 
        A) Building the ECR Repo
            1) Navigate to "/flash_sale_exercise/terraform_ecr/"
            2) Edit the name of the ecr_repo if desired
            3) Run terraform init, terraform plan, and then terraform apply

            This will create the ecr repo we'll use to push and pull our application code 

        B) Build the application
            1) Run "aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com"

            ARM64 Steps
                1) Navigate to "/flash_sale_exercise/application"
                2) Run: docker buildx build --platform linux/amd64 -t <your-image-name>:latest .
                3) Run: docker tag <your-image-name>:latest <aws_account_id>.dkr.ecr.<region>.amazonaws.com/<your-ecr-name>:latest
                4) Run: docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/<your-ecr-name>:latest
            x86
                1) Navigate to "/flash_sale_exercise/application"
                2) Replace line 2; "FROM python:3.8-slim-buster"
                3) Run: docker build -t <your-image-name> .
                4) Run: docker tag <your image tag> <aws_account_id>.dkr.ecr.<region>.amazonaws.com/<your-ecr-name>:<your image tag>
                5) Run: docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/<your-ecr-name>:<your image tag>

        C) Build the infrastructure
            1) Navigate to "/flash_sale_exercise/terraform/environments/prod"
            2) Review all terraform files, make changes based on your aws account, region, and any configs you'd like to change
            3) Run: terragrunt init
                3a) Terragrunt will ask you if you'd like to create the backend state file, type y, then enter to confirm
                3b) If the s3 bucket is created you can update lines 3-6 of "flash_sale_exercise/terraform/environments/prod/terragrunt.hcl"
            4) Run: terraform run-all plan
            5) Review the output, if this is your first time running only the vpc module will create as its required for other resources
            6) Run: terraform run-all apply
            7) Terragrunt/Terraform will create the infrastructure. NOTE: This may take up to 60 minutes for the entire run

        D) Configure the cluster
            1) Run: aws eks update-kubeconfig --region us-east-1 --name <your new cluster name>
                1a) This command will configure kubectl to work
            2) Run: aws ecr get-login-password --region us-east-1 | kubectl create secret docker-registry ecr-credentials --docker-server=354918396817.dkr.ecr.us-east-1.amazonaws.com --docker-username=AWS --docker-password-stdin
                2a) This command will add a secret so kubernetes can pull the docker images from ECR
            3) Navigate to "flash_sale_exercise/kubernetes"
            4) Run: kubectl apply -f .

        This will apply the configurations to the cluster, including the deployments and starting the app. 

Notes:
    - MSK will take a long time to complete the build
    - This does not deal with application code, the provided python script is just used to test basic functionality
    - I wasn't able to use a domain name to setup products like Route53
    - Services like API Gateway and CloudFront should be used but unable to setup in this config
    - If using this in production; follow best security practices -> especially related to rds 