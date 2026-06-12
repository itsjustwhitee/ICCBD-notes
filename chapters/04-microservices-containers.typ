#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= COMPONENTS, MICROSERVICES, AND CONTAINERS
#extra[
  Package: Components, Microservices, Container — `a - Microservices Container.pdf`
]

Modern distributed applications are no longer deployed as single blobs of code.
This chapter traces the path from *monolithic* architectures to *microservices*,
then explains how *containers* solve the hosting, isolation, and reproducibility
problems that microservices introduce.

== From Monolith to Microservices <ch04-microservices>

=== The Monolith

#def("Software Monolith")[
  A #kw[monolith] is an application built as a *single deployable unit*:
  one codebase, one build pipeline, one technology stack, deployed all-at-once.
]
#v(-1em)
#callout(color: green, title: "Monolith Benefits", icon: "✅")[
  - *Simple mental model*: developers work on a single, unified codebase.
  - *Single deployment unit*: one artefact to build, ship, and run.
  - *Simple scaling model*: run multiple identical copies behind a load balancer.
]
#v(-1em)
#callout(color: danger, title: "Monolith Problems", icon: "❌")[
  - *Codebase intimidation*: the #hl[code base grows huge] and difficult to navigate.
  - #hl[*Slow tooling*]: refactoring takes minutes, builds take hours, CI test suites take days.
  - *Coarse-grained scaling*: a single bottleneck forces scaling the *whole system*, even unused parts, extremely resource-intensive.
  - *Infrequent deployments*: #hl[re-deploying means halting the whole system]; failed deploys increase the perceived risk of any change.
  - *Technology lock-in*: the whole system is bound to one stack, even when parts would benefit from a different one.
]

=== Microservices

#def("Microservice")[
  The #kw[microservice] architectural style is an approach to developing a single
  application as a *suite of small, independently deployable services*, each running
  in its own process and communicating via lightweight mechanisms (typically HTTP/REST).
  Services are built around *business capabilities*, may be written in different
  languages, and use different data-storage technologies.
]
#v(-1em)
#prop("Core Properties of a Microservice")[
  - #hl[*Runs in its own process*] #swarrow faults are isolated #so one service crashing does not bring others down.
  - *#hl[Deployed independently]* #swarrow a new version of one service does not require re-deploying anything else.
  - #hl[*Scales independently*] #swarrow identified bottlenecks can be addressed directly without scaling the whole system.
  - *Owns its data* #swarrow no shared databases, #hl[each service manages its own storage] (*Bounded Context*).
  - *Polyglot* #swarrow #hl[each service can choose the language and stack] best suited for its task.
  - #hl[*Single responsibility*] #swarrow each service does one thing well.
  - #hl[*Composable*] #swarrow services are combined to build higher-level functionality.
  - *Small team* #swarrow a microservice must be manageable by a single development team.
  - *Decentralized governance* #swarrow no system-wide technology mandates.
  - *Culture of automation* #swarrow continuous integration and deployment are non-optional.
]
#v(-1em)
#why("a microservice own its data?")[
  Sharing a database between services creates hidden coupling: a schema change in one service
  can silently break another. Owning data forces explicit, #hl[versioned interfaces between services]
  and enables each service to choose the storage model (relational, document, time-series…)
  best suited for its access patterns.
]

=== Benefits of the Microservice Decomposition

*Independent codebase*: each service has its own repository.
Tools are fast (build/test/refactor in seconds), startup is quick, and there are
no accidental cross-dependencies between codebases.

*Independent technology stack*: teams can select the best tool for each job
and experiment with new technologies at low risk — a bad experiment affects only
one small service.

#hl[*Fine-grained scaling*: only the bottleneck service needs to scale].
*Data sharding* can be applied per service. Services that are not bottlenecks stay
simple and unscaled, reducing resource waste.

*Independent feature evolution*: a new version of a service can be deployed without
touching the rest of the system, up to and including a complete rewrite (as long as
the *service interface remains stable*).

#important("The Cost of Microservices")[
  Microservices do not come for free:
  - Many services #so many deployment units #so #hl[more operational complexity].
  - *#hl[Automation] is not optional*, manual deployment at microservice scale is impossible.
  - Distributed system problems (network failures, partial outages, data consistency) become routine.
]

=== Prerequisites Before Adopting Microservices

#prop("Microservice Prerequisites")[
  - *Rapid provisioning*: dev teams must be able to automatically provision new infrastructure.
  - *Basic #hl[monitoring]*: essential to detect and diagnose problems across many services.
  - *Rapid application deployment*: deployments must be controlled, traceable, and rollback-friendly.
]
#v(-1em)
#analogy("You Build It, You Run It")[
  In a monolith, a separate ops team manages production. In a microservice world,
  the team that writes a service is also responsible for running it in production.
  This forces engineers to think about operability from day one, but it also means
  the team that knows the code best is the one paged at 3 a.m.
]

== Hosting Problems

Once services are broken apart, *where and how do you run them?*
Four fundamental problems arise:

#side-note(color: danger)[
- *Process isolation*: services must not interfere with each other's memory or resources.
- *Process management*: start, stop, and monitor independent processes reliably.
- *Process packing*: fit multiple services on shared hardware efficiently.
- *Reproducible environment*: guarantee the same execution environment across development, test, and production.
]

Running everything directly on *bare metal* solves none of these:
services cannot be isolated, dependency conflicts arise, resource allocation
is unpredictable, and reproducing an exact environment on a different machine
is manual and error-prone.

== Process Isolation

#def("Process")[
  A #kw[process] is the OS representation of a running program. It has
  a private *memory space* and kernel data structures tracking its execution state.
]

#hl[UNIX isolates processes by default] through:
- #hl[*Memory space isolation*]: each process has its *own virtual address space*.
- #hl[*Privilege isolation*]: a process inherits the privileges of the user that created it.

But default UNIX isolation is coarse #swarrow processes share the same filesystem root,
the same network stack, the same PID namespace, etc.\
#hl[*Containers* extend isolation to cover all of these dimensions].
#extra[
  Containers are processes with their own "system" space we can say..\.😄
]

=== A Brief History of Container Isolation

#extra[
  #side-note(color:gray)[
    From the first `chroot` (1979) to modern container runtimes:
  - *1979 — Unix V7 `chroot`*: confines a process to a subtree of the filesystem.
  - *2000 — FreeBSD Jails*: extends `chroot` with network and process isolation.
  - *2006 — Process Containers (Google)*: resource-limit groups, later renamed *cgroups*.
  - *2008 — LXC*: first complete Linux container implementation using namespaces + cgroups.
  - *2013 — Docker*: wraps LXC (later its own runtime) with a developer-friendly image format and tooling.
  - *2015 — Open Container Initiative (OCI)*: industry standard for container image and runtime specs.
  ]
]

=== Linux Namespaces

#def("Linux Namespace")[
  A #kw[namespace] limits the *scope of kernel names and data structures* at process
  granularity\ #swarrow #hl[each namespace gives processes an *isolated* view of a system resource].
]

Available namespace types:

- `MNT` #swarrow mount points (filesystem view)
- `PID` #swarrow process IDs (a container sees only its own processes)
- `NET` #swarrow network devices, stacks, ports
- `IPC` #swarrow message queues, semaphores, shared memory
- `UTS` #swarrow hostname and NIS domain name
- `USR` #swarrow user and group IDs
- `CGRP` #swarrow cgroup root directory

By #hl[combining namespaces] a container gets an #hl[isolated view of the world] while
still sharing the *same kernel* as other containers.
#extra[
  Under the hood, namespaces work by decoupling a process from the global system tables and mapping its execution to private kernel pointers tree structuring links. Every node can see only itself. This abstraction enables dynamic translations, most notably within the `PID` namespace, where the main containerized process is assigned *PID 1* inside its isolated scope—behaving like the system init process—while the host OS simultaneously tracks it using a standard global PID. Similarly, the network stack isolation enforced by the `NET` namespace is bridged to the physical world by creating a virtual ethernet pair (`veth`), which acts as a software patch cord routing traffic between the container's private stack and the host's network bridge.
]
#v(-0.5em)
#analogy("The Isolated Apartment")[
  Namespaces are like separate apartments in the same building.
  Each tenant sees their own private space (filesystem, network, processes)
  but the building's structural elements (the kernel) are shared.
  Walls prevent tenants from seeing or interfering with each other,
  but they all pay rent to the same landlord.
]

=== Linux Control Groups (cgroups)

#def("cgroups")[
  #kw[cgroups] (Control Groups) are a kernel mechanism to *limit*, *account for*,
  and *isolate* the *resource usage* of groups of processes.
]

Key controllers:

- *cpu* #swarrow enforce fair CPU time distribution among groups of processes.
- *memory* #swarrow set soft and hard memory limits, hierarchical, child cgroups contribute to ancestor totals.
- *net_cls* #swarrow tag network packets with a class identifier for traffic shaping.
- *cpuset* #swarrow pin processes to specific CPUs or NUMA nodes.
#v(-0.6em)
#note[
  #hl[Namespaces provide *visibility isolation*] (what a process can see),
  while #hl[cgroups provide *resource isolation*] (how much a process can consume).
  Together they form the foundation of every Linux container.
]
#extra[
  Conversely, control groups manage physical resource boundaries rather than visibility, exposing their interface to user-space through a virtual filesystem mounted at `/sys/fs/cgroup/`. Setting consumption ceilings simply involves writing raw configuration values into these kernel-managed text files. Memory allocation is governed by strict *Hard Limits*, meaning that if processes exceed their defined byte threshold, the kernel triggers the *OOM (Out Of Memory) Killer* to instantly terminate the offender. On the other hand, CPU allocation relies on *Soft Limits* and proportional shares, which do not artificially throttle performance when the host is idle, but instead guarantee a fair, weighted slice of CPU cycles only during resource contention.
]
#v(-0.8em)
#analogy("The Isolated Apartment (Extended)")[
  - *Namespaces (The Walls & Meters):* Give each tenant their own apartment numbers (PID), their own private Wi-Fi router (NET), and their own front door key (MNT). They cannot see into other apartments.
  - *Cgroups (The Circuit Breakers & Valves):* Are the utility caps imposed by the landlord. If a tenant uses too much water (Memory), the main valve shuts off instantly (OOM Killer). If everyone turns on the AC at the same time (CPU contention), the landlord throttles the power dynamically based on who pays a higher contract (CPU shares).
]
== Containers

#def("Container")[
  A #kw[container] is a *lightweight* form of *process virtualization* built on kernel
  *namespaces* and *cgroups*. It runs as a normal process but has a *restricted*, *isolated
  view* of the system (its own filesystem root, its own network stack, its own PID
  space) while #hl[sharing the host kernel] with other containers.
]
#v(-1em)
#important("Container vs VM")[
  - *VMs* virtualize hardware: each VM runs a full OS on a hypervisor. Strong isolation, heavy overhead.
  - *Containers* virtualize the OS user space: all containers share the host kernel. Much lighter, faster startup (seconds vs. minutes), but isolation is weaker than a VM.
  - *Bare processes*: no isolation at all, no resource limits, no reproducible environment.
]

#important("Why Containers for Microservices")[
  Containers answer all four hosting problems at once:
  - #hl[*Isolation*: namespaces] prevent services from interfering.
  - #hl[*Management*: container runtimes] provide start/stop/inspect/restart #hl[primitives].
  - #hl[*Packing*: cgroups] allow fitting many containers on one host with predictable resource budgets.
  - #hl[*Reproducibility*]: the container #hl[*image* bundles the application] with all its dependencies. The same image runs identically on any machine.
]

== Docker <ch04-docker>

Docker is the dominant *container engine*: a platform for configuring, building,
distributing, and managing the full lifecycle of containers.

=== Docker Engine Architecture

Docker follows a *client–server* architecture:

- *Docker daemon* (`dockerd`): background service that manages containers, images, networks, and volumes.
- *Docker CLI / REST API*: client that sends commands to the daemon.

The daemon handles the *container lifecycle*:
create #arrow start #arrow pause #arrow unpause #arrow stop #arrow remove.

#figure(
  image("../assets/docker-API.png",width: 80%),
  caption: [Docker operation on container(s) and container life-cycle.]
)

=== Docker Images and Layers

#def("Docker Image")[
  A #kw[Docker image] is a *#underline[read-only], layered filesystem snapshot* that bundles
  the application binary with its OS libraries, runtime dependencies, and configuration.
  Each layer records a set of filesystem changes. Layers are identified by cryptographic
  content hashes (SHA-256) and shared across images to save space.
]

- #hl[*Image layers* are *read-only*]. Every `RUN`, `COPY`, or `ADD` instruction in a Dockerfile creates a new immutable layer.
- *Container layer*: when a #hl[container starts, Docker adds a thin *read-write* layer on top]. Writes go here, but they #underline[do not modify the image].
- *Copy-on-Write*: reading a file reads through the stack, writing copies the file into the R/W layer first.

#why([_layered images_])[
  Layers are shared across images. If 10 services all base on `ubuntu:22.04`,
  the base layers are stored once on disk and in the registry.
  Only the diff layers unique to each service need to be pulled or pushed,
  making distribution efficient.
]

=== Dockerfile

A #hl[`Dockerfile` is the *recipe* for building an image]:

- *Starting image* (`FROM`): base layer to build on.
- *Configuration instructions* (`ENV`, `ARG`, `EXPOSE`): metadata, no new layer.
- #hl[*Filesystem instructions*] (`RUN`, `COPY`, `ADD`): #hl[modify the filesystem #so create a new layer].
- *Multi-stage builds*: use intermediate images to compile code, then copy only the built artefact into the final image, keeping it small.

=== Docker Networks

Docker provides several network drivers:

- *Bridge* (default): software bridge #swarrow containers on the same bridge can communicate, others are isolated.
- #hl[*Host*: removes network isolation], the container shares the host's network stack directly.
- *Overlay*: software-defined network spanning multiple Docker hosts (used in Swarm/orchestration).
- *Macvlan*: assigns a MAC address to the container, appears as a physical device on the LAN.
- *None*: disables all networking.

=== Docker Plugins

#hl[Plugins extend the Docker Engine] with third-party functionality:

- *Volume plugins*: allow volumes to persist across hosts (e.g., NFS, cloud storage backends).
- *Network plugins*: advanced networking policies and configurations.
- *Authorization plugins*: access control within Docker environments.
- *Log plugins*: route container logs to external systems.

=== Configuration and Secrets

Docker provides three mechanisms to pass configuration to containers:

- *Environment variables*: simple key-value pairs injected at runtime.
- *Config files*: mounted into the container filesystem.
- *Secrets*: encrypted, stored separately, mounted only in memory, for sensitive data (passwords, tokens).

=== Docker Compose

`docker-compose` (or `docker compose`) is a #hl[tool for *defining and running multi-container applications*] using a single YAML file.

It allows specifying services, their images, networks, volumes, and dependencies in one place, enabling the entire application stack to be brought up with a single command (`docker compose up`).

#extra[
  Docker Compose is the natural stepping stone between running containers manually and using a full orchestrator like Kubernetes.
  It works well for local development and small deployments, but does not handle cross-host scaling or self-healing (that is Kubernetes's domain).
]

== Microservice Resilience Patterns

When services call each other over the network, failures in one service can cascade across the whole system. Two foundational patterns address this: the *Circuit Breaker* and *Retry/Timeout* policies.

=== Circuit Breaker

#def("Circuit Breaker")[
  The #kw[Circuit Breaker] is a stability pattern that prevents *cascading failures* in a distributed system. It wraps calls to a downstream service and monitors their success/failure rate. When failures exceed a threshold, the breaker *trips open* and short-circuits all subsequent calls immediately, returning a fallback response without touching the broken service, giving it time to recover.

  The breaker operates as a *three-state machine*:
  - #hl[*CLOSED*] (normal): all requests flow through. The breaker tracks outcomes in a rolling window. If failures exceed the *Failure Rate Threshold*, it trips to OPEN.
  - #hl[*OPEN*] (broken): all requests are immediately short-circuited, no call reaches the downstream service. A *Sleep Window* timer runs #arrow when it expires, the breaker moves to HALF-OPEN.
  - #hl[*HALF-OPEN*] (probing): a limited number of trial requests are let through. If they succeed, the breaker returns to CLOSED. If any fails, it goes back to OPEN and resets the timer.
]
#v(-1em)
#analogy("Electrical Breaker")[
  The pattern is named after the electrical circuit breaker.\
  An electrical circuit breaker monitors current. If it spikes, it trips to protect the wiring and appliances. The software circuit breaker monitors call failure rate. If it spikes, it trips to protect the upstream service's resources and let the downstream service recover.
]

#v(-1em)
#figure(
  image("../assets/circuit-breaker.png"),
  caption: [Circuit Breaker pattern.]
)

#prop("Key Configuration Parameters")[
  - *Failure Rate Threshold* #swarrow percentage of failures (e.g., 50%) within the rolling window that trips the breaker OPEN.
  - *Sliding Window Size* #swarrow sample size for computing the failure rate: count-based (last N calls) or time-based (last N seconds).
  - *Minimum Number of Calls* #swarrow minimum volume required before the failure rate can be calculated (prevents premature tripping on 1–2 early failures).
  - *Wait Duration in Open State* #swarrow length of the Sleep Window before the breaker tries HALF-OPEN.
  - *Permitted Calls in Half-Open* #swarrow how many trial requests probe the downstream health.
  - *Slow Call Rate Threshold* #swarrow calls exceeding a duration threshold are treated as failures.
]
#v(-0.8em)
#important("Benefits of Circuit Breaking")[
  - #hl[*Prevents cascading failures*]: a slow downstream service cannot exhaust thread pools in upstream services.
  - #hl[*Graceful degradation*]: return cached data or a default response instead of a hard crash.
  - #hl[*Self-healing*]: downstream services get breathing room to recover without being bombarded by retries.
  - #hl[*Fast failure*]: instead of blocking for a 10-second timeout, the caller gets an instant response.
]
#v(-1em)
#note[
  Circuit breakers should *not* trip on 4xx client errors (e.g., `404 Not Found`), those indicate caller mistakes, not service health. Only trip on 5xx server errors, network timeouts, and connection failures.
]

=== Implementation

Circuit breakers can be implemented at two levels:

- *Application level*: embed a library in each service. Common choices: *Resilience4j* (Java/Spring Boot), *Polly* (.NET), *go-resiliency* (Go). Netflix's *Hystrix* is legacy/archived.
- *Infrastructure level (Service Mesh)*: the circuit breaker logic lives in a sidecar proxy, transparent to application code. *Istio/Envoy* uses outlier detection, *Linkerd* tracks failure rates per cluster. This keeps application code free of resilience plumbing.