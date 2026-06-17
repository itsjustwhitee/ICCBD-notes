#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= QOS: QUALITY OF SERVICE <ch14-qos>

#extra[
  Package: QoS basis and protocols - `9 - QoS 26.pdf`
]

Quality of Service #hl[(QoS) is the ability of a network or system to provide *differentiated*, *negotiated*,] #hl[and *guaranteed levels of service*] to applications. This chapter covers the fundamentals of QoS indicators, management models, protocols (IntServ, DiffServ, RSVP, RTP/RTCP, SIP), router scheduling policies, and congestion prevention.

// ─────────────────────────────────────────────────────────────
// PART 1: QoS FUNDAMENTALS
// ─────────────────────────────────────────────────────────────

== QoS in Different Environments

#example("TCP/IP vs OSI")[
  The key difference is *whether resources are reserved before data is sent* - which is exactly what decides if QoS can be guaranteed:
  - #hl(color: gray.lighten(70%))[*TCP/IP* (*best-effort*)]: *nothing is reserved in advance*. Each packet is forwarded using whatever capacity happens to be free at each hop, with no commitment. So the IP layer gives *no guarantee* on delay, bandwidth, or loss, it just "does its best".
  - #hl(color: gray.lighten(70%))[*OSI* (*connection-oriented*)]: *every node along the path reserves the resources* it will need before data flows. This up-front commitment is what lets the network honor a *negotiated SLA end-to-end*, intermediate nodes included.
  - *The challenge*: modern applications (streaming, VoIP, real-time) need *real guarantees*, yet the Internet runs on best-effort TCP/IP #swarrow the rest of this chapter is about *how to add QoS on top of a best-effort network* (IntServ, DiffServ, RSVP, ...).
]

=== Application Classification

Applications are classified by their tolerance to QoS violations:

#prop("Elastic Applications")[
  #kw[Elastic applications] are the traditional: they do *not present quality constraints* but have requirements independent from delays:
  - Work better with low delays, worst during congestions.
  - Interactive apps require delays less than 200ms.
  - #extra[Examples: telnet, X-windows (interactive), FTP, HTTP (bulk interactive), e-mail, voice (asynchronous).]
]

#prop("Non-Elastic: Real-Time Applications")[
  Have *constraints to be respected in time*, less tolerant:
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
#v(-1em)
#prop("Key QoS Metrics")[
  - *Promptness in reply*: delay, response time, *jitter* (variation in deliver delay).
  - *Bandwidth (throughput)*: quantity of data transmitted by a channel with success per time unit (bit/byte per second).
  - *Throughput*: number of operations per second (transactions).
  - *Reliability*: percentage of successes/failures (MTBF: Mean Time Between Failures, MTTR: Mean Time To Repair).
]

=== Latency

#def("Latency Time (RTT)")[
  *Latency* is the delay for data to travel from sender to receiver. Measured there and back, it is the *Round Trip Time (RTT)*. It is the sum of three delays:
  $ T_L = T_"prop" + T_"tx" + T_q $
  - $T_"prop"$ (*propagation*): time for a bit to physically cross the distance, $= "distance" \/ "speed"$ (the signal moves near the speed of light in the medium). It depends on *how far* the nodes are, not on how much data is sent.
  - $T_"tx"$ (*transmission*): time to push all the bits of the message onto the link, $= "message size" \/ "bandwidth"$. It depends on *how much data* there is and on the link speed.
  - $T_q$ (*queuing*): time the data waits in buffers at intermediate nodes. This is the *most variable* part, since it grows with congestion, and usually the hardest to predict and control.
]
#v(-1em)
#important("Bandwidth-Delay Product")[
  A good service requires to identify bottlenecks and consider *resource management*:
  - Send/receive of 1 byte #arrow latency dominates RTT.
  - Send/receive of many megabytes #arrow bandwidth dominates.
  - *Resource data channel* = Latency × Bandwidth. 
    #extra[
      With *40 ms one-way latency* and *10 Mbps bandwidth*: \
      *One way* #arrow 10 Mbps × 40 ms = 10 000 000 bps × 0.04 s = 400 Kb = *50 KB*. By the time the first bit reaches the receiver, the sender has already put 50 KB onto the wire (the data "in flight"). \
      *Round trip* (80 ms) #arrow 10 Mbps × 80 ms = 800 Kb = *100 KB*. So the sender can push 100 KB before any reply can come back, and it should keep about that much unacknowledged data in flight to keep the link busy.
    ]
  - Infrastructures tend to keep *pipes full* to guarantee response time.
  - A *buffering time inside applications* is typically automatically considered.
]

=== Jitter and Skew

#def("Jitter")[
  #kw[Jitter] is defined as the *variance of latency* in a stream.\
  Optimal situation: latency stable. #so High jitter breaks real-time playback.
]
#v(-1em)
#figure(
  image("../assets/jitter.jpg", width: 55%),
  caption: [Jitter graphical representation.]
)

#def("Skew")[
  #kw[Skew] is the possible *offset between multiple flows* (types) composing a unique stream (_e.g., audio and video flows of the same session_). Skew must be minimized to maintain synchronization.
]
#v(-1em)
#note[
  *Skew vs Jitter:*
    - Skew is the *spatial/cross-flow* delta: $T_"audio" - T_"video"$ 
      at a given frame (e.g., lip-sync errors).
    - Jitter is the *temporal/intra-flow* delta: the packet-to-packet arrival time 
      variance within a single flow over time ($T_(i+1) - T_i$).
]

=== User-Level QoS Indicators

#def("QoE: Quality of Experience")[
  The typical non-functional properties requested by a final user:
  - *Relevance* (priority)
  - *QoS perceived* (details, accuracy, synchronization, audio/video quality)
  - *Cost* (per access, per service)
  - *Security* (integrity, confidentiality, authentication, non-repudiation)
]
#v(-1em)
#important("QoS Requires Negotiation")[
  QoS can be guaranteed only through a *negotiated *and* controlled contract and after provisioning*. The system must be observed during execution to adjust the service dynamically (obeying user requests). This requires *monitoring and feedback* loops. The *negotiated SLA must be verified during execution* to undertake quickly corrective actions.
]

// ─────────────────────────────────────────────────────────────
// PART 2: QoS MANAGEMENT
// ─────────────────────────────────────────────────────────────

== QoS Management

#def("QoS Management")[
  Good QoS management requires actions that must be *active for the whole service time*. Actions must be both *proactive* (before content distribution) and *reactive* (during deployment). Requires defining precise *Service Level Agreement (SLA)* models.
]
#v(-1em)
#prop("SLA Lifecycle (Static + Dynamic)")[
  *Static actions (before distribution):*
  1. *Requirement definition*: precise specification of QoS levels and allowed variations.
  2. *SLA definition*: the static agreement describing what is expected.
  3. *Negotiation*: agreement between all entities and levels interested in granting QoS.
  4. *Admission control*: comparison between requested QoS and offered resources.
  5. *Reservation and commitment* of required resources: needed resource definition for allocation.

  *Dynamic actions (during distribution):*
  1. *Monitoring*: continuous measurements of QoS levels and SLA parameters.
  2. *Respect control and synchronization*: verify fulfillment and potential need for synchronization of different resources (video/audio).
  3. *Renegotiation* of necessary resources: new contract to respect QoS and grant SLA.
  4. *Change of resources* to maintain QoS and adjustment to new situations.
  After renegotiation, the new SLA fulfillment must be ascertained and regularly checked.
]
#v(-1em)
#note[
  Local actions (reservations, conditioning) are not directly provided by the protocols: they must be implemented at lower levels. This is a fundamental limitation of IntServ.
]

=== Active Path

For #hl[streaming services, the management must find and maintain an *active path*] between emitter and receiver:
- The best active path is found (even by flooding).
- Among several paths, one is *chosen as the active path*.
- The active path *must change during provisioning* in case of severe problems (failure recovery).

=== SLA Negotiation Example

#example("Example: SLA Negotiation")[
  The SLA specification is *always a coordinated effort among emitters and receivers*:
  - Emitter: _"I can send that specific streaming with bandwidth B and accuracy A."_
  - Receiver: _"I can accept streaming with bandwidth B1 and accuracy A, latency L."_
  - *Agreement succeeds* when receivers accept a setting for their streaming.
  - The final agreement can define a *private setting* for the entire routing.
  - Some sharing of part of the active path can be convenient.
  - Difficult cases: receiver coordinates more emitters (multiple emitters sharing a path).
  - *Impossible agreement* #arrow look for other settings.
]

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
#figure(
  grid(
    align: center+horizon,
    stroke: 0pt,
    gutter: 1em, 
    columns: (1.2fr,2fr,2.2fr),
    image("../assets/streaming-one-to-one.jpg"),
    image("../assets/streaming-many-to-one.jpg"),
    image("../assets/streaming-many-to-many.jpg")
  ),
  caption: [Streaming topologies: one-to-one (left), many-to-one (center), many-to-many (right).]
)

=== Three Operational Planes

#important("Management and Monitoring Planes")[
  QoS management requires matching the application plane with efficiency control strategies:
  - *User Plane*: for defining user protocols (e.g., voice in telephony).
  - *Management Plane*: for service management and monitoring (e.g., QoS handling in telephony).
  - *Control Plane / Signaling*: to establish connections, negotiate and signal between levels (*not necessarily in-band*, in telco this level establishes the call before it starts).
]

=== RTSP: Real-Time Streaming Protocol

#def("RTSP (RFC 2326)")[
  #kw[RTSP] integrates web-based streaming transported to a final client. Starts *after downloading the file specification from the server*.
]
#v(-1em)
#prop("RTSP Operation")[
  - Player communicates with the server via UDP or TCP, trying to obtain better provisioning.
  - Exploits a *local receiver buffer strategy*: receiver does not wait for the entire file.
    - UDP: wait 2-5 seconds before starting to show
    - TCP: a larger buffer is used.
  - *Pull and push policies* on the server with *watermark techniques* to synchronize: if below threshold, starts pulling requests.
  - *Interleaving* used to deal with packet loss.
]

// ─────────────────────────────────────────────────────────────
// PART 4: INTSERV - INTEGRATED SERVICES
// ─────────────────────────────────────────────────────────────

== IntServ: Integrated Services (RFC 2210)

#def("IntServ")[
  #kw[Integrated Services (IntServ)] works at the *application level* at a *single flow level*. The goal is to produce one *active path* connecting sender and receiver for the whole flow. Must work during both static and dynamic phases to grant QoS. Requires coordination of protocols in the suite to not disturb the QoE of the final user.
]
#v(-1em)
#important("IntServ Principle")[
  For every flow, IntServ considers not only the endpoints but the *whole path*: works *hop-by-hop*, involving all intermediate nodes in the active path. The service is enabled by one active initiator (receiver/client), one service provider, and many intermediate nodes connected in the active path. Local actions that grant SLA respect must be obtained at *lower network levels* (not at protocol control level).
]

The IntServ suite has three protocols:
- *RSVP* (out-of-band, static): resource reservation setup.
- *RTP* (in-band): real-time data transport.
- *RTCP* (in-band): flow control and QoS monitoring.

#figure(
  image("../assets/intserv-control-planes.jpg", width: 40%),
  caption: [Contron planes in IntServ.]
)

=== RSVP: Resource Reservation Setup Protocol (RFC 2205)

#def("RSVP")[
  #kw[RSVP] (Resource ReSerVation Protocol) specifies how to communicate between neighbor nodes to enable the *reservation of needed resources* to guarantee an agreed SLA, in a completely separate way from current Internet traffic.
  RSVP is a *static (out-of-band) two-phase protocol* with *soft-state*, where the receiver requests to enable resource reservation for the whole service duration.

  - *Phase 1 - Path (sender to receivers)*: provider (sender) propagates announce messages (`Path`) with offers toward potential receivers. Identifies the active path.
  - *Phase 2 - Resv (receivers to sender)*: receivers propagate inversely their intention of creating an active path, requiring reservations (`Resv` with TSpec + optional RSpec).
  - *Soft-state*: the admitted state is maintained for a limited time and must be refreshed. Paths and resources are reserved locally either in a private or shared way.
  - *Teardown*: `PathTear` from sender or `ResvTear` from receiver, or timeout.
]
#v(-1em)
#note[
  The `Path` message is not routed by the sender, so it use this message to discover the route in order to reserve resources (with `Resv`).  
]
#v(-1em)
#prop("RSVP Key Properties")[
  - Oriented to #hl[*receiver initiative*] (receivers request resource reservation).
  - Produces *state on every node* of the path established from sender to receiver (during phase 2).
  - Allows *sharing of active paths* (shared reservations for multicast groups).
  - Compatible with any routing protocol (unicast or multicast, IPv4 and IPv6).
  - *Not a routing protocol*: works before provisioning, impacts less on execution.
  - One reservation can block another, producing a `ResvErr`.
  - Recommended only for *limited local networks*, not global environments (legacy application compatibility issues).
  - On router failure, QoS falls back to best-effort; RSVP must renegotiate the path reservation during provisioning.
]
#figure(
  image("../assets/rsvp.jpg", width: 40%),
  caption: [RSVP `Path` and `Resv` flow.]
)

=== RTP: Real-Time Transport Protocol (RFC 1889)

#def("RTP")[
  #kw[RTP] is the protocol that *carries the real-time media stream itself* (audio, video) from sender to receiver, *in-band* with the data. It runs over *UDP*, so there is no retransmission, which fits real-time traffic where a late packet is useless.

  Every RTP packet carries two key fields:
  - a *sequence number*, so the receiver can put packets back in *order* and *detect losses*.
  - a *timestamp*, so the receiver can play the media at the *right time*, smooth out *jitter*, and keep flows *synchronized* (e.g. audio with video).

  RTP uses an *even UDP port*, and its control companion *RTCP* uses the *next odd port*. By itself RTP gives *no delivery or QoS guarantee*, it only gives the receiver what it needs to cope with loss and jitter.
]
#v(-1em)
#prop("RTP Features")[
  - The *sequence number* lets the receiver reorder packets and notice gaps (lost packets).
  - The *timestamp* lets the receiver reconstruct timing, measure *jitter*, and align playback.
  - On a lost packet the receiver does *not retransmit but interpolates* from earlier packets, since a resent packet would arrive too late to use.
  - *Intermediate nodes* can process the stream:
    - a *mixer* combines several incoming streams into one and can add timestamps useful for monitoring.
    - a *translator* forwards or transcodes one stream without merging it.
  - Each source is tagged, so one path can carry *several sources*:
    - *SSRC* (Synchronization Source): the identifier of a single stream source.
    - *CSRC* (Contributing Source): the list of original sources that a *mixer* combined into one stream.
]
#figure(
  image("../assets/rtp.jpg", width: 70%),
  caption: [RTP packet and flow scheme.]
)

=== RTCP: Real-Time Transport Control Protocol

#def("RTCP")[
  #kw[RTCP] is the *bidirectional control companion* to RTP. Provides global and concise information of flow control at the application level, propagating knowledge about the current situation so anyone can intervene. Travels in *both directions* and uses the *same resources as RTP* (in-band, competing with application). Limited to *5-10% of RTP bandwidth*.
]
#v(-1em)
#prop("RTCP Message Types")[
  - *RR/SR* (Receiver/Sender Report): QoS per flow #swarrow loss, delays, jitter, end system info, application specification.
  - *SDES* (Source DEScription): ASCII strings #swarrow CNAME (canonical identifier, mandatory), NAME, EMAIL, PHONE, LOC, TOOL, NOTE, PRIV.
  - *BYE*: specifies abandoning of an RTP session.
  - *APP*: application-specific packets.
]

#figure(
  image("../assets/rtcp.jpg", width: 50%),
  caption: [RTCP messages of RR (right) and SR (left) type.]
)
#v(0.7em)
#extra[
  *IntServ flow summary*: RSVP prepares the path and enables resource reservations (static phase). In provisioning, frames are associated with RTP and RTCP. In case of problems, a new path negotiation can occur locally (via RSVP).
]

// ─────────────────────────────────────────────────────────────
// PART 5: DIFFSERV - DIFFERENTIATED SERVICES
// ─────────────────────────────────────────────────────────────

== DiffServ: Differentiated Services (RFC 2474/2475)

#def("DiffServ")[
  #kw[DiffServ] differentiates flows in *classes* handled together: greater scalability than IntServ by supporting *low-level differentiation* (work at network layer, not application layer). Do not work for each information flow separately, but *aggregate network-level classes of flows*. Suitable for legacy applications (less user involvement than IntServ).
]
#v(-1em)
#example("DiffServ Classes")[
  Example class structure:
  - *Gold*: 70% bandwidth
  - *Silver*: 20% bandwidth
  - *Bronze*: 10% bandwidth
  Or alternatively:
  - *Premium*: low delay
  - *Assured*: high speed, low packet loss
]
#v(-1em)
#prop("DiffServ Mechanism")[
  - Classification when packet *enters* based on packet content.
  - *SLA* based on classification: policy arranged between user and server.
  - A flow is classified at input and inserted in the right queue (*Per-Hop Behavior*, PHB); subsequent support is automatic.
  - Packet marking inside *DS byte* (Differentiated Service):
    - IPv4 ToS byte
    - IPv6 traffic-class byte
  - *Traffic classifiers*: Multi-Field (MF: DS byte + other fields) or Behavior Aggregation (BA: only DS byte).
]
#v(-1em)
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

#figure(
  image("../assets/qos-traffic-conditioning.jpg", width: 40%),
  caption: [QoS Meter, Marker, Dropper/Shaper.]
)

=== IntServ vs. DiffServ

#figure(image("../assets/qos-intserv-diffserv.svg", width: 95%), caption: "IntServ (per-flow RSVP reservation, hop-by-hop) vs. DiffServ (aggregate class queues, DS byte marking).")

=== IntServ + DiffServ Together

Both approaches cooperate.
- DiffServ is more scalable and supports legacy services.
- IntServ can grant specific QoS to specific flows.
Often joined in connected areas: *IntServ* used in smaller, controlled domains, while *DiffServ* in the wider Internet between domains.

// ─────────────────────────────────────────────────────────────
// PART 6: SIP - SESSION INITIATION PROTOCOL
// ─────────────────────────────────────────────────────────────

== SIP: Session Initiation Protocol (RFC 2543/3261)

#def("SIP")[
  #kw[SIP] defines and manages *sessions* to support multimedia services. Has signaling capability for *establishing, modifying, and closing* multimedia sessions. Based on HTTP-compatible content: a *text-based, purely client/server* protocol. SIP itself #underline[does not carry media] (other protocols dom like RTP).
]
#v(-1em)
#prop("SIP Entities")[
  - *User Agent*: endpoints that act as User Agent Client (REQUEST) or Server (RESPONSE).
  - *Proxy Server*: application-level routers, can keep session transaction state (stateful) or be stateless.
  - *Redirect Server*: sends a client to a new alternative server.
  - *Registrar Service*: user registration to infrastructure.
  - *Location Service*: links interested users to their location.
]
#v(-1em)
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

#figure(
  image("../assets/sip.jpg", width: 40%),
  caption: [SIP flow.]
)

// ─────────────────────────────────────────────────────────────
// PART 7: NETWORK MANAGEMENT
// ─────────────────────────────────────────────────────────────

== Network Management

We need dynamic data collection mechanisms and policies that do *not require too many resources* (minimum intrusion principle). Any correct management must reserve as few resources as possible. Performance area (monitor and data management) must define tools and policies that are *the least intrusive as possible*.

Management functional areas (FCAPS):
- *Fault Management*
- *Configuration Management*
- *Accounting Management*
- *Performance Management*
- *Security Management*

#extra[Standards: OSI/ISO (CMIB, CMISE), SNMP/IETF, TINA/CCITT.]

=== SNMP: Simple Network Management Protocol

#def("SNMP")[
  #kw[SNMP] uses one *manager* (only one) and some predefined *agents* that control variables representing objects, identified by unique names (*OID* in hierarchical directories). Manager requests actions (`get`, `set`, `getNext`) and receives responses. Agents wait for requests and can also send *traps*. Uses UDP (Port 161 for messages, Port 162 for traps).
]
#v(-1em)
#prop("SNMP Standards")[
  - *SMI* (Structure of Management Information): defines rules for object names (ASN.1 and BER).
  - *MIB* (Management Information Base): objects, types, and relationship collections (according to OSI X.500).
]
#v(-1em)
#prop("SNMP Versions")[
  - *SNMPv1*: extremely simple, limited expressivity, only configuration/fault management, limited traps.
  - *SNMPv2*: overcomes C/S manager-agent hierarchy with *proxy agents* (act as both agent and manager), solving the *micro-management* congestion problem. Manager orders operations; proxies actuate them locally and send aggregated results.
  - *SNMPv3*: adds security (S-SNMP): integrity, masquerading prevention, privacy (prevent disclosure). Denial of service and traffic analysis not dealt with.
]
=== RMON: Remote Monitor

#def("RMON")[
  #kw[RMON] controls the support parts of the communication and allows access to related statistics: oriented toward *traffic and bandwidth*, not toward devices. Introduces *probe* entities capable of monitoring packets on the network autonomously (even disconnected from the manager), tracking subsystems and reporting filtered information to the manager.
  - RMON1: multiple and grafted operations.
  - RMON2: guaranteed security.
]

#figure(
    image("../assets/rmon.jpg", width: 50%),
    caption: [RMON probe.]
  )

=== OSI Advanced Network Management

OSI Management provides a more sophisticated model with three roles:
- *Manager*: active entity issuing management policies.
- *Agents*: intermediate entities acting on manager requests (can themselves be managers, flexible hierarchy).
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

*Simple FIFO policy*: unique queue for every flow, excludes any service differentiation. Cannot reserve resources for flows with different SLAs.

=== Kleinrock Conservation Law

#def("Kleinrock Conservation Law")[
  For *work-conservative routers* (cannot be idle if there are packets on any port and cannot postpone arriving messages): given $n$ flows with $lambda_n$ traffic $forall$ flow, if flow $n$ has service mean time $mu_n$, usage $rho_n = lambda_n mu_n$, and mean waiting time $q_n$:
  $ sum_n rho_n q_n = "Constant" $
  #so to give a lower delay or higher bandwidth to one flow, you *must* increase the delay or reduce the bandwidth of another.
]
#v(-1em)
#important("Work Conservation")[
  A router in Internet *must* work according to work conservation: it cannot decide to postpone any message arriving. Any QoS router must break this by *conditioning traffic*: introducing monitoring and making actions to decide more sophisticated service policies (delay some packets, discard some packets).
]
#side-note(color: rgb("#002fff"))[
  💯 #text(fill: rgb("#002fff"))[*Prof. Question*]: #text(fill: rgb("#002fff").lighten(50%))[_State Kleinrock's conservation law. Why must a QoS router break it?_]\
  For a *work-conserving* router, $sum_n rho_n q_n$ is *constant*, so you cannot lower one flow's delay without raising another's. To give real QoS guarantees the router must *break work conservation*: it *conditions traffic*, delaying or dropping some packets (shaping, scheduling, RED) instead of always forwarding whatever it can.
]

=== Bucket Models for Traffic Shaping

#def("Leaky Bucket")[
  #kw[Leaky Bucket]: the router has limited memory (capacity C) and limited output flow (R). Models a router *actively shaping* services by limiting output flows:
  - If data arrive too quickly beyond admissible output flow R #so *delayed*.
  - If data arrive beyond capacity C #so *lost*.
  Aims at *switching off packet bursts*: smooths traffic to an admissible level.
]
#v(-1em)
#def("Token Bucket")[
  #kw[Token Bucket]: tokens are generated uniformly by time ticking (r tokens/sec, capacity C). Each packet needs a token to pass, stored in the bucket:
  - If bucket empty #so packet waits.
  - If bucket full #so tokens available for packets.
  - Unlike leaky bucket: data beyond capacity are *not lost but only delayed*.
  - Allows *packet bursts*: if tokens have accumulated, a burst can pass immediately.
  Models flows *history* via tokens as authorization for passing.
]
#v(-1em)
#analogy("Leaky vs Token Bucket")[
  Leaky bucket: a bucket with a hole; water (packets) drips out at a constant rate regardless of input. If too much comes in, it overflows (drops).\
  Token bucket: a ticket machine where you need a ticket (token) to send a packet. Tokens accumulate when traffic is low, allowing bursts when traffic spikes.
]
#v(-1em)
#note[
  Often leaky bucket and token bucket are used in *serial chain*. The token bucket allows bursts, while the leaky bucket smooths the output.
]

#figure(
  image("../assets/leaky-token-bucket.jpg"),
  caption: [Leaky bucket (left) vs. token bucket (right).]
)

=== Scheduling Policies

#prop("Properties Required of Scheduling Policies")[
  - *Implementation facility*: easy router design toward real feasibility.
  - *Fairness and Protection*: any flow penalized same as others in same operational situation.
  - *Performance limits*: constraints on correct flow operation.
  - *Admission Control*: decision on admission before distribution.
]

==== Max-Min Fairness and GPS

#def("Max-Min Fairness")[
  General strategy: requests of different resources by different flows considered *in order of growing request* (first the ones that require less). Allocates to flow n: 
  $
  m_n = min(X_n, M_n) space.quad space.quad M_n = (C - sum_(i=1)^(n-1) m_i) / (N - n + 1),
  $
  where:
  - $C$ is the global max capacity of resources,
  - $X_n$ are resources request by flow$space.hair_n$ ($X_1<X_2<...<X_N$),
  - $m_n$ are previously allocated resources with success to flow$space.hair_n$,
  - $M_n$ are available resources for flow$space.hair_n$
  Scaling down done only in lack of resources.
]
#v(-1em)
#note[
  It is also possible to consider different weights for different flows.
]
#v(-0.5em)
#def("GPS: Generalized Processor Scheduling Fluid Model")[
  *Fluid traffic model*: answers service requests one at a time in a very fair Round Robin order: serves only *one bit per flow* per round. Theoretically optimal for service scheduling, but *not implementable* in reality (can only serve packets, not bits). All practical policies are approximations of GPS.
]
#v(-1em)
#note[
  GPS is not implemented in reality.
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
  - More suitable and simple to implement: available on all routers including low-cost.
  - *Weighted Fair Queuing (WFQ)*: different weights associated to different flows.
]
#extra[
  - *GPS (Theoretical Fluid Model):* Serves queues simultaneously *per-bit* (like water splitting into parallel pipes). It provides perfect, instantaneous fairness but is physically impossible on real packet-switched hardware.
  - *FQ (Practical Packet Model):* Emulates GPS by transmitting *one full packet at a time*. It runs a virtual GPS clock in the background and tags each incoming packet with its *virtual finishing time* (when it would finish service under GPS). The router then outputs packets sorted by the lowest tag first.
]

#figure(
  image("../assets/fair-queuing.jpg", width: 70%),
  caption: [Fair queuing example.]
)

=== Congestion Prevention

#def("RED: Random Early Detection")[
  #kw[RED] is a *#underline[proactive]* congestion prevention policy: a queue for every flow, queues with equal priority. Randomly discards packets *before* congestion occurs, based on queue length:
  - Queue < minimum threshold: no action.
  - Queue > maximum threshold: all new packets discarded.
  - Otherwise: discard with *probability proportional to queue length*.
  Success: packets are randomly discarded more and more as queues grow, preventing congestion before it becomes severe.
]
#v(-1em)
#important("Reactive vs Proactive")[
  Traditional best-effort Internet only allows *reactive* actions: discard excess packets (silently) or send choke packets. QoS-aware Internet enables *preventive (proactive)* actions such as RED, transmission windows on channels, or other strategies that prevent dangerous congestion situations.
]

=== Service Levels Summary

#table(
  columns: (auto, 1fr, auto),
  align: (left, left, left),
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 0.8em,
  table.header([*Service Level*], [*Characteristics*], [*Use Cases*]),
  [*Best-effort*], [No guaranteed throughput, possible delays, no duplication control], [Elastic Internet services],
  [*Controlled load*], [Similar to best-effort with low load, some delay limits], [Elastic services, tolerant real-time],
  [*Guaranteed load*], [Tight delay limits, maximum guarantees on flows], [Non-tolerant real-time services],
)
