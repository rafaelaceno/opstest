
# Cloud Security

### Description

Script Terraform that when executed will go
- Create a Lauch Configuration
- link the Lanch Configuration to an Auto Scalling Group
- Placing Scalling with instances in Multi-AZ
- Creates an ELB by listening on port 80
- Link Auto Scalling Group to Load Balancer
- Create a policy for: 

    **Scalle UP**
Whenever the average processing time of our Auto Scaling Group gets above 60% during 2 cheks with interval of 2 minutes between them, we will upload a new instance.

   **Scalle Down**
Whenever the average processing time of our Auto Scaling Group falls below 10% during 2 checks with intervals of 2 minutes between them, we will kill one instance.



### Requirements
- [Terraform](https://www.terraform.io/downloads.html)
- [AWS Account](https://aws.amazon.com/)
- [SSH Key](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)

### Architecture
![Architecture](https://user-images.githubusercontent.com/32931856/51339968-ead70780-1a74-11e9-9a31-fe0892b65e59.png)
- Elastic Load Balancer (ELB)
- Auto Scaling Group with Launch Configuration
- Instances Multi-AZ
- Policies for Scale Up and Scale Down

### Running the project

- Clone the repository

```
git clone https://github.com/rafaelaceno/opstest

```
- Post the project springbot.zip in a s3 bucket with visualisation permission to the user account
- Edit the `variables.tf` file with the SSH public key location 
- Edit the `variables.tf `file with the name of the VPC that will be used for this infrastructure
- Edit the `variables.tf` file with the name of bucket s3 that is located the project spring_bot.zip

- Execute terraform

```
terraform init
terraform plan
terraform apply

```
