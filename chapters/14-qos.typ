#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= QOS: QUALITY OF SERVICE

#extra[
  Package: QoS basis and protocols — `9 - QoS 26.pdf`
]

Quality of Service (QoS) is the ability of a network or system to provide *differentiated, negotiated, and guaranteed levels of service* to applications. This chapter covers the fundamentals of QoS indicators, management models, protocols (IntServ, DiffServ, RSVP, RTP/RTCP, SIP), router scheduling policies, and congestion prevention.

// ─────────────────────────────────────────────────────────────
// PART 1: QoS FUNDAMENTALS
// ─────────────────────────────────────────────────────────────

== QoS in Different Environments

#prop("TCP/IP vs OSI")[
  - *TCP/IP*: communicates using resources available during execution (dynamic), without any predefined commitment. The IP level is responsible for *best-effort semantics* — no guarantees.
  - *OSI*: entities commit resources and can provide an SLA that must be respected from all parties in the path (including intermediate nodes).
  - *Challenge*: how to guarantee QoS in TCP/IP best-effort environments? Users increasingly require new Internet application services with real guarantees.
]

=== Application Classification

Applications are classified by their tolerance to QoS violations:

#prop("Elastic Applications")[
  Traditional applications — they do *not present quality constraints* but have requirements independent from delays:
  - Work better with low delays, worst during congestions.
  - Interactive apps require delays less than 200ms.
  - Examples: telnet, X-windows (interactive), FTP, HTTP (bulk interactive), e-mail, voice (asynchronous).
]

#prop("Non-Elastic — Real-Time Applications")[
  Have *constraints to be respected in time* — less tolerant:
  - Can *not work* outside their allowed admissibility space (failure).
  - The service can be *adaptive* in two ways:
    - *Delay adaptive* #arrow audio drops packets when delay is exceeded.
    - *Bandwidth adaptive* #arrow video adapts quality to available bandwidth.
  - Further split into *Tolerant* (adaptive to delay or bandwidth) and *Not tolerant* (not-adaptive).
]

== QoS Indicators

#def("QoS Indicators")[
  Many parameters and indicators qualify a *stream of information* and its functional properties. They are both *functional* (easily measurable) and *non-functional* (dependent on external factors, observable and judged by the final user only).
]

#prop("Key QoS Metrics")[
  - *Promptness in reply*: delay, response time, *jitter* (variation in deliver delay).
  - *Bandwidth (throughput)*: quantity of data transmitted by a channel with success per time unit (bit/byte per second). E.g., Ethernet: 10 Mbps.
  - *Throughput*: number of operations per second (transactions).
  - *Reliability*: percentage of successes/failures (MTBF — Mean Time Between Failures, MTTR — Mean Time To Repair).
]

=== Latency

#def("Latency Time (RTT)")[
  The time to send an information unit (bit), measured as the *Round Trip Time (RTT)*:
  $ T_L = T_"prop" + T_"tx" + T_q $
  - $T_"prop"$: depends on light *speed* inside the medium (Space / Speed).
  - $T_"tx"$: depends on *messages and bandwidths* (Dimension / Bandwidth).
  - $T_q$: depends on *queuing delays* in different intermediate points — the critical time because it involves all waiting overheads.
]

#important("Bandwidth-Delay Product")[
  A good service requires to identify bottlenecks and consider *resource management*:
  - Send/receive of 1 byte #arrow latency dominates RTT.
  - Send/receive of many megabytes #arrow bandwidth dominates.
  - *Resource data channel* = Latency × Bandwidth. E.g., 40ms latency, 10Mbps bandwidth #arrow product is 50 KB (400 Kb): the sender must send 50 KB before the first bit arrives, and 100 KB before any answer returns.
  - Infrastructures tend to keep *pipes full* to guarantee response time.
  - A *buffering time inside applications* is typically automatically considered.
]

=== Jitter and Skew

#def("Jitter")[
  #kw[Jitter] is defined as the *variance of latency* in a stream. Optimal situation: latency stable. High jitter breaks real-time playback.
]

#def("Skew")[
  #kw[Skew] is the possible *offset between multiple flows* composing a unique stream (e.g., audio and video flows of the same session). Skew must be minimized to maintain synchronization.
]

=== User-Level QoS Indicators

#def("QoE — Quality of Experience")[
  The typical non-functional properties requested by a final user:
  - *Relevance* (priority)
  - *QoS perceived* (details, accuracy, synchronization, audio/video quality)
  - *Cost* (per access, per service)
  - *Security* (integrity, confidentiality, authentication, non-repudiation)
]

#important("QoS Requires Negotiation")[
  QoS can be guaranteed only through a *negotiated and controlled contract and after provisioning*. The system must be observed during execution to adjust the service dynamically (obeying user requests). This requires *monitoring and feedback* loops. The *negotiated SLA must be verified during execution* to undertake quickly corrective actions.
]

// ─────────────────────────────────────────────────────────────
// PART 2: QoS MANAGEMENT
// ─────────────────────────────────────────────────────────────

== QoS Management

#def("QoS Management")[
  Good QoS management requires actions that must be *active for the whole service time*. Actions must be both *proactive* (before content distribution) and *reactive* (during deployment). Requires defining precise *Service Level Agreement (SLA)* models.
]

#prop("SLA Lifecycle (Static + Dynamic)")[
  *Static actions (before distribution):*
  1. *Requirement definition* — precise specification of QoS levels and allowed variations.
  2. *SLA definition* — the static agreement describing what is expected.
  3. *Negotiation* — agreement between all entities and levels interested in granting QoS.
  4. *Admission control* — comparison between requested QoS and offered resources.
  5. *Reservation and commitment* of required resources — needed resource definition for allocation.

  *Dynamic actions (during distribution):*
  1. *Monitoring* — continuous measurements of QoS levels and SLA parameters.
  2. *Respect control and synchronization* — verify fulfillment and potential need for synchronization of different resources (video/audio).
  3. *Renegotiation* of necessary resources — new contract to respect QoS and grant SLA.
  4. *Change of resources* to maintain QoS and adjustment to new situations.
  After renegotiation, the new SLA fulfillment must be ascertained and regularly checked.
]

#note[
  Local actions (reservations, conditioning) are not directly provided by the protocols — they must be implemented at lower levels. This is a fundamental limitation of IntServ.
]

=== Active Path

For streaming services, the management must find and maintain an *active path* between emitter and receiver:
- The best active path is found (even by flooding).
- Among several paths, one is *chosen as the active path*.
- The active path *must change during provisioning* in case of severe problems (failure recovery).

=== SLA Negotiation Example

The SLA specification is *always a coordinated effort among emitters and receivers*:
- Emitter: "I can send that specific streaming with bandwidth B and accuracy A."
- Receiver: "I can accept streaming with bandwidth B1 and accuracy A, latency L."
- *Agreement succeeds* when receivers accept a setting for their streaming.
- The final agreement can define a *private setting* for the entire routing.
- Some sharing of part of the active path can be convenient.
- Difficult cases: receiver coordinates more emitters (multiple emitters sharing a path).
- *Impossible agreement* #arrow look for other settings.

// ─────────────────────────────────────────────────────────────
// PART 3: VIDEO STREAMING
// ─────────────────────────────────────────────────────────────

== Video Streaming Services

Effective video streaming requires thinking about: actors (senders and receivers), streaming model, protocols, and strategies.

#prop("Streaming Topologies")[
  - *One-to-one*: one sender, one receiver, many intermediaries. Requires simple protocols and point-to-point strategies.
  - *Many-to-one*: many senders, one receiver, more intermediaries. Typical in CDN (Content Delivery Networks) with edge servers and media servers.
  - *Many-to-many*: many senders, many receivers, much more intermediaries. Requires multicast or overlay networks with distributors and relays.
]

=== Three Operational Planes

#def("Management and Monitoring Planes")[
  QoS management requires matching the application plane with efficiency control strategies:
  - *User Plane*: for defining user protocols (e.g., voice in telephony).
  - *Management Plane*: for service management and monitoring (e.g., QoS handling in telephony).
  - *Control Plane / Signaling*: to establish connections, negotiate and signal between levels — *not necessarily in-band* (in telco, this level establishes the call before it starts).
]

=== RTSP — Real-Time Streaming Protocol

#def("RTSP (RFC 2326)")[
  #kw[RTSP] integrates web-based streaming transported to a final client (e.g., RealPlayer). Starts *after downloading the file specification from the server*.
]

#prop("RTSP Operation")[
  - Player communicates with the server via UDP or TCP, trying to obtain better provisioning.
  - Exploits a *local receiver buffer strategy*: receiver does not wait for the entire file.
  - UDP: wait 2-5 seconds before starting to show; TCP: a larger buffer is used.
  - *Pull and push policies* on the server with *watermark techniques* to synchronize: if below threshold, starts pulling requests.
  - *Interleaving* used to deal with packet loss.
]

// ─────────────────────────────────────────────────────────────
// PART 4: INTSERV — INTEGRATED SERVICES
// ─────────────────────────────────────────────────────────────

== IntServ — Integrated Services (RFC 2210)

#def("IntServ")[
  #kw[Integrated Services (IntServ)] works at the *application level* at a *single flow level*. The goal is to produce one *active path* connecting sender and receiver for the whole flow. Must work during both static and dynamic phases to grant QoS. Requires coordination of protocols in the suite to not disturb the QoE of the final user.
]

#important("IntServ Principle")[
  For every flow, IntServ considers not only the endpoints but the *whole path*: works *hop-by-hop*, involving all intermediate nodes in the active path. The service is enabled by one active initiator (receiver/client), one service provider, and many intermediate nodes connected in the active path. Local actions that grant SLA respect must be obtained at *lower network levels* (not at protocol control level).
]

The IntServ suite has three protocols:
- *RSVP* (out-of-band, static): resource reservation setup.
- *RTP* (in-band): real-time data transport.
- *RTCP* (in-band): flow control and QoS monitoring.

=== RSVP — Resource Reservation Setup Protocol (RFC 2205)

#def("RSVP")[
  #kw[RSVP] (Resource ReSerVation Protocol) specifies how to communicate between neighbor nodes to enable the *reservation of needed resources* to guarantee an agreed SLA, in a completely separate way from current Internet traffic.
  RSVP is a *static (out-of-band) two-phase protocol* with *soft-state*, where the receiver requests to enable resource reservation for the whole service duration.
]

#prop("RSVP Two-Phase Protocol")[
  - *Phase 1 — Path (sender to receivers)*: provider propagates announce messages (`Path`) with offers toward potential receivers. Identifies the active path.
  - *Phase 2 — Resv (receivers to sender)*: receivers propagate inversely their intention of creating an active path, requiring reservations (`Resv` with TSpec + optional RSpec).
  - *Soft-state*: the admitted state is maintained for a limited time and must be refreshed. Paths and resources are reserved locally either in a private or shared way.
  - *Teardown*: `PathTear` from sender or `ResvTear` from receiver, or timeout.
]

#prop("RSVP Key Properties")[
  - Oriented to *receiver initiative* (receivers request resource reservation).
  - Produces *state on every node* of the path established from sender to receiver (during phase 2).
  - Allows *sharing of active paths* (shared reservations for multicast groups).
  - Compatible with any routing protocol (unicast or multicast, IPv4 and IPv6).
  - *Not a routing protocol* — works before provisioning, impacts less on execution.
  - One reservation can block another, producing a `ResvErr`.
  - Recommended only for *limited local networks*, not global environments (legacy application compatibility issues).
]

#prop("RSVP Summary")[
  - Single-hop protocol inside IntServ (from one node to one potential neighbor).
  - Objective: signal information to reserve necessary resources.
  - Defines a non-permanent (soft) state of the active path.
  - Can work with any routing protocol (unicast or multicast).
  - In case of router failure, QoS can downgrade to best-effort #so renegotiation is needed during provisioning.
]

=== RTP — Real-Time Transport Protocol (RFC 1889)

#def("RTP")[
  #kw[RTP] provides *general operational messages* for in-band flow management. Frames are sent with *progressive numbers* and *timestamps* associated with the data flow. Works at UDP even ports.
]

#prop("RTP Features")[
  - Every packet (flow frame) identified with *progressive number tags* — identifiable by router classifiers.
  - Provides precise indications on *transit time* in any path hop.
  - In case of missing packets: suggestion is to *not retransmit, but to interpolate* previous packets.
  - *Intermediate nodes* (mixers, translators) can insert information (timestamps) to add data toward SLA monitoring.
  - Active path becomes a set of *sources for every node*:
    - *SSRC* (Synchronization Source): primary source.
    - *CSRC* (Contributing Source): contributing sources when mixed by an intermediate node (mixer).
  - Supports *shared paths* producing complex graphs with nodes belonging to more paths (mixers).
]

=== RTCP — Real-Time Transport Control Protocol

#def("RTCP")[
  #kw[RTCP] is the *bidirectional control companion* to RTP. Provides global and concise information of flow control at the application level, propagating knowledge about the current situation so anyone can intervene. Travels in *both directions* and uses the *same resources as RTP* (in-band, competing with application). Limited to *5-10% of RTP bandwidth*.
]

#prop("RTCP Message Types")[
  - *RR/SR* (Receiver/Sender Report): QoS per flow — loss, delays, jitter, end system info, application specification.
  - *SDES* (Source DEScription): ASCII strings — CNAME (canonical identifier, mandatory), NAME, EMAIL, PHONE, LOC, TOOL, NOTE, PRIV.
  - *BYE*: specifies abandoning of an RTP session.
  - *APP*: application-specific packets.
]

#extra[
  *IntServ flow summary*: RSVP prepares the path and enables resource reservations (static phase). In provisioning, frames are associated with RTP and RTCP. In case of problems, a new path negotiation can occur locally (via RSVP).
]

// ─────────────────────────────────────────────────────────────
// PART 5: DIFFSERV — DIFFERENTIATED SERVICES
// ─────────────────────────────────────────────────────────────

== DiffServ — Differentiated Services (RFC 2474/2475)

#def("DiffServ")[
  #kw[DiffServ] differentiates flows in *classes* handled together — greater scalability than IntServ by supporting *low-level differentiation* (work at network layer, not application layer). Do not work for each information flow separately, but *aggregate network-level classes of flows*. Suitable for legacy applications (less user involvement than IntServ).
]

#prop("DiffServ Classes")[
  Example class structure:
  - *Gold*: 70% bandwidth
  - *Silver*: 20% bandwidth
  - *Bronze*: 10% bandwidth
  Or alternatively:
  - *Premium*: low delay
  - *Assured*: high speed, low packet loss
]

#prop("DiffServ Mechanism")[
  - Classification when packet *enters* based on packet content.
  - *SLA* based on classification — policy arranged between user and server.
  - A flow is classified at input and inserted in the right queue (*Per-Hop Behavior*, PHB); subsequent support is automatic.
  - Packet marking inside *DS byte* (Differentiated Service):
    - IPv4 ToS byte
    - IPv6 traffic-class byte
  - *Traffic classifiers*: Multi-Field (MF — DS byte + other fields) or Behavior Aggregation (BA — only DS byte).
]

#prop("DiffServ Service Classes (RFC 3246, RFC 2579)")[
  - *Expedited Forwarding (EF)*: routers keep at least two differentiated queues, guarantee delivery of expedited packets in every hop (PHB: low loss, low delay, low jitter). Creates point-to-point connection like a shared line between endpoints.
  - *Assured Forwarding (AF)*: four priority classes with three service levels in case of congestion (low, medium, high). Different packets labeled and processed with differentiated strategies.
]

=== QoS Traffic Conditioning

#prop("Traffic Conditioning Components")[
  - *Packet Classifier*: identifies flows and assigns to appropriate class.
  - *Meter*: measures traffic profile (in-profile vs out-of-profile).
  - *Marker*: re-marks packets with new DS codepoint (reconditioning).
  - *Dropper*: discards out-of-profile packets.
  - *Shaper*: delays out-of-profile packets to smooth bursts.
]

=== IntServ + DiffServ Together

Both approaches cooperate. DiffServ is more scalable and supports legacy services; IntServ can grant specific QoS to specific flows. Often joined in connected areas: *IntServ* used in smaller, controlled domains; *DiffServ* in the wider Internet between domains.

// ─────────────────────────────────────────────────────────────
// PART 6: SIP — SESSION INITIATION PROTOCOL
// ─────────────────────────────────────────────────────────────

== SIP — Session Initiation Protocol (RFC 2543/3261)

#def("SIP")[
  #kw[SIP] defines and manages sessions to support multimedia services. Has signaling capability for *establishing, modifying, and closing* multimedia sessions. Based on HTTP-compatible content — a *text-based, purely client/server* protocol. SIP itself does not carry media — other protocols (RTP) do.
]

#prop("SIP Entities")[
  - *User Agent*: endpoints — act as User Agent Client (REQUEST) or Server (RESPONSE).
  - *Proxy Server*: application-level routers, can keep session transaction state (stateful) or be stateless.
  - *Redirect Server*: sends a client to a new alternative server.
  - *Registrar Service*: user registration to infrastructure.
  - *Location Service*: links interested users to their location.
]

#prop("SIP Messages")[
  REQUEST messages: `INVITE`, `ACK`, `CANCEL`, `BYE`, `REGISTER`, `OPTIONS`, `PRACK`, `SUBSCRIBE`, `NOTIFY`, `PUBLISH`, `INFO`, `REFER`, `MESSAGE`, `UPDATE`.

  RESPONSE messages:
  - `1xx`: Provisional
  - `2xx`: Success
  - `3xx`: Redirection
  - `4xx-6xx`: Failure
]

#extra[
  SIP message structure: start-line (request-line or status-line), headers, optional message body. The body can contain *SDP* (Session Description Protocol) for audio/video format negotiation.
]

// ─────────────────────────────────────────────────────────────
// PART 7: NETWORK MANAGEMENT
// ─────────────────────────────────────────────────────────────

== Network Management

#important("Minimum Intrusion Principle")[
  We need dynamic data collection mechanisms and policies that do *not require too many resources* (also used by application execution). Any correct management must reserve as few resources as possible. Performance area (monitor and data management) must define tools and policies that are *the least intrusive as possible*.
]

Management functional areas (FCAPS):
- *Fault Management*
- *Configuration Management*
- *Accounting Management*
- *Performance Management*
- *Security Management*

Standards: OSI/ISO (CMIB, CMISE), SNMP/IETF, TINA/CCITT.

=== SNMP — Simple Network Management Protocol

#def("SNMP")[
  #kw[SNMP] uses one *manager* (only one) and some predefined *agents* that control variables representing objects, identified by unique names (*OID* in hierarchical directories). Manager requests actions (`get`, `set`, `getNext`) and receives responses. Agents wait for requests and can also send *traps*. Uses UDP (Port 161 for messages, Port 162 for traps).
]

#prop("SNMP Standards")[
  - *SMI* (Structure of Management Information): defines rules for object names (ASN.1 and BER).
  - *MIB* (Management Information Base): objects, types, and relationship collections (according to OSI X.500).
]

#prop("SNMP Versions")[
  - *SNMPv1*: extremely simple, limited expressivity, only configuration/fault management, limited traps.
  - *SNMPv2*: overcomes C/S manager-agent hierarchy with *proxy agents* (act as both agent and manager), solving the *micro-management* congestion problem. Manager orders operations; proxies actuate them locally and send aggregated results.
  - *SNMPv3*: adds security (S-SNMP) — integrity, masquerading prevention, privacy (prevent disclosure). Denial of service and traffic analysis not dealt with.
]

#note[
  SNMP embeds CMIP and CMISE properties with a predetermined vision — very little capacity for dynamically varying during runtime.
]

=== RMON — Remote Monitor

#def("RMON")[
  #kw[RMON] controls the support parts of the communication and allows access to related statistics — oriented toward *traffic and bandwidth*, not toward devices. Introduces *probe* entities capable of monitoring packets on the network autonomously (even disconnected from the manager), tracking subsystems and reporting filtered information to the manager.
  - RMON1: multiple and grafted operations.
  - RMON2: guaranteed security.
]

=== OSI Advanced Network Management

OSI Management provides a more sophisticated model with three roles:
- *Manager*: active entity issuing management policies.
- *Agents*: intermediate entities acting on manager requests (can themselves be managers — flexible hierarchy).
- *Managed Objects*: abstract representations of resources (simple or complex, created dynamically).

Protocol *CMISE/P* provides remote operations: `Set-Modify`, `Get/Cancel Get`, `Action`, `Create/Delete`, `Event Report`. Supports *dynamic addition* of attributes, actions, agents, and events during execution (also deletion).

// ─────────────────────────────────────────────────────────────
// PART 8: ROUTER QoS POLICIES
// ─────────────────────────────────────────────────────────────

== Router QoS Policies

=== Best-Effort Router (FIFO)

The standard Internet router (best-effort) executes for every packet:
1. Verification of the destination.
2. Access to routing tables to find output path.
3. Select the best output path (maximum match length).
4. Forward the packet to the selected interface.

*Simple FIFO policy*: unique queue for every flow — excludes any service differentiation. Cannot reserve resources for flows with different SLAs.

=== Kleinrock Conservation Law

#def("Kleinrock Conservation Law")[
  For *work-conservative routers* (cannot be idle if there are packets on any port — cannot postpone arriving messages): given n flows, if flow n has service mean time $mu_n$, usage $rho_n = lambda_n / mu_n$, and mean waiting time $q_n$:
  $ sum_n rho_n q_n = "Constant" $
  #so to give a lower delay or higher bandwidth to one flow, you *must* increase the delay or reduce the bandwidth of another.
]

#important("Work Conservation")[
  A router in Internet *must* work according to work conservation: it cannot decide to postpone any message arriving. Any QoS router must break this by *conditioning traffic* — introducing monitoring and making actions to decide more sophisticated service policies (delay some packets, discard some packets).
]

=== Bucket Models for Traffic Shaping

#def("Leaky Bucket")[
  #kw[Leaky Bucket]: the router has limited memory (capacity C) and limited output flow (R). Models a router *actively shaping* services by limiting output flows:
  - If data arrive too quickly beyond admissible output flow R: *delayed*.
  - If data arrive beyond capacity C: *lost*.
  Aims at *switching off packet bursts* — smooths traffic to an admissible level.
]

#def("Token Bucket")[
  #kw[Token Bucket]: tokens are generated uniformly by time ticking (r tokens/sec, capacity C). Each packet needs a token to pass:
  - If bucket empty: packet waits.
  - If bucket full: tokens available for packets.
  - Unlike leaky bucket: data beyond capacity are *not lost but only delayed*.
  - Allows *packet bursts* — if tokens have accumulated, a burst can pass immediately.
  Models flows *history* via tokens as authorization for passing.
]

#analogy("Leaky vs Token Bucket")[
  Leaky bucket: a bucket with a hole — water (packets) drips out at a constant rate regardless of input. If too much comes in, it overflows (drops). Token bucket: a ticket machine — you need a ticket (token) to send a packet. Tokens accumulate when traffic is low, allowing bursts when traffic spikes.
]

#note[
  Often leaky bucket and token bucket are used in *serial chain*. The token bucket allows bursts; the leaky bucket smooths the output.
]

=== Scheduling Policies

#prop("Properties Required of Scheduling Policies")[
  - *Implementation facility*: easy router design toward real feasibility.
  - *Fairness and Protection*: any flow penalized same as others in same operational situation.
  - *Performance limits*: constraints on correct flow operation.
  - *Admission Control*: decision on admission before distribution.
]

==== Max-Min Fairness and GPS

#def("Max-Min Fairness")[
  General strategy: requests of different resources by different flows considered *in order of growing request* (first the ones that require less). Allocates to flow n: $m_n = min(X_n, M_n)$ where $M_n = (C - sum_{i=1}^{n-1} m_i) / (N - n + 1)$. Scaling down done only in lack of resources.
]

#def("GPS — Generalized Processor Scheduling")[
  *Fluid traffic model*: answers service requests one at a time in a very fair Round Robin order — serves only *one bit per flow* per round. Theoretically optimal for service scheduling, but *not implementable* in reality (can only serve packets, not bits). All practical policies are approximations of GPS.
]

==== Round Robin Variants

#prop("Round Robin Policies")[
  - *Round Robin (RR)*: flows served cyclically, one packet per flow per round. Fair but does not consider packet size or flow demands.
  - *Weighted Round Robin (WRR)*: flows served by round-robin in proportion to assigned weight. Every queue visited a number of times per round equal to the weight.
  - *Deficit Round Robin (DRR)*: each flow has a deficit counter. Packet extracted if less than threshold length; otherwise waits a number of rounds proportional to its length (augmenting deficit by a specific amount per visit). Works well with limited flows and small packets on average.
]

==== Fair Queuing

#def("Fair Queuing")[
  Based on GPS principle applied per-packet: messages assigned *tags* for message end in every queue. Packet selected for output is the one that would *complete service first* (if it were per-bit service). A packet of size N in a flow can output only after visiting all other queues N times.
  - More suitable and simple to implement — available on all routers including low-cost.
  - *Weighted Fair Queuing (WFQ)*: different weights associated to different flows.
]

=== Congestion Prevention

#def("RED — Random Early Detection")[
  #kw[RED] is a *proactive* congestion prevention policy: a queue for every flow, queues with equal priority. Randomly discards packets *before* congestion occurs, based on queue length:
  - Queue < minimum threshold: no action.
  - Queue > maximum threshold: all new packets discarded.
  - Otherwise: discard with *probability proportional to queue length*.
  Success: packets are randomly discarded more and more as queues grow — preventing congestion before it becomes severe.
]

#important("Reactive vs Proactive")[
  Traditional best-effort Internet only allows *reactive* actions: discard excess packets (silently) or send choke packets. QoS-aware Internet enables *preventive (proactive)* actions such as RED, transmission windows on channels, or other strategies that prevent dangerous congestion situations.
]

=== Service Levels Summary

| Service Level | Characteristics | Use Cases |
|---|---|---|
| *Best-effort* | No guaranteed throughput, possible delays, no duplication control | Elastic Internet services |
| *Controlled load* | Similar to best-effort with low load, some delay limits | Elastic services, tolerant real-time |
| *Guaranteed load* | Tight delay limits, maximum guarantees on flows | Non-tolerant real-time services |
