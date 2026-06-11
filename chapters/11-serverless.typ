#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= SERVERLESS COMPUTING
#extra[
  Package: Serverless Computing — `ICCBD Serverless.pdf`
]

Serverless computing represents the next step in the abstraction ladder of cloud delivery
models. Rather than managing servers, runtimes, or even containers, the developer
delivers only *business logic* — functions — and the platform handles everything else:
scheduling, scaling, isolation, and billing.

== Cloud Computing Service Models

=== The Service-Model Spectrum

The cloud-computing stack can be described along a single axis: how much is *managed by
the provider* versus *managed by the customer*.

- *On-premises*: customer owns and manages everything — hardware, virtualization, runtime, application.
- *MaaS (Metal as a Service)*: provider manages hardware; customer handles everything above.
- *IaaS*: provider manages hardware and virtualization; customer handles runtime and application.
- *PaaS*: provider manages up through the runtime; customer handles the application.
- *FaaS*: provider manages up through the runtime; customer manages only the application *logic and interconnection lifecycle*.
- *SaaS*: provider manages everything; customer only uses the application.

#note[
  The #kw[XaaS] ("Anything as a Service") umbrella is large: MaaS, IaaS, PaaS, SaaS,
  DBaaS, NaaS, CaaS, StaaS, BaaS, IAaaS, ObjaaS, SecaaS… The trend is clear:
  every infrastructure concern is becoming an outsourced service.
]

#analogy("Pizza as a Service 2.0")[
  On-premises is making pizza at home. MaaS is a commercial kitchen.
  IaaS is takeaway — the kitchen and oven are provided. PaaS is a restaurant where
  you choose from the menu. FaaS is food delivery: you specify the recipe (function),
  the platform prepares and delivers it, and you pay per meal.
  SaaS is eating at a buffet — you just consume.
]

=== Serverless: Definitions

#def("Serverless Computing")[
  «Serverless computing is a method of providing backend services on an as-used basis.
  A company that gets backend services from a serverless vendor is charged based on
  usage, not a fixed amount of bandwidth or number of servers.»
  --- Cloudflare

  «A serverless architecture is a way to build and run applications and services without
  having to manage infrastructure. Your application still runs on servers, but all the
  server management is done by AWS. You no longer have to provision, scale, and maintain
  servers to run your applications, databases, and storage systems.»
  --- Amazon AWS team

  «A Serverless solution is one that costs you nothing to run if nobody is using it.»
  --- Paul Johnston, AWS
]

#prop("Serverless Key Concepts")[
  - *Absence of control* on scheduling and scaling logic — the platform decides.
  - *No control on resource deployments* — provisioning is invisible to the developer.
  - *Zero-scaling*: cost is based on number of activations; idle functions cost nothing.
  - *Developer focuses only on business logic* — infrastructure is fully abstracted away.
]

=== Serverless as BaaS + FaaS

In the serverless model (sometimes called *BaaS+FaaS*), everything below the application
layer is managed by the provider:

- In *IaaS*, the customer manages Application, Data, Runtime, Middleware, OS; the provider handles Virtualization, Servers, Storage, Networking.
- In *PaaS*, the customer manages Application and Data; the provider manages the rest.
- In *BaaS+FaaS*, only the *Application logic* (the function code) is customer-managed; the entire stack beneath — Data, Runtime, Middleware, OS, Virtualization, Servers, Storage, Networking — is provider-managed.

== Backend as a Service (BaaS)

#def("BaaS — Backend as a Service")[
  #kw[BaaS] is the outsourcing of backend infrastructure to the cloud provider through
  *plug-and-play APIs*. Developers consume ready-to-use services rather than building
  and operating them.
]

To support the development of FaaS (and also PaaS/IaaS), cloud providers offer ready-to-use
BaaS components:

- *Database as a Service* (DBaaS)
- *Storage as a Service*
- *CDN as a Service*
- *Cognitive as a Service* (AI/ML APIs)
- Authentication, Alerting, Push Notifications, …

#why("Why BaaS matters for serverless")[
  Functions are stateless and ephemeral — they cannot hold long-lived connections or
  manage persistent state. BaaS services (managed databases, object storage, queues)
  fill this gap, giving functions a reliable backend without forcing the developer to
  manage servers.
]

== Function as a Service (FaaS)

=== Definition and Properties

#def("FaaS — Function as a Service")[
  #kw[FaaS] is an *event-centric* computing model where user-defined business logic
  (functions) is triggered and dynamically instantiated by incoming events.
  Each function is a small, stateless, independently deployable unit of logic.
]

#prop("FaaS Core Properties")[
  - *Stateless*: functions carry no state between invocations; all persistent state lives in external BaaS services.
  - *Event-driven*: execution is always triggered by an event (HTTP request, queue message, timer, file upload, …).
  - *Ephemeral execution environments*: the execution container is created on demand and destroyed after the invocation.
  - *Fine-grained autoscaling with zero-scaling*: the platform scales from zero to thousands of concurrent instances automatically, and scales back to zero when idle.
]

#note[
  Functions can be composed into *pipelines* and *workflows*. Reducing the scope of
  each function enables easy parallelism and higher throughput. A pipeline of functions
  is also called a *workflow*.
]

=== FaaS as Finer Decomposition

FaaS pushes decomposition one level beyond microservices:

- A *monolith* is decomposed into *microservices*.
- Each *microservice* is itself a composition of *functions*.

#so a microservice in FaaS is just a group of cooperating functions sharing a trigger
and a lifecycle.

=== FaaS Advantages

#prop("FaaS Benefits")[
  - *Ease of development process*: write only the business logic.
  - *Ready-to-use services*: connect to BaaS for storage, auth, messaging.
  - *Reduced management costs*: no servers to patch, monitor, or scale.
  - *Fine-grained autoscaling* #arrow *pay only for what you use*.
  - *Many provider-side optimization possibilities*: the provider can bin-pack, pre-warm, and cache containers transparently.
]

#note[
  The slides mention *event sourcing* and a *state manager* as advanced patterns:
  an event is treated as a state (more complex coordination), while an *orchestrator*
  executes programs. FaaS fits naturally into event-sourcing architectures.
]

=== Positioning FaaS in the Cloud Stack

In FaaS the customer manages:
- *Application layer only*: the logic, the interconnection pattern, and the lifecycle configuration.

Two coordination capabilities exist in functional services:
- *Orchestration*: a central entity manages all function executions (e.g., AWS Step Functions).
- *Choreography*: a function triggers a sequence of events, with no central manager.

== FaaS Architecture

=== FaaS Workflow

#def("FaaS Workflow")[
  The association between a specific event and the execution of one (or more) specific
  functions is called a #kw[FaaS Workflow].
]

A typical workflow: `HTTP request` #arrow `FaaS platform` #arrow `function executes` #arrow returns JSON response.

=== Essential Components of a FaaS Platform

Every FaaS platform must include at least three components:

#prop("FaaS Essential Components")[
  - *Trigger*: bridges external events with ones manageable by the FaaS infrastructure.
  - *Controller*: orchestrates event delivery and function lifecycle.
  - *Function Executor*: runs the function code in an isolated environment.
]

=== The Trigger

#prop("Trigger Responsibilities")[
  - Bridges external events with ones manageable by the FaaS infrastructure.
  - Can convert non-event-based information into events (e.g., polling a database).
  - Lifecycle and scaling managed by the infrastructure.
  - Handles different protocols and formats: HTTP, TCP, RabbitMQ, Kafka, …
]

=== The Controller

#prop("Controller Responsibilities")[
  - Interacts with external controllers to provision resources.
  - Handles the delivery of events from trigger to functions.
  - Manages lifecycle of functions and other FaaS infrastructural components.
  - Receives configurations from customers and activates workflows.
]

#prop("Controller Advanced Features")[
  - *Scalability* of components.
  - *Location transparency*: clients need not know where a function runs.
  - Delivery of events with different *QoS* levels.
  - *Load balancing* across function instances.
  - *Asynchronous delivery* via a Message-Oriented Middleware (MOM).
]

=== The Function Executor

#prop("Function Executor Structure")[
  The Function Executor contains:
  - *Invoker* (or watchdog): receives events from the controller, runs the designated function by passing the event, and manages the result.
  - *Execution environment*: provides isolation (Container, VM, or WASM), dependency management (OS libs), and reproducibility.
  - *Logic*: the function code itself.
]

#important("Execution Environment Isolation")[
  The execution environment must guarantee:
  - *Isolation*: one function cannot interfere with another.
  - *Dependencies*: the correct OS, libraries, and runtime are bundled.
  - *Reproducibility*: the same image runs identically on every invocation.
]

=== Platform Architecture (detailed)

A more complete FaaS platform view adds an *API Gateway* and an *Event Queue* in front
of a *Dispatcher*:

- *API Gateway*: accepts HTTP requests from clients.
- *Event sources* (object storage, messaging, mail, cloud services): emit events directly.
- *Event Queue*: buffers incoming events.
- *Dispatcher*: routes events to the appropriate *Worker*.
- *Workers*: hold the function code and execute it in isolated slots.

== FaaS Workflows and Function Composition

=== Workflows of Functions

#def("FaaS Workflow (extended)")[
  A #kw[FaaS workflow] is a series of FaaS functions orchestrated to complete a complex task.
]

Common use cases:
- Data pipelines.
- API processing.
- Event stream handling.

#prop("Benefits of FaaS Workflows")[
  - *Scalability*: automatically scales with workload.
  - *Cost-efficiency*: pay-per-use model reduces expenses.
  - *Modularity*: functions can be developed, deployed, and updated independently.
]

=== Core Workflow Components

#prop("Orchestration vs. Choreography")[
  - *Orchestration*: a central entity (e.g., AWS Step Functions, Azure Durable Functions) manages all function executions.
  - *Choreography*: functions trigger each other using events without a central manager.
]

*Workflow building blocks*:
- *Event Sources*: events that trigger workflows (APIs, IoT events, file uploads).
- *Functions*: individual, stateless units of logic.
- *State Management*: handled externally through services like DynamoDB or Redis.
- *Orchestrators*: tools like AWS Step Functions, Apache Airflow, or Tekton.

=== Composition Patterns

Functions can be composed in three main patterns:

#prop("Function Merging Pattern")[
  Two or more functions are *merged* into one, which also defines the composition logic.
  Execution is very efficient because everything runs locally in a single container.
  The merged function acts as a monolithic coordinator.
]

#prop("Reflective Invocation Pattern")[
  Two or more functions are invoked by an additional *coordinating function* provided
  by the customer. The coordinating function can hold state. Coordinated functions are
  independent and run in separate workflows (Workflow A, Workflow B), each with their
  own trigger. This is more expensive in resources because every trigger must pass
  through all network nodes.
]

#prop("Continuous Passing Pattern (Function Chaining)")[
  The result of the execution of Function A is passed directly to Function B as its
  trigger (instead of returning to the caller). The next function is hard-coded, making
  the chain static — changing the successor requires a new function definition.
]

Other composition examples:
- *Facade pattern*: a single function aggregates multiple downstream APIs.
- *Conditional chaining*: branches based on function output.
- *Map-reduce*: parallel map functions feed a reduce stage.

=== Example: E-Commerce Order Workflow

#example("E-Commerce Order Processing")[
  + *Trigger*: customer places an order.
  + *Function A*: validate payment.
  + *Function B*: check inventory.
  + *Function C*: process shipment.
  + *Function D*: send order confirmation.

  Key benefits: flexibility (replace individual steps), high availability (built-in
  fault tolerance), no servers to manage.
]

== FaaS Platforms

=== Hosted vs. Installable Platforms

FaaS platforms fall into two categories:

- *Hosted platforms*: AWS Lambda, Azure Functions, Google Cloud Functions, Cloudflare Workers, Vercel, Netlify Functions, IBM Cloud Functions, Twilio Functions, Koyeb, …
- *Installable/open-source platforms*: Knative (CNCF Incubating), KEDA (CNCF Incubating), Apache OpenWhisk, OpenFaaS, Fission, Kubeless, Kyma, Nuclio, OpenFAAS, PipelineAI, Virtual Kubelet, riff, …

#why("Why Open Source FaaS?")[
  - Serverless advantages available on *on-premises* nodes, not just public clouds.
  - *Total control* over components.
  - *Transparency* of the architecture — no vendor black-box.
  Open-source platforms (Fission, OpenFaaS, Apache OpenWhisk, Knative) bring
  FaaS benefits to private and hybrid clouds.
]

== OpenFaaS

=== Architecture Overview

#def("OpenFaaS")[
  #kw[OpenFaaS] is an open-source FaaS platform built on top of Kubernetes and Docker.
  It provides a gateway, auto-scaling, a monitoring stack, and a messaging layer.
]

OpenFaaS is organized in three layers:
- *GitOps/IaaC Layer*: OpenFaaS Cloud, GitHub.com, GitLab Self-hosted.
- *Application Layer*: OpenFaaS Gateway, Prometheus (monitoring), NATS Streaming (messaging).
- *Infrastructure Layer*: Kubernetes or Docker, Container Registry.

=== OpenFaaS Internal Flow

The flow of an invocation:

+ Client (UI/CLI/REST) sends a request to the *OpenFaaS Gateway*.
+ Gateway performs CRUD or Invoke via the *faas-provider* (abstraction over Kubernetes/Docker/containerd/AWS).
+ Provider routes to the appropriate *function container* (`fn`), identified by name and image.
+ Functions are stored in a *Registry*.

=== OpenFaaS: Gateway

The *OpenFaaS Gateway* is simultaneously the trigger and controller:

#prop("Gateway Capabilities")[
  - *HTTP Trigger*: accepts incoming HTTP requests.
  - *Controller*: distributes invocations over available functions; manages resources through Providers.
  - *Built-in UI Portal*.
  - *Function management API*.
  - *Monitoring, Tracing, Logging* exposure.
  - *Auto-scaling* based on Prometheus metrics.
  - *Self-documented REST API* (Swagger).
]

=== OpenFaaS: Prometheus (Monitoring)

*Prometheus* is the monitoring backbone of OpenFaaS:

- Widely-spread cloud-oriented monitoring service.
- Embeds a multi-dimensional data model with time-series.
- Uses *PromQL* for querying.
- Each server has its own storage #arrow single server nodes are autonomous.
- Pull-model over HTTP: metrics are collected by Prometheus from targets.
- Targets discovered via service discovery or static configuration.
- Multiple graphing and dashboarding modes.

=== OpenFaaS: NATS (Messaging)

*NATS* is the message-oriented middleware used by OpenFaaS for asynchronous delivery:

#prop("NATS Properties")[
  - Native Pub/Sub and Request/Reply support.
  - Open source, lightweight, high-performance.
  - Cloud-native infrastructure.
  - Hybrid deployment support.
  - Delivery guarantees: *at-least-once*, *at-most-once*, *exactly-once*.
]

#example("OpenFaaS Asynchronous Invocation")[
  A "Request Statement" event triggers the Gateway. The Gateway enqueues via NATS
  Streaming. A `queue-worker` function dequeues, calls a `Generate Statement` function
  that queries Postgres and uploads a PDF to S3. Finally a callback invokes
  `Email Customer` with the result.
]

=== OpenFaaS: Providers

*Providers* are an abstraction layer for provisioning Function Executors in different
environments (Kubernetes, containerd, AWS, …). They provide:

- CRUD for functions (or microservices).
- Invocation of functions via a proxy.
- Scaling of functions.
- CRUD for Secrets (optional).
- Log streaming (optional).

#note[
  Using containers (Kubernetes pods) for functions is *expensive* in terms of overhead.
  Fine-grained scalability is *sacrificed* in order to gain stronger isolation and
  compatibility with the Kubernetes ecosystem.
]

=== OpenFaaS: Watchdog (Invoker)

Every function executes inside a container that exposes a proxy — the *Watchdog* — used
to pass the function code to the forked process.

#prop("Watchdog Execution Steps")[
  + Receive an event from the controller.
  + Create a *child process* to execute the function code.
  + Run the function code in the child.
  + Pass the event as argument to the function.
  + Wait for the end of execution.
  + *Terminate the child*.
]

Two watchdog modes exist:

- *Forking mode*: for each request, a new Linux process (heavy) is forked. The function is executed on a dedicated process, and once it finishes it is destroyed. A child process is created to accomplish the function.
- *HTTP mode*: a persistent child process exposes an HTTP server at `localhost:3000`; the parent watchdog proxies requests to it.

#prop("Keeping the Child Alive (HTTP Mode Trade-offs")[
  Keeping the child process alive breaks the strict FaaS definition but offers:
  - *No-zero scaling* (the container is warm).
  - *Thread concurrency* in the child.
  - *State* can be maintained in the child.
  - *Reduced response latency*.
]

=== OpenFaaS: faasd

*faasd* is a lightweight alternative to the full Kubernetes-based OpenFaaS. It runs
OpenFaaS on *containerd* directly, controlled by *systemd*, without Kubernetes overhead.
Suitable for edge, IoT, and single-node deployments.

== Apache OpenWhisk

#def("Apache OpenWhisk")[
  #kw[Apache OpenWhisk] is an open-source, distributed FaaS platform with an
  action-oriented model. It uses an event-driven architecture built on Kafka and
  CouchDB.
]

#prop("OpenWhisk Architecture")[
  - *NGINX*: single point of access — API Gateway.
  - *Controller*: manages every function call, load balances across nodes, and serves as the authentication server. Can become a bottleneck (not replicated like ETCD).
  - *Apache Kafka*: enables event-based and asynchronous communications.
  - *Invoker*: executes functions (actions) in Docker containers.
  - *Apache CouchDB*: stores functions, parameters, configurations, and results.
]

== Knative

=== Overview

#def("Knative")[
  #kw[Knative] is a *platform-agnostic* solution for running serverless applications
  on Kubernetes. It simplifies deployment, scaling, and event-driven architectures.
  *Knative is not a FaaS* — it abstracts Kubernetes resources, exposing them as
  serverless workloads (microservices, not functions).
]

Roles in the Knative ecosystem:
- *Developers*: build and deploy apps via Knative API.
- *Operators*: deploy and manage Knative instances using Kubernetes API.
- *Users/IoT systems*: consume applications deployed by developers.
- *Contributors*: develop and contribute to the OSS project via GitHub.

#prop("Knative Benefits")[
  - *Scalability*: automatically scales from zero to millions of requests.
  - *Flexibility*: supports any runtime that runs on Kubernetes (Go, Node.js, Python, …).
  - *Cost efficiency*: pay for resources only when the service is running.
  - *Integration*: seamlessly integrates with existing Kubernetes tools.
]

=== Knative Serving Architecture

Knative has two main subsystems: *Serving* and *Eventing*.

#prop("Knative Serving — Key Components")[
  - *Ingress Gateway*: entry point for all external traffic.
  - *Activator*: queues incoming requests when a service is scaled-to-zero; communicates with the Autoscaler to bring the service back up; can act as a request buffer for traffic bursts.
  - *Autoscaler*: scales Knative Services based on configurations, metrics, and incoming requests.
  - *Queue-Proxy*: a sidecar container in the Knative Service Pod; collects metrics (useful for batching multiple events together), enforces the desired concurrency, and can act as a queue/buffer.
  - *Controller*: manages the state of Knative resources within the cluster; implements the Operator Pattern (Observed State #arrow Desired State); can become a bottleneck. Watches several objects, manages lifecycle of dependent resources.
  - *Webhooks*: validate and mutate Knative resources.
  - *DomainMapping*: maps custom domains to Knative Services.
]

#note[
  All Knative Serving components (Activator, Autoscaler, Controller, etc.) are
  *microservices*, not functions. Knative abstracts Kubernetes, providing a serverless
  *developer experience* without the FaaS per-invocation billing model.
]

=== Knative Serving: Resource Model

Knative Serving follows a *golden path standardization* using four Kubernetes CRDs:

#prop("Knative Serving CRDs")[
  - *Service* (`service.serving.knative.dev`): automatically manages the whole lifecycle of a workload. Controls creation of Route, Configuration, and Revisions. Ensures your app always has a route, a configuration, and a new revision for each update.
  - *Route* (`route.serving.knative.dev`): maps a network endpoint to one or more Revisions. Enables specific-path and per-revision traffic splitting.
  - *Configuration* (`configuration.serving.knative.dev`): maintains the desired state for the deployment. Separates code from configuration. *Modifying a configuration creates a new Revision.*
  - *Revision* (`revision.serving.knative.dev`): a point-in-time snapshot of code and configuration. Immutable — each modification creates a new Revision. Revisions can be retained as long as useful and independently scaled up/down.
]

=== Knative Serving: Orchestration via Revisions

Revisions are created indirectly when a Configuration is created or updated.

#prop("Revision-Based Deployment Benefits")[
  - *Automated Rollouts*: Route performs rollouts using a single, referenceable Revision.
  - *History tracking*: Revisions offer a historical record of changes.
  - *Rollback*: revert to a different Revision (previous known good Configuration).
]

Update scenarios:
- Push image, keep config #arrow update image, retain config.
- Update config, keep image #arrow modify config (e.g., env vars), keep image.
- *Controlled Rollout*: test revisions gradually by adjusting traffic specs.

=== Knative Request Flow

The request flow through Knative Serving:

+ *Ingress* receives the external request.
+ If the service is *scaled-to-zero*, Ingress goes through *Proxy mode* #arrow *Activator*.
+ Activator queues the request and signals the Autoscaler.
+ *Autoscaler* fetches metrics via Decider #arrow recommends a scale target to the Pod Autoscaler (PA).
+ PA scales the *Revision* (Deployment), creating/deleting *User Pods*.
+ Each User Pod contains a *Queue-Proxy* sidecar + the *Application* container.
+ Once pods are ready, traffic switches to *Serve mode* (direct path: Ingress #arrow Queue-Proxy #arrow Application).
+ Queue-Proxy reports metrics back to Autoscaler (scrapes).
+ *ServerlessService (SKS)* keeps track of pod endpoints: *Private Service* (actual pods) informs SKS; SKS updates the *Public Service* (external endpoint).

=== Knative Serving vs. Eventing

#prop("Serving vs. Eventing")[
  - *Serving* (C/S model, default): manages HTTP-triggered workloads. Handles revision history, traffic splitting, scale-to-zero. Very *DevOps-oriented*.
  - *Eventing* (event-based model): collection of APIs enabling event-driven architectures. Supports event sources (HTTP, CloudEvents), event brokers and channels for distribution, and event-driven function triggers.
]

== Knative Eventing

=== Motivation

#prop("Knative Eventing Goals")[
  - *Loosely Coupled Services*: services can be developed and deployed independently on Kubernetes, VMs, SaaS, FaaS — enabling reusability across languages and tools.
  - *Independent Event Production and Consumption*: producers generate events before consumers are ready; consumers express interest in events not yet being produced.
  - *Flexible Service Connections*: no need to modify producer or consumer when connecting; select specific subsets of events from a producer.
]

Key principles:
- *CloudEvents Specification*: utilizes and extends CloudEvents for event data exchange.
- *At-least-once delivery*: prioritizes reliable delivery using HTTP POST (push) transport.

Knative Eventing can drive *both* Client/Server and event-driven architectures simultaneously.

=== Eventing Components

#prop("Knative Eventing Components")[
  - *Event Sources*: support various sources — Kafka, Google Cloud Pub/Sub, custom events.
  - *Flow*: events are ingested and routed to different services.
  - *Triggers*: define what happens when an event occurs (e.g., invoke a function). A Trigger sends a request to a Knative serving pod computing the function.
  - *Subscriptions*: define how events are consumed by a service.
]

Two event-processing patterns:

- *Topology-based Event Routing* (`messaging.knative.dev`): events routed based on connections (e.g., Channel to Subscription) — resembles event plumbing where flow is like water through pipes; supports routing "reply" events back through the object topology.
- *Content-based Event Routing* (`eventing.knative.dev`): events routed based on event *attributes* (not just connections), via Brokers and Triggers — "picking parts off a conveyor belt" where each event is processed separately; handles reply events by re-enqueueing them in the originating Broker.

#note[
  Knative Eventing does *not* specify models for multi-stage workflows, correlated
  request-reply, or sequential event processing — but these can be built using its
  primitives or by integrating with external systems.
]

=== Eventing Interface Contracts

Knative Eventing defines *3 interface contracts* to connect Kubernetes objects as event
senders and recipients:

#prop("Knative Eventing Interface Contracts")[
  + *Addressable*: resources exposing a URL to receive events (e.g., Broker, Channel).
  + *Destination*: references the event delivery destination via an Addressable object or URL.
  + *Event Source*: resources that generate events and send them to a Destination.
]

=== Eventing: Broker and Trigger

#prop("Broker")[
  - Central *event-routing hub* that exposes a URL for event senders.
  - Implemented using different event-forwarding mechanisms (NATS, RabbitMQ, Kafka, in-memory interval).
  - Supports basic event-delivery options with customizable configurations.
]

#prop("Trigger")[
  - Filters events from a Broker based on *CloudEvents attributes*.
  - Routes events to a Destination.
  - Supports both cluster-local and external resource event delivery.
]

=== Eventing: Messaging Components

#prop("Channel")[
  - Abstract interface for *asynchronous fan-out queues*.
  - Allows parallel or chained event processing.
  - Enables flexible messaging technology replacement across environments.
]

#prop("Subscription (association of function and channel)")[
  - Defines a *destination* for events sent to a Channel.
  - Delivers events independently to each subscription.
  - Manages undelivered events and retries.
  - Uses the Destination interface for delivering events to various destination types.
]

=== Knative Eventing: Summary

Knative Eventing provides primitives for building flexible, event-driven workflows by
connecting Producers, Consumers, and Event Routers:

- *Trigger*: filter and route events based on CloudEvents attributes.
- *Broker*: central hub for event routing, forwarding to appropriate Triggers.
- *Channel*: provides asynchronous fan-out with parallel or chained processing.
- *Subscription*: delivers events to specific destinations with independent retries.

Advanced capabilities (multi-stage, correlated request-reply, sequential event processing)
can be built using these primitives or by integrating with external systems.

=== Knative Perspectives

#prop("Knative Future Directions")[
  - *Serverless platform integrations* with Knative.
  - *Portability to hybrid clouds*.
  - General-purpose platform for heterogeneous environments and use cases: Stream processing, SaaS events processing, Multimedia, Machine Learning, IoT.
]

== Choosing the Right Model

#important("Is FaaS the Answer to All Problems?")[
  All Cloud Computing models are evolving to support a wider plethora of customer needs.
  Tailoring a model to support a use case it was not designed for has consequences.
  *Choosing the right Cloud Computing model depends on many factors and requires an
  expert engineer.*

  FaaS is excellent for event-driven, bursty, stateless workloads. It is a poor fit for
  long-running processes, stateful computations, or latency-sensitive applications
  (due to cold-start times).
]
