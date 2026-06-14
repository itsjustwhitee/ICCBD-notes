# Infrastructures for Cloud Computing and Big Data (ICCBD) Notes

**Course:** Infrastructures for Cloud Computing and Big Data (ICCBD)  
**Program:** Master in Computer Engineering - University of Bologna (Unibo)  
**Professors:** Andrea Sabbioni, Antonio Corradi  
**Academic Year:** 2025/2026  
**Author:** [Matteo Fontolan](https://itsjustwhitee.github.io)

---

## About

These are personal lecture notes compiled from the official course slides of ICCBD at Unibo.  
They are written in **Typst** using the [`justwhitee-notes`](https://typst.app/universe/package/justwhitee-notes/) template (`@preview/justwhitee-notes:0.2.2`).

The compiled PDF (`ICCBD-notes.pdf`) is generated from `main.typ`, which includes all chapters (in `chapters/`) in the order listed below.

---

## Template

Notes are typeset with the [`justwhitee-notes`](https://typst.app/universe/package/justwhitee-notes/) Typst package.  
It provides structured callout/side-notes boxes (`#def`, `#prop`, `#important`, `#analogy`, `#example`, `#why`, `#note`, `#warning`, `#extra`, `#proof`), inline highlights (`#kw[]`, `#hl[]`), and relation arrows (`#arrow`, `#swarrow`, `#so`), other than a general styling.

---

## Structure

The notes are split into **6 parts** and **18 chapters**.

> These notes adapt the official course slide decks (indicated at the start of each chapter) but rearrange the content to avoid redundancies. As a result, certain topics may be moved from their original slide order to more logical locations. In these cases, a #note block is explicitly provided to reference the specific chapter or section where the concept is thoroughly deepened.

---

### Part 1 | Foundations

#### Chapter 1 · Introduction
The Cloud, data center physical and network architecture (3-Tier, Leaf-Spine), compute architecture, hyperscalers and sustainability, the large cloud ecosystem, Big Data (5/6 Vs), application scenarios (Smart Cities, Industry 4.0/5.0), QoS overview, middleware families and use cases, cloud as an evolution, course roadmap.

#### Chapter 2 · Goals, Basics, Models
Modern distributed systems challenges, the ICCBD resource/API approach (black-box vs open-box), abstraction and transparency, TINA-C architecture (roles, layers, DPE), monitoring vs observability (three-plane model: User/Management/Control), minimal intrusion principle, granularity, Service-Oriented Architecture (SOA, 3 actors), Enterprise Application Integration (EAI), Gartner Hype Cycle, resource classification, objects → components → services progression, containers and container delegation, DevOps, microservices overview, Docker and Kubernetes intro.

#### Chapter 3 · Resource Management Models
QoS fundamentals (functional vs non-functional properties, SLA), general resource management (preventive vs reactive, static vs dynamic), application deployment and process allocation, allocation strategies and decision models, agent-based management (DFS), load sharing and the Farm pattern, load balancing and process migration (internal/external, sender/receiver initiative, centralized/decentralized), scalability and orchestrators (Kubernetes overview), service mesh (Istio), CI/CD and Infrastructure as Code (IaC), computational models for parallelization (speedup, efficiency, Amdahl's law, iso-efficiency).

#### Chapter 3b · UNIX Files and Single Primitive Atomicity
UNIX per-primitive atomicity model, file and directory primitives, file system architecture (file descriptors, Global File Table, i-nodes, cache, disk), i-node and directory structure, non-determinism under concurrent writes, directory listing as a moving target (eventual consistency at the primitive level).

---

### Part 2 | Middleware and Architecture

#### Chapter 4 · Components, Microservices, and Containers
Monolith vs microservice architecture (trade-offs, prerequisites, benefits), the four hosting problems (isolation, management, packing, reproducibility), process isolation (UNIX model, history of containers), Linux namespaces (MNT, PID, NET, IPC, UTS, USR, CGRP), Linux cgroups (cpu, memory, net_cls, cpuset), containers (vs VMs, vs bare processes), Docker (engine architecture, images and layers, Dockerfile, networks, plugins, secrets, Docker Compose), microservice resilience patterns: **Circuit Breaker** (CLOSED/OPEN/HALF-OPEN state machine, configuration parameters, application-level and service-mesh implementation).

#### Chapter 5 · Middleware and Cloud Models
What is middleware, middleware support functions, layered middleware view (host infrastructure, distribution, common services, domain-specific), taxonomy (RPC/RMI, MOM, DOC/OO, DTP monitor, DB, adaptive/reflective, self-*, specialized), usage scenarios, design issues, cloud history, what a cloud is (SaaS/PaaS/IaaS, XaaS), NIST cloud definition and business roles, QoS-related cloud properties, cloud architecture and data center organization, cloud management and monitoring, middleware for cloud.

#### Chapter 6 · Cloud and Data Center Global Strategies
Cloud DC architecture (edge vs internal levels, two-level replication), sharding, consistency vs speed (critical paths, asynchronous effects), CAP theorem, ACID properties and nested transactions (2PC), BASE properties and eventual consistency, consistency spectrum, eBay's five internet-scale principles (partition everything, asynchrony everywhere, automate everything, everything fails, embrace inconsistency).

#### Chapter 7 · CORBA, Advanced C/S Models, Events, and MOM
CORBA (ORB, IDL, data types, language mapping, Holder/Helper, IOR, POA), advanced client/server models (Pull/Push, delegation with Poll Object and Call-Back Object), message exchange modes and coupling, distributed events and publish-subscribe, Linda/Tuple Model (Gelernter, tuple spaces, in/out, non-determinism), MOM - Message Oriented Middleware (deployment models, hub-and-spoke vs P2P, MQSeries IBM), Apache Kafka (pub/sub model, topics/partitions/brokers, QoS, producers/consumers/ZooKeeper), MQTT (IoT), OPC UA, group communication and IP multicast (IGMP v1/v2, spanning tree, pruning/grafting, DVMRP, MOSPF, PIM Scattered/Dense, CBT).

---

### Part 3 | Cloud Infrastructure and Services

#### Chapter 8 · Kubernetes
What Kubernetes is and why, cluster architecture (control plane: API server, controller manager, scheduler, etcd; worker nodes: kubelet, kube-proxy, container runtime), declarative model and YAML manifests, controllers and the control loop, operator pattern, etcd and RAFT consensus, nodes/pods/workloads (Deployments, StatefulSets, DaemonSets, Jobs), storage (PV, PVC, StorageClass), networking (network model, kube-proxy, CNI plugins, Services, Ingress), load balancing and autoscaling (HPA, KEDA), service mesh (Istio architecture, traffic management, observability, security).

#### Chapter 10 · OpenStack
Cloud data centres and IaaS, NIST cloud reference model, cloud resource virtualization, OpenStack overview (history, high-level architecture, logical layers, design guidelines), core services: Nova (compute), Swift (object storage), Cinder (block storage), Glance (image), Horizon (dashboard), Keystone (identity, four sub-services, request flow), Neutron (networking, agents, tenant networks), Ceilometer (telemetry), Heat (orchestration).

#### Chapter 11 · Serverless Computing
Cloud service model spectrum (MaaS → IaaS → PaaS → FaaS → SaaS), serverless definitions, BaaS + FaaS model, Backend as a Service (DBaaS, Storage, CDN, Cognitive), Function as a Service (stateless, event-driven, ephemeral, zero-scaling), **Cold Start** (definition, mitigation with slim images / warm pools / HTTP-mode watchdogs), FaaS as finer decomposition beyond microservices, FaaS architecture (trigger, controller, function executor), function composition patterns (merging, reflective invocation, continuous passing, facade, map-reduce), hosted and open-source platforms, OpenFaaS (gateway, Prometheus, NATS, providers, watchdog, faasd), Apache OpenWhisk (Kafka + CouchDB architecture), Knative (serving: revisions/routes/configurations, autoscaler, activator, queue-proxy; eventing: brokers, triggers, channels, subscriptions, CloudEvents).

#### Chapter 17 · Stream Processing
Motivation for streaming vs batch, the stream processing model (windowing, watermarks, support functions), Spark Streaming (discretized stream processing, DStreams, fault tolerance), Apache Flink (architecture, pipelining, distributed snapshots), processing guarantees (at-most-once, at-least-once, exactly-once), comparison Spark Streaming vs Flink.

---

### Part 4 | Distributed Coordination

#### Chapter 12 · Replication for Dependability
Core concepts (dependability, faults/errors/failures, fault types), service unavailability indicators, fault identification and recovery, SPoF and single-fault assumption, formal properties (availability, reliability, correctness, vitality), fault-tolerance architectures (replicated components, stable memory, TANDEM, RAID), minimal intrusion principle, high replication costs, replication architectures (passive master-slave with checkpoints, active replication), the five phases of replication (request → coordination → execution → agreement → delivery), eager/lazy and optimistic/pessimistic update policies, industrial evolution, ALMA web service case study, high-availability clusters (failover, heartbeat, SAN, Red Hat cluster), optimistic lazy policies and eventual consistency, Amazon S3, Docker Swarm, Apache ZooKeeper (architecture, reads/writes, leader election).

#### Chapter 13 · Group Issues and Policies
Partitioning and replication trade-offs, group communication semantics (global vs selective solicitation, positive vs negative confirmation), reliable multicast (hold-back, NAK), multicast ordering (no ordering, FIFO, causal, atomic - costs and trade-offs), synchronization (clock synchronization: UTC, NTP, Berkeley time; minimal overhead strategies), Lamport happened-before relationship (partial order, local and remote events), logical clocks and timestamps (clock condition, three implementation rules), total ordering from logical clocks, vector clocks (bidirectional causality detection, vector update protocol), mutual exclusion (centralized coordinator, Lamport protocol, Ricart-Agrawala - message counts), atomic multicast and CATOCS, ISIS system (ABCast, CBCast, GBCast), JGROUPS, Apache ZooKeeper, token-based synchronization (token ring, recovery, token regeneration), election protocols (Bully algorithm, ring election), global state and distributed snapshots (consistent cuts, marker algorithm, channel state recording).

---

### Part 5 | Network Quality of Service

#### Chapter 14 · QoS: Quality of Service
QoS in different environments (elastic vs non-elastic applications), QoS indicators (bandwidth, latency/RTT formula, jitter, skew, QoE), QoS management (SLA lifecycle, active path), video streaming services (1-1, M-1, M-M, RTSP), IntServ - Integrated Services (RSVP two-phase protocol: Path/Resv, soft state, RTP, RTCP), DiffServ - Differentiated Services (service classes EF/AF/BE, DS byte, traffic conditioning: meter/marker/dropper/shaper, IntServ+DiffServ together), SIP - Session Initiation Protocol (entities, INVITE/ACK/BYE), network management (SNMP v1/v2/v3, RMON, OSI CMISE/P), router QoS policies (best-effort FIFO, Kleinrock conservation law, Leaky Bucket, Token Bucket, Round Robin, Fair Queuing, RED congestion prevention).

---

### Part 6 | Big Data Infrastructure

#### Chapter 9 · Overlay Networks and File Systems
Overlay network classification and lifecycle, unstructured overlays (Napster centralized lookup, Gnutella flooding), structured overlays and Distributed Hash Tables (Chord finger tables and routing, Pastry), DHT applications, distributed file systems (NFS, AFS/quality file systems), modern global file systems, GFS - Google File System (design assumptions, novel strategies: large chunks, append semantics, single master, atomic record append), HDFS - Hadoop Distributed File System (NameNode, DataNode, replication pipeline).

#### Chapter 15 · Data Storage
NoSQL movement and motivations, scale-out vs scale-up, NoSQL data models (Key-Value, Document, Wide-Column, Graph), key-value abstraction (DHT-based, immutable elements), column-oriented storage, Cassandra (DC model, ring architecture, keyspaces, placement strategies, snitches, write path: commit log → memtable → SSTable, Bloom filter, compaction, read path, gossip and failure detection, eventual consistency, consistency levels, quorums), MongoDB (document model, queries, sharding architecture, replication, read preferences, write concern, balancing), ACID vs BASE fundamental trade-off, Big Data infrastructure properties.

#### Chapter 16 · Data Batching
Big Data characteristics, batch processing in large clusters, data parallelism, MapReduce programming model (functional origins, Map/Reduce phases, word count example, other applications), MapReduce implementation (master-worker architecture, scheduling, data locality, fault tolerance, backup tasks/stragglers), Hadoop (YARN resource manager, architecture, workflow, Sahara on OpenStack), Apache Spark (motivation, RDDs - Resilient Distributed Datasets, transformations vs actions, persistence, fault tolerance via lineage, iterative workload performance, architecture, deployment modes), Big Data tools ecosystem, resource analysis.

---

## Concept Map

A schematic **concept map** that summarizes the whole course at a glance lives in [`map/`](map/).  
Each main **technology** is a box grouping its **core components / sub-technologies** (e.g. *Kubernetes* → API server, etcd/RAFT, scheduler, controllers, Pods → containers; *OpenStack* → Nova, Neutron, Cinder, Swift, Glance, Keystone; *Knative* → Serving, Eventing, scale-to-zero, built on Kubernetes). Cross-references between technologies are shown as `→` pointer boxes and short "Links" chips, keeping the view readable rather than a tangle of arrows. It covers 26 technologies across the same topics as the notes, and is handy for **quick revision**.

Available formats:

| File | Use |
|------|-----|
| [`map/ICCBD-concept-map.svg`](map/ICCBD-concept-map.svg) | Best for **viewing** — single page, infinitely zoomable |
| [`map/ICCBD-concept-map.html`](map/ICCBD-concept-map.html) | Interactive view in a browser |
| [`map/ICCBD-concept-map.drawio`](map/ICCBD-concept-map.drawio) | **Editable** source — open at [app.diagrams.net](https://app.diagrams.net) or draw.io desktop |
| [`map/generate-concept-map.py`](map/generate-concept-map.py) | Script that regenerates the `.drawio` (for bulk edits) |

> The map is a single large canvas, so **PDF export splits it across pages badly**, prefer the **SVG** or **HTML** export, or open the `.drawio` in any editor.

---

## Building

```bash
typst compile main.typ
```

Requires [Typst](https://typst.app/) and the `justwhitee-notes` package (automatically fetched from the Typst Universe on first compile).
> For full requirements refer to [justwhitee-notes docs](https://typst.app/universe/package/justwhitee-notes/).
> At the moment of writing this README notes are not complete/fully revisioned, but updated final pdf should be included :D

---

## Disclaimer

These are personal study notes and may contain errors or omissions. They do not replace the official course material and lectures.

## Related Useful Stuff
- [**Micro-Project Activity** bt *Matteo Fontolan*](https://github.com/itsjustwhitee/ICCBD-micro-proj).
- [**Notes** by *Alessandro Marcellini*](https://github.com/alessandromarcellini/cloud_computing_notes).