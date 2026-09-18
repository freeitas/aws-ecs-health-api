# aws-ecs-health-api

Microservices lab for the Health API on ECS, built on top of the ECS service module.

## Architecture decisions

### Why only the edge service gets blue/green

`health-api.tf` is the one module carrying `deployment_controller = "CODE_DEPLOY"`. The other seven pass `use_lb = false`, so they own no target group, and ECS blue/green needs a listener with two of them. Putting the whole fleet on CodeDeploy would have meant bolting a load balancer and a second target group onto every gRPC backend that needs neither, just to bake a deploy. I pay that tax only where a bad rollout is user-visible. I also left `codedeploy_strategy` commented instead of pinning `ECSLinear10PercentEvery1Minutes`: with `service_task_count = 1`, there is nothing to shift ten percent of.

### Why Service Connect east-west and the ALB only north-south

The seven backends set `use_service_connect = true` with `use_lb = false`; `health-api` alone sets it `false` and consumes `listener_internal` / `alb_internal`. The same split shows in the endpoints: `recommendations`, inside the mesh, calls `*.aws-ecs-cluster.local`, while `health-api`, with Service Connect off, calls `*.aws-ecs-cluster.discovery.com` and leans on `service_discovery_namespace`.

The alternative survives on the `routing` branch, where all eight modules take `service_listener`/`alb_arn` — seven on the internal ALB, `health-api` on the external one under `health.demo`. That is eight target groups and host rules to keep, and they are not even on the east-west path: `recommendations` there still resolves `*.discovery.com` over DNS, so a dead task stays pinned inside a long-lived gRPC connection until the record expires.

### Why the topology is a branch, not a variable

`main`, `routing`, `service-connect` and `codedeploy` share no history — `git merge-base` between any two returns nothing (`codedeploy` is currently identical to `main`, so the live split is three topologies). `routing` drops both service-connect SSM lookups and their variables; `data.tf` goes from 11 lookups to 9. A single root with `var.communication_mode` could gate those with `count`, but every module input turns conditional with them, and what I want to read per topology is the whole file, not a ternary. The price is bumping the module pin on four branches.

### Why FARGATE_SPOT at weight 100, including the trace collector

All eight `service_launch_type` blocks are Spot at weight 100, no on-demand base. It bites hardest on `jaeger`: `task_maximum = 1`, so a reclaim is a gap with no replica and the in-flight spans go with it. This is a lab — I would rather lose traces than keep a 512/1024 collector on on-demand around the clock.

### Why one role for all eight services

`iam.tf` defines a single `nutrition-role`, passed as `service_task_execution_role` by all eight modules, including `jaegertracing/all-in-one:1.57`. Its policy carries `s3:GetObject` and `sqs:*` on `Resource = "*"` beside the logs and ECR actions it actually needs. A role per service is the correct answer; the trade here is one role instead of eight in a single-tenant account, and the trigger to split it is explicit: the day this stack shares an account with anything I care about.

## [v1] - Internal and external routing

The goal is to stand up an environment with distributed communication between several internal and external microservices inside AWS.

![v1](.github/assets/health-api.png)

```bash
curl --location --request POST 'http://health.demo/calculator' \
--header 'Content-Type: application/json' \
--data-raw '{ 
   "age": 26,
   "weight": 90.0,
   "height": 1.77,
   "gender": "M", 
   "activity_intensity": "very_active"
} ' --silent | jq .
```

## [v2] - API Gateway and VPC Link for external exposure

![v2](.github/assets/health-api-gateway.png)