## Decisions

### Deployment CI/CD

**Choice:** Make
**Alternatives:** Shell Scripts

For a reliable, idempotent deployment and teardown workflow I've decided go with Make. For one is Make an old and battle-tested technology that, in my experience, runs really stable, it is also installed on most Linux distributions by default. It is not generally intended for applications that do not manipulate files and while this project does not really change files, there are ways to get around this (e.g. PHONY targets) so that I can profit from what Make does good - for example its usage simplicity and versatility for recipe definition with a myriad of other features.

Shell scripts are an alternative but for a local deployment CI/CD I would essentially re-implement Make.

### Private Egress

**Choice:** Public NAT Gateways
**Alternatives:** Single AZ NAT Gateway, PrivateLink endpoints

A single AZ NAT gateway does not provide fault tolerance, i.e. it fails to meet the HA goal. PrivateLink endpoints would be a considerably more private solution but comes in at a cost of `0.012$/hour` for every endpoint provisioned in an AZ, whereas a NAT gateway incurs `0.052$/hour` in every AZ. The PrivateLink solution is more expensive after 4 endpoints and with 3 endpoints from ECS (`ecs`, `ecs-agent` and `ecs-telemetry`), 2 endpoints from ECR (`ecr.api`, `ecr.dkr`), 1 endpoint for SecretsManager and 1 endpoint for CloudWatch Logs, this is easily met.

The cost per GB processed is negligible in this scenario.


### IaC

**Choice:** CloudFormation

**Alternatives:** Terraform

### Image Registry

**Choice:** ECR

**Alternatives:** Docker Registry, On-Premise Registry

The image registry should make and keep the image readily available, keep cost at a minimum and not require a lot of work. Data sovereignity and security are not a considerable worry. 
All three options provide the image readily and have a low cost point with negligible differences. An on-premise registry produces a lot of work though and the Docker Registry integrates worse with AWS than ECR, so for ease of use ECR is the tool of choice.

### Container Runtime

**Choice:** ECS + EC2

**Alternatives:** EKS, Kubernetes + EC2, Docker Swarm + EC2

The existing skillset is insufficient for Kubernetes and running Docker Swarm on EC2 does not provide any benefits for ease of usage or availability compared to ECS.

### Secrets

**Choice:** AWS Secrets Manager

**Alternatives:** Encrypted File on Container Instance + KMS

On AWS there is no real alternative that enables easy retrieval and integrates as well with other services as their Secrets Manager service. Other solutions require additional tools or introduce unnecessary complexity.

### Image Signing

**Choice:** cosign

**Alternatives:** ECR Managed Signing

While ECR provides a built-in solution to sign images, domain knowledge on cosign already exists and provides signing at no additional cost (compared to `0.02$/signature` with ECR).

### Key Management

**Choice:** KMS

**Alternatives:** Smartcard, Local file-based, CloudHSM

Key management is required for signing images, which is a local process. In that case a smartcard or file-based solution would provide a solution at zero OpEX but does not scale at all - any team of size 2+ requires a solution share/provide keys securely, even if it needs to be shared only once. A file based solution additionally runs a certain risk as Smartcard or HSM solutions offer considerably increased protection at rest.

CloudHSM is a strong contender but requires a complex architectural integration into the workflow. For KMS the KMS Sign API can be used in a similar fashion without any large architectural considerations.

### Load Balancing

**Choice:** ELB

**Alternatives:** Route53

Route53 requires a domain for load balancing, which is out of scope for this project. ELB is a well integrated load balancing solution in the AWS ecosystem. External alternatives introduce unnecessary complexity.

### Scaling & Fault Tolerance

**Choice:** ECS / EC2 Auto Scaling

**Alternatives:** Manual Scaling

The container runtime of choice "ECS + EC2" provides a built-in solution to enable fault tolerance and automated scaling; EC2 Auto Scaling. As its integrated with ECS it can be configured directly with it.

### Database Layer

**Choice:** RDS

**Alternatives:** -

A task requires an optional database layer. The application provides no requirement or restrictions, neither explicitly or implicitly, so the choice of the datbase is inconsequential. RDS provides in this context somehwat of a learning opportunity and is choosen solely for this purpose.

## Compartmentalization

AWS offers tags, and of course names, to define and group resources. Thus:

**Naming** - Every resource name is prefixed with `pha-`, short for "podtato-head-app".
**Tags** - Every resource is tagged with `Project: practice-pha`.

## AWS Well-Architected Framework

### Operational Excellence

Operational Excellence mentions the ability to run workloads effectively, gain insights into their operations and to continuously improve processes and procedures. All three are given through the use of auto-scaling, automatically adjusting the compute environment to keep the app running effectively. Through the use of CloudWatch alerts, a CloudWatch Dashboard and container, as well as VPC flow logs, sufficient insights into the operational quality of the app's infrastructure is gained, which supports the continuous improvement of the supporting processes and procedures.

This can be improved further by using EventBridge to further monitor specific deployment events and add automatic remediation of errors.

### Security

The Security pillar desribes taking advantage of cloud technologies to protect data, systems and assets. Through the use of KMS based encryption keys, image signing supported and displayed within ECR, and storage of app secrets within Secrets Manager, well integrated cloud technologies are sufficiently used for security purposes.

This can be improved further by:
- Using KMS keys for logs, secrets or SNS
- Using PrivateLink to keep communication to regional/global AWS services out of the Internet
- Using ECR's built-in image signing instead of cosign to leverage better integration (not necessarily better security)

### Reliability

The Reliability pillar describes the ability of a workload to perform its intended function correctly and consistently when it's expected to, including operation and testing through its lifecycle. This is sufficiently provided through the use of a Load Balancer in combination with auto-scaling with an EC2 Auto Scaling Group and ECS, the app can support workloads through the loss of hosts, instances and a whole Availability Zone. Testing is provided through the local Makefiles, covering a wide surface area.

This can be further improved by deploying the application to multiple regions and leveraging Global Accelerator, as well as Aurora Global for an eventual Relational Database layer, adding regional resilience and failover.
Testing can be further improved by establishing a cloud/server layer CI/CD pipeline for an automated testing workflow and increasing the surface area that tests cover, e.g. by forcing the application to return HTTP 5XX codes to test reactivity to 5XX errors, filling the filesystem with large dummy files to test reactivity to filesystem overfilling or tearing down EC2 hosts in addition to container instances to test recovery in both cases.

### Performance Efficiency

The Performance Efficiency pillar describes the usage of computing resources to meet system requirements and to maintain that efficiency as demand changes. Due to the use of automatic scaling and serverless resources like Secrets Manager, KMS or ECS (control plane), computing resources are already partly used as efficiently as possible. EC2 hosts use the smallest host size possible and the image is developed to have a small footprint. 

Nonetheless both the compute host and container instance can be improved for efficiency, especially since both rely on manual adjustment for horizontal demand changes. The compute host layer specifically can be improved by leveraging Fargate instead of self-managed EC2 hosts. This additionally improves Reliability and Operational Excellence since it offloads the management and auto-scaling of the host layer to AWS.

### Cost Optimization

The Cost Optimization pillar describes delivering business value at the lowest price point. This is provided through the ability to easily deploy and teardown the whole stack with a single Make command. 

This can be improved by leveraging on-demand services like Fargate or by deploying a NAT gateway in only 1 Availability Zone, since it is the most costly resource. This would come at the cost of Reliability though.

### Sustainability

The Sustainability pillar describes essentially the same qualities as the Performance Efficiency pillar and thus I refer to it.

## Learnings

### CloudFormation JSON vs. YAML

Next time I use CloudFormation, I will use JSON instead of YAML as writing JSON by hand is awful DX.

### CloudFormation vs. Terraform

I can't really make a technical relevant statement for comparison since I lack experience with Terraform. But for the next AWS/Cloud project I will use Terraform, yet alone to learn a new technology.

### Nested Makefiles

This approach allows me to keep the infrastructure domain exchangeable which is, while being out of scope for now, allows me to return to this project and experiment with new infrastructure stacks.

Unfortunately there is no easy way to enforce the structure of the deployment commands with Make and since I defined a few key variables (like the project name) in the root Makefile and pass it along, I have to route and deployment method through the root Makefile, making experimentation and running specific infrastructure methods ad-hoc more difficult. Next time I either drop the nesting, define key variables somewhere else and them in per Makefile or try another deployment IaC approach that supports modularity more readily.

## Other Notes

- Tags are added as a command parameter to the CLI invocation instead of adding the project tag to every CloudFormation resource manually.
