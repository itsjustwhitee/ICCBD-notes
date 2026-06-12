#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()
#v(1em)

= INTRODUCTION
#extra[
  Package: Class Starting - `1-Starting26.pdf`
]

The course builds a deep, practical understanding of *large distributed systems*, approached from two angles:
- The *user perspective*: what services are offered and consumed.
- The *designer/implementer perspective*: what is behind the architecture, how it behaves, how it is managed.

The #hl[focus is on *runtime operations across the full system lifecycle*], not just static design or configuration. The idea is that execution time dominates the life of any system, and that is where the most interesting engineering challenges lie.

We live immersed in distributed IT infrastructure, personally, socially, and professionally. Every organization, regardless of its attitude toward ICT (_Information and Communication Technology_), has consolidated usage of *off-premises resources*.

Key features of today's environments:
- *Big data* available to anyone
- Processing distributed across many *remote* localities
- Large-scale applications running continuously
Both companies and individuals share the same tools and requirements. The IT landscape has become *homogeneous*.

== The Cloud

#def("Cloud")[
  A #kw[cloud] is a *#underline[coordinated] network of multiple geographically distributed data centers* that work together to provide unified, high-quality services to users.
]

Data centers must be far apart enough to:
- Survive local disasters *independently*,
- Provide geographically *replicated* services.

A #hl[connected multi data center cloud is far more efficient and sustainable than any isolated facility.]
#table(
  align: (x,y) => {if y == 0 { center} else { left }},
  fill: (x,y) => {if y == 0 { accent.lighten(40%)} else { if calc.rem(y,2) == 0 { gray.lighten((70%)) } else { white }}},
  columns: (2fr, 3fr),
  stroke: 0.5pt,
  inset: 0.8em,
  [*_Benefit_*], [_*Explanation*_],
  [Workload shifting], [Move tasks to greener or cheaper regions. #v(-0.4em)#extra[e.g., wind energy peaks in Denmark at night]],
  [Higher utilization],[Consolidate loads, turn off idle servers.],
  [Cooling efficiency],[Route workloads to colder climates or facilities with free cooling.],
  [Redundancy without overprovisioning ],[Spread failover capacity across sites instead of duplicating hardware everywhere. ],
  [AI-driven global optimization],[Predictive maintenance, self-optimizing behavior.],
  [Lifecycle & circular economy ],[Reuse hardware across regions, reduce e-waste.],
  [Edge + core coordination],[Process data locally, send only results to core DCs\ #so less energy.],
)

#problem[\
  Cloud and Big Data infrastructure consumption is enormous and growing:

  - Global data centers consume around _200 TWh_ of *electricity* per year, that is comparable to entire industrialized countries.
  - Cloud, Big Data, and AI workloads are increasing *water usage* (for cooling) and the overall *carbon footprint*.
  - Exponential growth of digital services makes redesigning infrastructure a necessity
  Main challenges: *Energy Consumption*, *Water Consumption*, *CO₂ Emissions*.
]
#v(-1em)
#side-note(color: green)[
  ☑️ #kw(color: green)[Solution]:
  #text(fill: green.darken(25%))[
    - *Renewable energy*:  solar, wind, Power Purchase Agreements (PPAs), 24/7 carbon-free energy matching.
    - *Low-impact cooling*, such as free cooling (outside air), liquid cooling, hot/cold aisle containment, AI-driven thermal management.
    - *Workload optimization* shifting workloads based on renewable energy availability.
    - Recover waste heat for district heating, refurbish/reuse servers (circular economy).
    - More transparent metrics (like PUE and WUE).
  ]
]

== DC Physical Architecture

- #kw()[Racks] are vertical cabinets holding servers (computers), storage arrays, network switches, and PDUs (Power Distribution Units).
- *Rows*: racks are arranged in a *hot aisle / cold aisle* configuration to optimize airflow. Cold air enters from one aisle, is consumed by servers, and exits as hot air through the opposite aisle.
- *Rooms / Pods*: rows are grouped into isolated cooling zones, each with its own power feed and network aggregation layer.
#v(-0.6em)
#note[
  Physical layout directly affects cable length, airflow efficiency, and energy consumption.
]
#figure(
  grid(
    columns: (1.25fr, 1fr),
    gutter: 0pt,
    image("../assets/dc-arc.png", width: 100%),
    image("../assets/dc-aisle.png", width: 100%)
  ),
  caption: [Data center physical architecture.]
)<dc-arc>

- *UPS (Uninterruptable Power Supplies)*: backup power, either centralized or at rack level.
- *PDUs*: distribute power inside racks.
- *Cooling systems*: often the largest non-IT energy cost. Technologies include CRAC, CRAH units, in-row cooling, and liquid cooling.

== DC Network Architecture
Before shifting to the architecture, we must introduce the concept of east-west traffic and north-south traffic.

#def("East-West Traffic")[
  #kw[East-West traffic] is the data flow between servers within the same data center:
  - server ↔ server,
  - server ↔ storage,
  - GPU cluster communication.
]
#def("North-South Traffic")[
  #kw[North-South traffic] is the data flow between the data center and external entities, that passes through core switches:
  - server ↔ client.
  #extra[
    Less dominant in modern architectures.
  ]
]

=== Traditional 3-Tier Architecture
In _@dc-net-arc _, we see on the left the #kw[traditional architecture] of a data center network, with 3 layers:
- #kw[Core Layer]: high-capacity routers, connects DCs to internet/WAN (and other DCs).
- #kw[Aggregation Layer]: connect multiple rack by providing routing, security and load balancing.
- #kw[Access Layer]: Top-of-Rack (ToR) switches, connect directly to servers, handle local traffic inside the rack.

#table(
  align: (x,y) => {if y == 0 { center} else { left }},
  fill: (x,y) => {if y == 0 { if x == 0 { green.lighten(40%) } else { danger.lighten(15%) }} else { if calc.rem(y,2) == 0 { gray.lighten((70%)) } else { white }}},
  columns: (1fr, 1fr),
  stroke: 0.5pt,
  inset: 0.8em,
  [*_Pro_*], [*_Cons_*],
  [
    - Simple
    - Well-understood
  ], [

    - Inefficient for east-west traffic],

)

=== Modern Leaf-Spine Architecture

The right side of _@dc-net-arc _ shows the modern #kw[leaf-spine architecture], designed to #hl[optimize] #hl[east-west traffic], nowadays it is the *dominant model* for cloud and high-throughput workloads.

- #kw[Leaf Switches]: #hl[connect directly to servers] (like ToR), but also connect to #hl[multiple spine] switches, creating a full mesh.
- #kw[Spine Switches]: high-capacity switches that interconnect all leaf switches (innter-rack traffic).

#hl[Every server can reach every other server in exactly *2 hops*] (leaf #arrow spine #arrow leaf), giving:
- Predictable, *uniform latency*.
- *High* and *scalable bandwidth*.
- Better energy efficiency per bit.
- Ideal behavior for microservices and distributed systems.

#figure(
  crop(
    image("../assets/dc-net-layers.jpg", width: 80%),
    top: 0em,
  ),
  caption: "Data center network architecture layers."
)<dc-net-arc>

#note[
  Above the two architectures, there is the upper layer with the routers for the Internet and WAN connectivity.
  #extra[
    So, the switches and routers inside the two architectures handle intra-DC (east-west) traffic, while those other routers above are for north-south traffic.
  ]
]


In synthesis:
#table(
  align: (x,y) => {if y == 0 { center} else { left }},
  fill: (x,y) => {if y == 0 { if x == 0 { accent.lighten(80%) } else { accent.lighten(45%) }} else { if calc.rem(y,2) == 0 { gray.lighten((70%)) } else { white }}},
  columns: (1fr, 1fr),
  stroke: 0.5pt,
  inset: 0.8em,
  [*_3-Tier_*], [*_Leaf-Spine_*],
  [ #hl[*Tree* topology]],[ #hl[*Full Mesh*] topology],
  [Travel time variable],[Travel time fixed (2 hops)],
  [Non uniform latency],[Uniform latency],
  [Ideal for C/S (Nord-South)],[Ideal for Microservices and Distributed Systems (East-West) ],

)

#side-note(color: gray)[
  #v(0.5em)
  #extra[
    Analogy: *DC Networks*

    Think of the *3-Tier* architecture like a traditional city layout with suburbs and a single main highway: if two neighbors in different suburbs want to talk, they must both drive onto the congested main highway (Core layer) to reach each other.

    The *Leaf-Spine* architecture is like a perfect grid-city (like Manhattan): every street (leaf) intersects with every avenue (spine). To get anywhere, you only ever need to make exactly one turn (2 hops), and traffic is spread evenly across all avenues.
  ]
]

== Compute Architecture Inside a DC

#hl[Servers are grouped into #kw[clusters] based on *workload type*]:
- #kw[Compute] *clusters*: *general-purpose* servers with support for VMs, containers, microservices.
- #kw[Storage] *clusters*: SAN (block-based), NAS (file-based), distributed storage (Ceph, HDFS).
- #kw[GPU/AI] *clusters*: use high-bandwidth interconnects (such as _InfiniBand, NVLink, RDMA over Converged Ethernet_).
- #kw[Hyperconverged Infrastructure] (HCI): software-defined framework that unifies compute, storage, networking, and virtualization on commodity hardware into a single system. Think of it as collapsing the entire stack into one manageable unit.
#figure(
  image("../assets/hci.png", width: 50%),
  caption: "Hyperconverged infrastructure (HCI)"
)<hci>
Different cluster types have different communication patterns and energy profiles.
#side-note(color: gray)[
  #v(0.5em)
  #extra[
    Analogy: *HCI Analogy*

    Before HCI, building a DC was like buying a separate camera, a GPS navigator, an MP3 player, and a cell phone, and trying to wire them together. *HCI* is the "Smartphone" approach: compute, storage, and networking are all packaged into a single, standardized building block managed by one operating system. If you need more power, you just buy another smartphone (node) and add it to the cluster.
  ]
]

== Hyperscalers and Sustainability
 Hyperscalers (Google, Microsoft, AWS, Meta, IBM…) treat sustainability as a *full-stack engineering requirement*, redesigning every layer:

 #table(
  columns: (auto, auto),
  align: (x,y) => {if y == 0 { center} else { left }},
  fill: (x,y) => {if y == 0 { accent.lighten(45%) } else { if calc.rem(y,2) == 0 { gray.lighten((70%)) } else { white }}},
  stroke: 0.5pt,
  inset: 1em,
  table.header(
    [*Layer*], [*Hyperscaler Approach*],
  ),
  [Energy], [Power Purchase Agreements, on-site renewables, 24/7 carbon-free.],
  [Cooling], [Free cooling, liquid cooling, AI-driven thermal control.],
  [Hardware], [Custom servers, TPUs, efficient power supplies.],
  [Software], [Autoscaling, serverless, workload consolidation.],
  [Power distribution], [48V DC (vs traditional AC), rack-level batteries, fewer conversion steps.],
  [Location], [Climate-optimized siting, renewable-rich regions.],
  [Lifecycle], [Recycling, refurbishing, modular construction.],
)

== Large Cloud Ecosystem
Smaller/regional data centers and large hyperscale facilities working *together* form a *hybrid cloud ecosystem* that is more sustainable than either alone.

The principle:#hl[distribute locally when appropriate, optimize globally when beneficial.]

#table(
  columns: (auto, 1fr, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else { if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white } },
  stroke: 0.5pt,
  inset: 1em,

  [*Benefit*], [*Small DCs role*], [*Large DCs role*],
  [Latency], [Local processing of IoT, video, real-time analytics], [Global coordination],
  [Efficiency], [Offload heavy/batch tasks], [Run them at lower energy per operation],
  [Cooling], [Avoid thermal peaks], [Absorb load in cool regions],
  [Redundancy], [Less overprovisioning], [Provide pooled backup capacity],
  [Sustainability], [Reduce data movement], [Use renewables + AI optimization],
)

The full hierarchy spans from device-level edge (sensors, wearables) through fog computing and regional data centers up to hyperscale public cloud.

#figure(
  image("../assets/cloud-continuum.jpg", width: 80%),
  caption: "Large Cloud Ecosystem."
)

#example("Costs Comparison")[
  Large data centers have overwhelming cost advantages:
  #table(
    columns: (auto, 1fr, 1fr, auto),
    align: (x, y) => if y == 0 { center } else {
      if x == 0 { left } else { center }
    },
    fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
      if calc.rem(y, 2) == 0 { gray.lighten(83%) } else { white }
    },
    stroke: 0.5pt,
    inset: 1em,
    table.header(
      [*Technology*], [*Small DC (1K servers)*], [*Large DC (50K servers)*], [*Cloud Advantage*],
    ),
    [Network], [\$95/Mbps/month], [\$13/Mbps/month], [*7.1$times$*],
    [Storage], [\$2.20/GB/month], [\$0.40/GB/month], [*5.7$times$*],
    [Administration], [~140 servers/admin], [>1000 servers/admin], [*7.1$times$*],
  )

  This is why cloud is winning: the bigger the infrastructure, the *cheaper* each unit of service.
]

== Big Data
#example("Market Context")[

  The scale of investment confirms how central Big Data has become:

- *Digitalization* market: \$880B in 2023 → \$4.40T by 2030 (27.6% CAGR)
- *Big Data investments*: \$327B in 2023 → \$924B by 2030 (14.9% CAGR)
- *ICT industry* overall: \~\$6T in 2025 → \$7.86T by 2030
Drivers: mobile broadband, cloud services, social business, and analytics.
]

=== The 5 (or 6) Vs
Information systems need a quality-aware view of data across its full lifecycle. Big Data is characterized by:

#block(
  width: 100%,
  fill: luma(245),
  inset: 12pt,
  radius: 5pt,
  stroke: (left: 3pt + purple),
  [
    *5Vs for new data processing and novel data treatment:*
    - #kw[Volume] #swarrow Massive quantities of data (size).
    - #kw[Variety] #swarrow Many formats and structures.
    - #kw[Velocity] #swarrow Speed of ingestion and processing.
    - #kw[Value] #swarrow Extracted insight (relevance).
    - #kw[Veracity] #swarrow Trustworthiness (or reliability) of data.
  ]
)
#block(
  width: 100%,
  fill: luma(245),
  inset: 12pt,
  radius: 5pt,
  stroke: (left: 3pt + orange),
  [
    *6Vs also for Dynamicity:*
    - #kw[Variability] #swarrow Data dynamicity (meaning and structure change over time).
  ]
)

#figure(
  image("../assets/5vs.jpg", width: 60%),
  caption: "The 5 (or 6) Vs of Big Data."
)

== Application Scenarios

=== Smart Cities

Smart cities generate massive streams of heterogeneous data from diverse sensors (IoT). The smart city model is built on six dimensions: Smart Economy, Smart Mobility, Smart Governance, Smart Environment, Smart Living, Smart People.

From a systems perspective, a smart city involves:
- Groups of replicated and interacting components,
- Co-creation of content (videos, pictures),
- Collection and harvesting of big data and open data,
- Management of public services and logistics workflows.
Sensor sources include: building sensors, smart grid meters, pollution sensors, meteorological sensors, traffic cameras, medical sensors on ambulances, industrial automation sensors, and wearables.
#v(-1em)
#figure(
  crop(
    image("../assets/smart-city.png", width: 70%),
    top: 4em,
    bottom: 4em,
  ),
  caption: "Smart city data sources and applications."
)

=== Industry 4.0 and 5.0
*Industry 4.0* connects physical production with ICT: machines communicate with machines (M2M), customer data merges with machine data, and components autonomously manage production in a flexible, efficient way. Built on IoT, cloud platforms, big data, and wireless intelligence.

*Industry 5.0* (EU Commission, 2021) extends the focus beyond efficiency to societal goals:
- *Human-centric*: technology adapts to workers, not the other way around
- *Sustainable*: circular processes, reduced energy and waste
- *Resilient*: robust supply chains, adaptable production capacity, critical infrastructure that withstands crises

== Quality of Service

In distributed systems, correctly delivering a service is necessary but not sufficient. The critical goal is *QoS*.

#def("QoS")[
  #kw[QoS] consists in meeting parameters and requirements that reflect what users actually need.
]

QoS can include: response time, correctness, availability, confidence, security, user satisfaction.

=== Old World vs New World
#table(
  columns: (auto, 1fr, 1fr),
  align: (x, y) => if y == 0 { center } else {
    if x == 0 { center } else { left }
  },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header(
    [*_Metric_*], [*_Old World_*], [*_New World_*],
  ),
  [Priority], [Reliability, enforced consistency (*ACID*)], [#hl[*Scalability* and *availability*]],
  [Latency], [Acceptable delays.], [Milliseconds matter.],
)

=== Supporting QoS

- *Meaning*: data must be interpretable and understood everywhere.
- *Replication*: multiple copies of resources for fault tolerance.
- *Grouping*: coordinating replicas coherently.
- *Simplified delivery*: tools to accelerate development and deployment.
- *Automated management*: infrastructure that manages itself with minimal human intervention.
- *Batch data processing*: storing and processing massive amounts ofdata (e.g., Google Web indexing).
- *Streaming data*: handling continuous information series from sensors, video feeds, etc..
#v(-0.7em)
#note[
  QoS is a recurring theme throughout the course. Resource-level QoS management (SLA, allocation strategies, load balancing) is covered in the #link(<ch03-qos>)[_*Resource Management Models* chapter_]. Network-level QoS protocols (IntServ/RSVP, DiffServ, traffic shaping) are covered in the #link(<ch14-qos>)[_*QoS: Quality of Service* chapter_].
]

== Middleware
Complex, large-scale distributed applications cannot be built from scratch every time. The answer is *Middleware*.

#def("Middleware")[
  #kw[Middleware] is a set of pre-built *tools* and *components* that provide the best system performance under user-required conditions (data and processing).
]

#side-note(color: gray)[
  #v(0.5em)
  #extra[
    Analogy: *Middleware*

    Think of a restaurant. \
    The *User/App* is the customer sitting at the table. \
    The *Hardware/OS* is the kitchen staff and the raw ingredients. \
    The *Middleware* is the waiter and the ordering system: the customer doesn't need to speak the chef's language or know how the oven works, they just give the order to the waiter (the uniform interface), who translates it, routes it to the correct station, and brings the finished meal back.
  ]
]

Middleware can:
- Make *ready-to-use applications* available when a user needs new functions, with no user intervention required.
- *Simplify development* of new applications when needed functionality doesn't yet exist.
- *Adapt the system* across its lifecycle as requirements and conditions change.

=== Middleware Families
- #kw[Object middleware]: enable remote object interaction, examples are *CORBA*, COM, .NET.
- #kw[Message exchange middleware (MOM)]: asynchronous communication between components.
- #kw[Overlay networks], #kw[novel file systems], NoSQL support.
- #kw[Cloud middleware]: *OpenStack* and similar platforms for managing cloud resources.
- #kw[Big Data middleware]: for storing, processing, and streaming large datasets, such as *Hadoop*, *Spark*, *Kafka*, *Cassandra*, *MongoDB*.

=== Major Use Cases
*#kw[Private]/company middleware* supports an organization's internal users:
- Works on local data center servers.
- Accesses remote (cloud) resources when needed.
- Provides transparent services: replication, load balancing, naming.
- Provides non-transparent services: monitoring, decision systems.
- Manages computing, storage, and network resource delivery.
*#kw[Cloud] provider middleware* supports external customers at scale:
- Manages large pools of heterogeneous internal resources.
- Serves many customer organizations simultaneously under agreed contracts.
- Key functions: physical infrastructure management, resource isolation (security and performance), Customer Relationship Management (CRM).
- Must honor SLAs, coordinating with other providers if necessary.

== Cloud as an Evolution

Cloud is not a revolution, it is a necessary *evolutionary step*, building on decades of distributed systems experience. What changes is the *packaging*: web-accessible resources in remote data centers, offered as services with the following properties:

- *Ready-to-use*: no setup burden on the customer.
- *Easy*: low barrier to entry.
- *Pay-per-use*: cost tied to actual consumption.
- *Transparent* (or selectively non-transparent): complexity hidden behind clean interfaces.
- *Elastic*: resources scale up or down on demand.
- *Reliable*: high availability guaranteed by contract.
- *Secure*: isolation and access control enforced by the provider.

== Roadmap

The course covers distributed systems lifecycle operations, focusing on execution-time aspects:

- System management and QoS
- Observation and monitoring of all resources
- Replication and partitioning of localities and resources
- Dynamic resource variation during the lifecycle
- Recovery, tuning, and disaster recovery
- Sustainability and resilience
Middleware tools covered in practice: *CORBA, OpenStack, Hadoop, Spark, Kafka, Docker, Kubernetes, orchestrators*, and more.
