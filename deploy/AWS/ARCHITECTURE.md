## Technologies

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
