# AWS ECS Service Connect vs ECS Service Discovery

AWS launched ECS service connect in 2022 re:Invent. ECS connect enables the ECS services to communicate with each other and it also enables external applications to communicate with ECS service. This feature is very similar to ECS service discovery except with service connect, we don't need to write any custom application code to collect traffic metrics any more. (Post a screenshot of the metrics dashboard)

## Main differences

- **Service URL construction**: when we are using service discovery, the service URL follows the format `<protocol>://<service_name>.<namespace>:<port>`. In service connect, the service URL follows the format `<protocol>://<service_name>:<port>`, because we have associated a default namespace with the ECS cluster (I think this format only applies if we are communicating with the service within the same cluster)

- **Traffic metrics collection**: as mentioned above, servive connect automatically collects the networking metrics and sends it to CloudWatch if we have enabled it. But we have to write custom code to collect those metrics when we are using service discovery.

- **Pricing**: ECS connect charges $0.01 per connection-hour and $0.01 per GB of data transferred and ECS service discovery charges $0.50 per million DNS queries and $0.01 per GB of data transferred. 

  For example, if two tasks within a service are connected to each other for a total of 24 hours in a month, the number of connection-hours would be 24, and the cost of ECS Service Connect for those tasks would be $0.24 (24 connection-hours x $0.01 per connection-hour).

Both services can be pretty cheap under the usual usage conditions.

- **Latency**: in service connect, services communicate with each other directly over pirvate network whereas in service discovery, services discover eacg other by registering the IP and the ports with a DNS server which introduces extra networking overhead, so using service connect should be slightly faster than service discovery.

- **Configuration**: ECS service connect is configured using HTTP namespace and service discovery is configured using private DNS namespace.

### Service discovery

<img width="1145" alt="image" src="https://user-images.githubusercontent.com/48658585/206368446-f6d7178b-e6e0-440e-9ad9-85c2e5b3c71d.png">

<img width="589" alt="image" src="https://user-images.githubusercontent.com/48658585/206357287-a2bfe4c1-434b-4cee-9805-3b417c54c37d.png">

<img width="420" alt="image" src="https://user-images.githubusercontent.com/48658585/206357187-af260e70-4b20-4f9f-86e0-512cf21da2bb.png">

### Service connect

<img width="1419" alt="image" src="https://user-images.githubusercontent.com/48658585/206368399-838f6094-6282-49e0-9af2-98def4d6d9a4.png">

<img width="585" alt="image" src="https://user-images.githubusercontent.com/48658585/206357337-07348d15-2132-4e89-ad01-c5c131c5dbcb.png">

<img width="389" alt="image" src="https://user-images.githubusercontent.com/48658585/206357208-e42077ce-9b63-4699-b850-487a468927e5.png">

### Service connect incoming traffic metrics

<img width="1409" alt="image" src="https://user-images.githubusercontent.com/48658585/206364262-6407b1aa-6955-47ba-b536-484d800f4310.png">

### Service connect outgoing traffic metrics

<img width="1409" alt="image" src="https://user-images.githubusercontent.com/48658585/206364375-02ce9d9a-26aa-4458-a2b6-5f5858ef2ffe.png">

# Reference

- [AWS's official announcement of ECS Connect](https://aws.amazon.com/blogs/aws/new-amazon-ecs-service-connect-enabling-easy-communication-between-microservices/)
- [Creating Service Connect from CLI](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-service-connect.html)

# Note

- service-discovery is deployed to us-west-2 and the service-connect example is deployed to us-east-1 but currently it's not functional (ECS tasks have been failing to start).
