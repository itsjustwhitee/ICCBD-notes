#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= REPLICATION FOR DEPENDABILITY
#extra[
  Package: Replication for Dependability - `7  - Replication for Dependability 26.pdf`
]

Dependable systems must continue to operate correctly even in the presence of faults. This chapter introduces the core concepts of #kw[fault tolerance], the models behind system replication, and the architectural strategies used in practice to achieve high availability and reliability.

== Core Concepts: Dependability and Faults

=== Some Definitions

#def("Dependability / Fault Tolerance")[
  #kw[Dependability] is the umbrella property that makes a system *trustworthy*: users and operators can rely on it to deliver correct service continuously, even under hardware failures, software bugs, and adverse events. It encompasses availability, reliability, and recoverability, all of which must hold at every level: hardware, software, and protocol.
]
#v(-1em)
#def("Availability (continuity of service)")[
  #kw[Availability] is the fraction of time the system is *operational and accessible*. It is formally $A = "MTBF" \/ ("MTBF" + "MTTR")$, where MTBF is the mean time between failures and MTTR is the mean time to repair. High availability requires both infrequent failures *and* fast recovery. In-memory replication on multiple nodes is a typical technique to reduce MTTR.
]
#v(-1em)
#def("Reliability (correctness of results)")[
  #kw[Reliability] is the ability to deliver *only correct results*, without any erroneous output, over an extended period. Unlike availability, it does not promise when the result arrives, only that what it returns is right. Reliable storage on disk (stable memory) is a classic mechanism for preserving correct state across crashes.
]
#v(-1em)
#def("Recoverability (state restoration after failure)")[
  #kw[Recoverability] is the ability to *restore correct service state* after a fault, by returning to a previously saved consistent state (a checkpoint). A recoverable system does not lose committed work. Safety, consistency, security, and privacy are all aspects that the recovered state must still satisfy.
]

=== Faults, Errors, and Failures

#def("Fault, Error, Failure")[
  - *Failure*: any behavior not conforming with the requirements.
  - *Error*: any problem that can generate an incorrect behavior or a failure (unsafety).
  - *Fault*: set of events in a system that can cause errors.
]

An application can fail and it can cause a wrong update on a database.

- *Fault* is the _concrete causing occurrence_ (several processes entering at the same time).
- *Error* is the _sequence of events_ (mutual exclusion has not been enforced) that can generate the visible effect of *Failures* (to be prevented).

#so fault tolerance.

=== Types of Faults

Faults can be *transient*, *intermittent*, or *permanent*:

- *Bohrbug*: a fault that is *deterministic and repeatable*: it appears every time the same conditions occur, so it is relatively easy to reproduce, isolate, and fix. Named after Niels Bohr's solid atomic model (you know exactly where the electron is).
- *Eisenbug*: a fault that *disappears or changes behavior when you try to observe it*: for example, a race condition that only shows up under specific timing or load. Named after Heisenberg's uncertainty principle. Eisenbugs are tied to particular execution contexts and often vanish when debugging instrumentation is added, making them very hard to diagnose.

=== Services Unavailability

Any system can crash and may become unavailable for some time. *Planned downtime* (maintenance windows, software upgrades) can be scheduled and communicated in advance. *Unplanned downtime* is the real problem: it hits users without warning and is harder to recover from quickly.

Regardless of the cause, restoring normal operation requires two sequential phases: *fault/error identification* (detecting that something went wrong and localizing the cause) followed by *recovery* (returning the system to a correct, operational state).

Common causes of downtime by business impact: hardware drive or server failures (55%), human error (22%), software bugs (18%), and natural disasters (5%). By raw incident frequency, human error and unexpected configuration changes are actually the most common triggers.

=== Service Unavailability Indicators

#def("Number of 9s")[
  The standard metric for measuring availability. It expresses not only the *frequency of crashes* and the *percentage of uptime*, but also the *capacity of fast recovery*, because the uptime depends not only from fatal failure occurrences but also from the capacity of recovering.
]
#v(-1em)
#note[
  The indicators are averaged over one year. *Availability* (A) = MTBF / (MTBF + MTTR).
]

#table(
  columns: (auto, auto, auto),
  align: (center, center, center),
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 0.8em,
  table.header([*Uptime (%)*], [*Downtime (%)*], [*Downtime*]),
  [98%], [2%], [7.3 days],
  [99%], [1%], [3.65 days],
  [99.8%], [0.2%], [17h, 30'],
  [*99.9%*], [0.1%], [8h, 45'],
  [99.99%], [0.01%], [52.5'],
  [99.999%], [0.001%], [5.25'],
  [99.9999%], [0.0001%], [31.5''],
)

=== Failure Costs

Downtime costs vary greatly by industry due to the different impact on society or on customers:

#table(
  columns: (1fr, auto),
  align: (left, center),
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 0.8em,
  table.header([*Industrial Area*], [*Loss/h*]),
  [Financial (broker)], [\$5.6M],
  [Financial (credit)], [\$2.6M],
  [Manufacturing], [\$0.8–1.5M],
  [Retail], [\$0.4M],
  [Avionic], [\$2M],
  [Media], [\$~],
)

#note[A true and precise evaluation is very difficult. Business consequences of outages include: Transaction Loss, Idle Resources, Lost Opportunity, Penalties, Lost Customers, Lost Reputation, Litigation, and Loss of Life.]

== Fault Identification and Recovery

=== Fault Identification in Client/Server Systems

In a client/server interaction, both sides monitor each other:
- The *client* sends a request and waits with a timeout; if no reply arrives in time, it assumes the server has failed or is unreachable.
- The *server* sends its reply and may wait for an acknowledgment; unacknowledged messages are resent up to a configured limit.

The difficulty is that neither side can directly distinguish a crashed server from a very slow one, or a lost message from a delayed one. This ambiguity is why *fault assumptions* matter: by agreeing in advance on what kinds of faults can occur and how many simultaneously, designers can keep detection and recovery protocols tractable.

The number of message retransmissions also determines how many faults can be masked: more retransmissions mean more fault coverage, but also higher latency and communication overhead in the normal case.

#note[Fault tolerance design can be very intricate. Fault assumptions (explicit agreements about what can go wrong and how often) are the engineering tool that keeps the complexity manageable.]

=== Single Point of Failure (SPoF)

#def("Single Point of Failure (SPoF)")[
  Unique points that must be available at any time: a *single point of failure* in an architecture. Single fault assumption #arrow general, not so reliable.
]

- With *2 copies* you can identify 1 failure but not correct it.
- With *3 copies* you can identify 1 failure and can correct it.
- In general terms, with *3t copies* we can tolerate *t faults* for a replicated resource (without any fault assumption).

=== Single Fault Assumption

#def("Single Fault Assumption")[
  Fault assumptions simplify management and system design. *One fault at a time*:
  - The identification and recovery must be less than *TTR* (Time To Repair) and *MTTR* (Mean TTR).
  - The interval between two faults (TBF Time Between Failure and *MTBF* Mean TBF).
  - During recovery we assume that *no fault occurs*, and the system is safe.
]

- With *2 copies*, we can *identify one fault* (via some invariant property), and even if fault caused the block, we could continue with the residual correct copy (in a degraded service) with single fault assumption.
- With *3 copies*, we can *tolerate one fault*, and we can *identify two faults*.

=== Fault Assumptions for Communicating Processors

#table(
  columns: (auto, 1fr),
  align: (left, left),
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 0.8em,
  table.header([*Model*], [*Description*]),
  [*Fail-Stop*], [One processor fails by stopping (halt), and all other processors *can verify* its failure state.],
  [*Fail-SAFE* (CRASH or HALT assumption)], [One processor fails by stopping (halt), and all other processors *cannot verify* its failure state.],
  [*Byzantine Failures*], [One processor can fail, exhibiting any kind of behavior, with *passive and active malicious actions* (see Byzantine generals). _Limit feasible._],
)

#extra[Typically, Fail-Stop and Fail-SAFE are used; Byzantine is the hardest case.]

=== Fault Assumptions and Number of Processors

How to implement Fail-Stop and Fail-Safe, and how many processors are needed:

- *Fail-Stop*: You need *3 processors* and *single fault assumption*. One processor fails by stopping and all others can verify its failure state.
- *Fail-SAFE* (HALT): For HALT, you can adopt *single-fault assumption and two processors*. Both stop when any different result is observed.

=== Distributed Systems Fault Assumptions

More advanced fault assumptions on communication:

#table(
  columns: (auto, 1fr),
  align: (left, left),
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 0.8em,
  table.header([*Model*], [*Description*]),
  [*Send & Receive Omission*], [One processor fails by receiving/sending *only some* of the messages it should have worked on correctly.],
  [*General Omission*], [One processor fails by receiving/sending only some messages, and it may work on them correctly *or by halting*.],
  [*Network Failure*], [The whole interconnection network does *not always grant correct behavior*.],
  [*Network Partition*], [The whole interconnection network does not work by *partitioning the systems in two parts* that cannot communicate with each other.],
)

#note[Replication is a fundamental strategy to build dependable components in all these models.]

== High-Level Goals and Formal Properties

=== Availability and Reliability

#def("Availability")[
  *A = MTBF / (MTBF + MTTR)*: defines the percentage of *correct services in time* (the number of 9s). It can also be different for read and write operations: if we consider more copies, the read can be answered also if only one copy is available, and other ones are not (action that does not modify).
]
#v(-1em)
#def("Reliability")[
  Probability of an available service depending on time and based on a period of Δt:
  - R(Δt) = reliable over time Δt.
  - R(0) = A, as a general limit.
]

=== Correctness and Vitality

Formal properties of dependable systems:

Two formal properties capture the essential quality requirements of a dependable system:

- *Safety (Correctness)*: nothing bad ever happens. All system invariants are always satisfied: the system never returns a wrong answer, never enters a corrupt state. If uncertain, it does nothing rather than risking incorrect output.
- *Liveness (Vitality / Availability)*: something good eventually happens. Every valid request eventually receives a response; the system makes progress and never stays blocked forever.

#note[
  These two properties trade off against each other under failures:
  - A system with *only safety* (no liveness) will always give correct answers, but may simply stop responding when uncertain. It is correct but potentially frozen.
  - A system with *only liveness* (no safety) will always respond, but may return wrong or stale data. It is responsive but potentially incorrect.
  - A fully dependable system requires both. To achieve both under faults, *space replication* (multiple simultaneous copies) or *time replication* (retries, checkpoints, replaying from log) is necessary.
]

== Fault-Tolerance Architectures

=== Replicated Components

Fault-tolerant architectures use *replicated components*: multiple copies of the same logical resource placed on different machines, so that if one fails, the others can take over. Replication applies at every level: hardware disks (RAID), processors (TMR), services, and data stores.

The key design question is *how active each replica is*:

1. *Passive replication (master-slave)*: only one copy, the master, actually executes requests and produces results. The other copies are backups that receive periodic state updates but do no work. Simple to reason about, but the master is a bottleneck and its failure requires explicit failover.
2. *Active replication*: all copies execute the same request independently and then coordinate to agree on a common answer. Faults are masked without failover delay, but the coordination overhead is higher.
3. *Load-sharing clusters*: all copies are equal in role but execute *different* requests simultaneously, splitting the workload. This maximizes throughput without requiring coordination among requests, but provides no single-fault masking on a per-request basis.

#note[These architectures introduce a *metalevel*: parts that control the rest of the system (managing replication, detecting failures, coordinating state). The metalevel itself must be dependable, or the whole scheme collapses.]

=== Stable Memory

#def("Stable Memory")[
  Uses replication strategies (*persistency on disk*) to guarantee not losing any information. It is based on the *limiting fault assumption*: a low and negligible probability of multiple faults over related memory components (single fault over connected blocks of memory).
]

Any error is converted into an *omission* (a control code is associated to the block and the block is considered correct or faulty). Blocks are organized in *two different copies* over different disks, with a really low probability of simultaneous faults (conjunct faults): the two copies contain the same information. *Replication degree is two.*

#note[High cost of implementation, especially in terms of timing (how to limit the recovery time?)]

=== Stable Memory: Support Protocols

Any operation (either read or write) operates on both copies; if one is incorrect, a recovery protocol starts:
- Any *action from a correct block*: proceeds starting from one copy and then to the other.
- Any *action from an incorrect block*: considered an omission fault and starts a recovery protocol.

The recovery protocol has the goal of recovering both copies to a safe state, even by working for a long time:

- If *both copies are equal and consistent*: no action.
- If *only one copy is correct*: the protocol copies the correct value over the wrong copy.
- If *both copies are correct but inconsistent*: the consistency is established (one content is enforced).
- If copies have a *time/version indicator*: it is used to choose the correct copy.

=== TANDEM Systems

#def("TANDEM")[
  TANDEM (later acquired by Compaq then HP, marketed as "NonStop") is a *special-purpose fault-tolerant system* designed for continuous online operation - it keeps data in memory (not solely on disk) and replicates every hardware component: two processors, two buses, two disks, and so on. All copies operate in *perfectly synchronous lockstep*.
]

The goal is a *fail-safe* system that tolerates any single hardware fault:
- Every component is mirrored, so if one fails, its twin continues without interruption.
- Stable memory is implemented by writing to both buses, which each write to a mirrored pair of disks.

#note[The cost is very high: double hardware, strict synchrony overhead. This makes TANDEM a special-purpose solution for mission-critical environments like banking and financial transaction processing.]

Replication can follow two strategies: execute every action on *both* copies simultaneously (active replication), or execute on *one* copy and use the other purely as a hot standby backup.

=== RAID: Redundant Array of Inexpensive Disks

#def("RAID")[
  #kw[RAID] is a general-purpose technique that coordinates a set of commodity disks to improve either *performance* (via striping) or *fault tolerance* (via redundancy), or both, at a much lower cost than special-purpose hardware like TANDEM.
]

The original goal was to improve *throughput* via *data striping*: split a file across multiple disks so they can be read or written in parallel. Later RAID levels added *parity* or *mirroring* to recover from disk failures. Each level trades off cost, capacity, and protection differently:

- *RAID 0 - striping only*: data split across N disks for maximum parallel I/O throughput. No redundancy: any single disk failure loses all data. Suitable for performance-critical scratch storage where loss is acceptable.
- *RAID 1 - mirroring*: every disk has an exact copy. Maximum redundancy: survives failure of any one disk. Reads can be load-balanced across both; writes must hit both. Cost: 50% capacity overhead.
- *RAID 3 & 4 - striping with a dedicated parity disk*: data striped byte-by-byte (RAID 3) or block-by-block (RAID 4), with a single dedicated parity disk. The parity disk becomes a bottleneck: only one write I/O at a time can proceed.
- *RAID 5 & 6 - distributed parity*: parity blocks are spread across all disks, eliminating the parity-disk bottleneck. RAID 5 tolerates one disk failure; RAID 6 adds a second parity block to tolerate two simultaneous failures. Best balance of performance, capacity, and fault tolerance for general use.

== Fault Tolerant Support: Costs and Principles

=== Fault Tolerant Support Overview

*Fault tolerance requires support, resources, protocols.* Protocols are expensive in terms of required resources:
- Complexity and length of the algorithms.
- Implementation of the algorithm (and their correctness).

There is no *unique strategy* for always accepted solutions: dependability is a non-functional property with many facets. In general terms, the recovery protocol must be more reliable than the application itself.

- *Special-purpose systems* #arrow ad-hoc resources even with better QoS.
- *General-purpose systems* #arrow fault tolerance support insists on user resources.

=== Minimal Intrusion Principle

#def("Minimal Intrusion Principle")[
  Applies to any solution to *limit the cost of the dependability support*, by organizing the resource engagement (overhead) at any support and system level. It is an engineering principle that should be considered in any design of systems, to answer with the requested SLA.
]

- *Special-purpose systems*: achieve dependability via an added ad-hoc architecture completely separated from the application one. Costs are high and the design is complex (formal proofs?).
- *General-purpose systems*: user resources are the only one available. The fault tolerance support *must economize on its design* so not to get too much from the resources for the application levels.

=== High Replication Costs

Dependability costs are generally high in two senses and dimensions:
- *Space*: in terms of required *resource* available (multiple copies).
- *Time*: in terms of *time, answer and service timing*.

Often fault assumptions can make the system more or less complex and viable the cost of the solutions.

Cost may depend on many different factors: memory and persistency costs, communication overhead, implementation complexity, what to replicate, how many copies, where to keep them, how to coordinate, etc.

#note[The general trend is in the sense of *optimizing protocols, supports, infrastructures*.]

== Resource Management and Replication Architectures

=== Resource Management with Replicated Resources

In distributed systems, we can consider *replicated resources* with an obvious need of coordination toward a common goal (also software fault-tolerance):

- *Replicated resources*: multiple resource copies on different nodes with *several replication degrees*.
- *Partitioned resources*: multiple resource copies on different nodes (without any replication degree) to work *independently*.

Redundancy can suggest architectures to get a better QoS: *replication of processes and data*.

=== Abstract Unique Resource Model

The *replication degree* is the number of copies (#kw[\# copies]) of the entity to replicate. The greater the number of copies, the greater the redundancy. The better the reliability and availability. *The greater the cost and the overhead.*

Two extreme models of FT architectures:
1. *One only executes* (master-slave).
2. *All execute* (copies are active and peer).

With variations in between.

=== Replication Architectures: Passive Model (Master-Slave)

#def("Passive Model (Master-Slave)")[
  *Only one copy executes, the others are back-ups.* This is the first replication model well spread in industrial plants. The *master* is externally visible and manages the whole resource. The slaves must control the master for errors and faults.
]

Structure: MASTER #arrow CHECKPOINTING #arrow CONTROL (slaves observe).

=== Active Replication Model

#def("Active Model")[
  *All copies execute all operations* in a more or less synchronous way and with some forms of coordination among copies.
]

In *TMR* (Triple Modular Redundancy) *three copies* are used: we can tolerate on faults and can identify up to two faults. In software FT, different copies can use *different algorithms* toward the goal.

#figure(
  image("../assets/replication-models.svg", width: 95%),
  caption: "Passive (master-slave) vs. active (TMR) replication: trade-off between simplicity and fault masking strength."
)

=== Passive Replication Model

The two extreme FT models are:
- *Master Slave* (passive model).
- *Active Copies* (active model).

The *passive model* (master/slave or primary/backup):
- Has one *active process only* (the master or primary) actively executing over data; the other copies (passive ones or backups) become operational only in *case of failure* of the master.
- *Only one copy is fresh and updated*; the others can also be obsolete in state and not updated (*cold* or *hot* copies).

This mode can produce a possible conflict between the state of the master and the state of the slaves:
- In case of a failure and cold copies, one must start repeating from the previous state, to produce the updated state.

=== Master-Slave: Architecture

*Master and Slaves are an internal architecture.*

*Fault Recovery*: who identifies the fault and when:

Secondary copies (slaves) must identify the fault of the master *by observing its activity*: by using application messages coming from the master and by keeping the timing into account. Even ad-hoc management messages can be used and exchanged.

The organization can use:
- *One slave* for the control protocol (_if single fault_).
- *A hierarchy of slaves* and more complex protocols (_for multiple faults_).

The entire *resource*, from an external perspective, can tolerate a different number of errors depending on internal strategies and can still provide correct services in case of errors (*fault transparency*).

=== Checkpoint: Slave Checkpoint

In general, the master updates the slave states via *checkpointing* #arrow the updating action also made in a chain: the master updates the first slave that updates the second, …

The management policies can distinguish:
- The required actions to grant a correct response: *update of the primary copy* (first slave).
- From successive actions (less crucial): *update of the secondary copies* (other slaves).

Those strategies can achieve different policies and different state updating costs and quality:
- The client gets the answer with *less delay* if the master answers before the state has been updated in all copies (but only a part) or even in *no slave copy* at all (_prompt but not safe_).
- In the other case, the *delay is more*, but we grant more *consistency on the internal resource state* (_safe less prompt_).

=== Master-Slave: Checkpoint Timing

The update of the state and its establishment over the slaves:
- *Periodic action* (time-driven).
- *Event action* (event-driven).

In case of a *sequential resource*, the state is clearer and easier to identify and establish. In case of a *parallel resource*, all the parallel actions should be taken into account and considered toward the state saving. The state subjected to more *concurrent actions is less easy to isolate* and the *state is harder to identify* and distinguish.

#note[The checkpoint of a resource with several operations going on at the same time is more complex to deal with and to complete correctly, because of the sharing of data between concurrent activities.]

Checkpoint at *entrance/exit* and in *specific decision points*.

== Active Replication: Models and Coordination

=== Active Replication Model Details

*Active copies*: all copies are active and consistent in executing all operations.

An activity executes the operation for any private data copy. Client external requests to the server can have an either *explicit* or *implicit* approach related to replication:

- If the *client has an explicit vision* of FT #arrow *no abstraction*. This organization lacks abstraction because all clients have too much visibility of internal FT details of servers.
- If the *client has an implicit FT* #arrow *FT transparency*. Need of a support capable of getting the request and distributing copies to server copies and vice versa for results.

=== Active Copies Replication: Manager Strategy

Fault tolerance is usually an *invisible internal detail* of the replicated resource: the client sees a single logical service and is unaware of how many copies exist. To coordinate requests across copies, a *manager* role is needed:

- *Single manager (static)*: one designated copy acts as manager for all operations. It receives every request, distributes it to other copies, collects their results, and returns the agreed answer to the client. Simple to implement and easy to reason about, but the manager is both a performance bottleneck and a potential single point of failure.
- *Rotating managers (dynamic)*: each operation gets a different manager, chosen by locality (the copy closest to the client) or by rotation (round-robin across copies). This distributes the coordination load evenly and removes the single point of failure, but requires careful handling when multiple operations are in flight simultaneously to avoid conflicting decisions by different concurrent managers.

#note[When several operations are handled by different managers at the same time, the managers must avoid interfering with each other: for example, by acquiring per-object locks or using atomic multicast to impose a consistent execution order.]

=== Active Copies Coordination

Active models can decide different coordination models:
- *Perfect synchrony (full consistency or strict consistency)*: all copies should agree and produce a *completely synchronized view*, with the same internal copy scheduling for all copies (difficult for nested actions or external actions).
- *Different approaches to synchrony (less consistency)*: even if some minimal threshold can be considered, actions can complete before all copies agree on the final outcome, and the final agreement can take place later (also it does not apply even eventually).

#note[Less synchronous strategies cost less in time, mainly client service time, and makes protocols easier and more viable but grant less in operation ordering and release some _semantic properties_. Some modern Cloud systems decide of abandoning *perfect synchrony* in favor of an *eventual synchrony*.]

=== Copies Coordination: Read/Write Actions

Different actions on active copies have different requirements and management:
- *Read actions*: typically actions that can occur easily in parallel and accessing a limited number of copies.
- *Write actions*: those intrinsically require *coordination among copies*.

Any action that can change the state implies more coordination to propagate such a change:
- In case of a *clean state partitioning*, where any change applies to different partitions, those actions can proceed independently in parallel without any coordination.
- Eventually, some actions can require a *copy reconciliation* of actions that could have been interfering.

There are also actions with very specific intrinsic semantics. For instance, the *actions on a directory* can proceed with some more parallelism: add/delete of a file, read/write of a file, directory listing. Even semantic properties can distinguish operations and can make possible more efficient behavior and greater parallelism.

=== Active Copies Updating

Any action that requires to update the state of any copy:

The *update action* must occur *before delivering the answer* to grant a complete consistency but that impacts on response time (more delay in case of failures) (*eager policies vs. lazy*).

If the component employs *different managers for any operation*, it is a manager duty to command the internal actions. If the component defines *parallel operations*, all managers must negotiate and conciliate their decisions, causing some conflict to be solved and some actions in incorrect order to be *undone or redone*.

#note[*Strategies for the operation maximum duration*: In case of failure during one operation and before its correct completion, there should exist the feature of giving an answer anyway, because of the excess of accumulated delay in finishing internal agreement protocols.]

=== Active Copy Agreement

Copies can reach an agreement before giving the answer:
- *All copies should agree* on the specific action (*full agreement*).
- *Majority voting* (not all copies must agree) *with a quorum* (also weighted): correct copies can go on freely; other copies must agree on it and then reinserted in the group (recovery).

*Failure detection*: who is in charge? When? *Reinsertion detection*: who is in charge? When?

There is a *strict need of monitoring* and execution control.

*Group semantics*: in a group, depending on agreed semantics of actions, there may be also less expensive and less coordinated actions on execution orders. *The less the coordination, the less is the cost.*

== The Five Phases of Replication Operation

=== Overview

To make clear the needs of different steps and one general workflow, we can model the group operation as a sequence of *five phases*:

1. *Request Arrival*
2. *Copy Coordination*
3. *Execution*
4. *Copy Agreement*
5. *Response Delivery*

=== Phase 1: Client Request

The client initiates the operation by sending its request to the replicated resource. It has two options: send to *one copy only* (a designated manager, which then internally forwards the request to all other replicas), or send directly to *all copies simultaneously*. Sending to one copy is simpler for the client but puts more coordination responsibility on that copy; sending to all is more robust against a single-copy failure at the cost of requiring the client to know the full replica set. Which copy acts as manager can be fixed at deployment time or elected dynamically per operation.

=== Phase 2: Copy Coordination

Before executing, copies must coordinate to agree on *when and in which order to run* the operation. This is critical when multiple operations may be in flight simultaneously: without prior coordination, different replicas could apply concurrent operations in different orders, leading to divergent states. One copy acts as *manager* for this operation, proposing an execution schedule. Copies may carry different weights (as in weighted quorum protocols) and play different roles. This is the *first coordination phase*.

=== Phase 3: Copy Execution

With coordination complete, copies actually run the operation. In an *active model*, all replicas execute independently and produce their own result; in a *passive model*, only the master executes while backups wait. Some local freedom may still exist: for instance, a copy may skip execution if it has already received the committed result from the manager. Conflicting executions due to concurrent overlapping operations are resolved here or corrected in the next phase.

=== Phase 4: Copy Agreement

After executing, all copies must agree on the *final result* before it is delivered to the client. Some copies may have produced divergent outputs due to faults or concurrent operations from other managers. The group votes: if a quorum agrees on the same result, that becomes the committed answer; divergent copies are excluded from the group and must be recovered and re-synchronized before they can rejoin. If agreement cannot be reached (too many copies failed), the operation is rolled back. This is the *second coordination phase*.

=== Phase 5: Result Delivery

Finally, the agreed result is returned to the waiting client. The preferred form is a *single unified answer*: the client should not need to know that replication exists. If the client sent its request to all copies directly in Phase 1, it may receive multiple identical responses and must accept the first valid one while discarding duplicates. Minimizing complexity on the client side is a key design goal.

=== Observations on Active Copies Operations

The sequence of the five phases gives a first idea of the complexity of an active copy replication. The coordination among copies tends to induce a high overhead to be limited. So the *replication degree must be kept low* and *replication policies are to be kept simple*.

#note[*Eager consistency* (strong guarantees) vs. *Lazy availability* (fast, optimistic). The trade-off is central to replication system design.]

=== Active Copy Operations Classification

To classify some FT resources replication, we can use two significant directions:
- *Who decides the updating*: only the primary copy or all copies.
- *When to propagate and take the updates*: *eager* (immediate and before the answer) pessimistic, or *lazy* (delayed after the propagation) optimistic.

(We can reverse the terms for the client perspective.)

For the updating we can distinguish:
- *Eager primary copy* vs. *Lazy primary copy*.
- *Eager updating for all copies* vs. *Lazy updating for all copies*.

=== Eager Primary Copy

Sticking to *one primary*, that copy executes and *gives back* the answer only after *having updated the state* of all copies in a pessimistic approach (*one operation at a time with faults*).

In that case, the manager is in charge of the whole coordination, but the client receives a deferred answer (for correctness sake). If more operations are active over the replicated object that does not change, they can proceed in parallel.

Flow: Phase 1 (Client Request) #arrow Phase 2 (Server Coordination) #arrow Phase 3 (Execution + Update) #arrow Phase 4 (Two Phase Commit Agreement) #arrow Phase 5 (Client Response).

=== Lazy Primary Copy

On the opposite, the manager can first answer to the client and afterwards it updates the copies with an *optimistic approach* (_also several operations can go on at the same time_).

In this case, the manager must also be able to control the possible reconciliation of the state of the copies ... and some problems may occur if there is a manager crash.

Flow: Phase 1 #arrow Phase 3 (Execution + Update primary) #arrow Phase 4 (Client Response) #arrow then Reconciliation with other copies.

=== Update of Active Copies

*Eager policies* favor *consistency and correctness* of the operations, instead of the promptness of the answer to the client:
- The goal is *not very fast precocious answers*, because that can lead to undo actions, that are not easy to be done, and, in some cases, impossible to backtrack.

Copy coordination is *two phases toward consistency granting* (specially in case of concurrent actions):
- Those two phases are *not always needed*, but they can obtain the necessary coordination among copies and operations.
- *A-posteriori coordination* to *verify consistency*: if it is not verified, some *undo* must be considered (two phase protocol and roll back).
- *A-priori coordination* can ensure that all correct copies receive all correct messages and the right schedule is automatically enforced (e.g., *atomic multicast*).

=== Optimistic Eager Update

All copies are updated with some enforcing policies in an *optimistic approach* (*two-phase commit*), only afterwards the answer is provided to the client.

After copy independent executions, the final coordination ensures an agreement, otherwise some backtracking is commanded (*possible undo*).

Flow: Phase 1 (Client) #arrow Phase 2 (Server Coordination) #arrow Phase 3 (Execution + Update all copies) #arrow Phase 4 (Two Phase Commit Agreement) #arrow Phase 5 (Client Response).

=== Pessimistic Eager Update

A different approach for eager update implies coordination but tends to save the final phase. The agreement of results is granted via a delivery protocol *in a pessimistic approach*.

An *atomic multicast can ensure* that any message is correctly sent to all copies in the same order, so that there is no need for a final check (*no undo*).

Flow: Phase 1 (Client) #arrow Phase 2 (Atomic Broadcast in Server Coordination) #arrow Phase 3 (Execution + Update all copies, skipping Phase 4) #arrow Phase 5 (Client Response).

== Replication Forms and Widespread Models

=== Replication Forms Summary

#table(
  columns: (auto, auto, 1fr),
  align: (left, left, left),
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 0.8em,
  table.header([*Category*], [*Model*], [*Variants*]),
  [*Hardware Replication*], [-], [Disks, Processors, Batteries, Energy, ...],
  [*Software Replication*], [Passive Model], [Hot Copies, Warm Copies, Cold Copies],
  [*Software Replication*], [Active Model], [Coordination required],
)

- *Hot copies*: continuous updating.
- *Cold copies*: no update actions.
- *Warm copies*: some update actions, but not continuous.

=== Widespread Replication Models

The *Master-Slave* (passive) model is simpler and has only one execution point per operation. *Active Copies* replication is more complex and requires coordination across all replicas for every operation.

In any model, the cost is influenced by the *group replication degree*: the number of copies, either working or not. A search on the most common applications and more widespread ones, the *replication degree is typically very limited* (no more than a few copies).

There are also *intermediate replication models*, non-FT oriented, with a set of resources able to work independently on the same kind of operations: they operate on *different services at the same time*, and they can share the *responsibility of being a back-up of each other* (throughput driven and load balancing).

== Industrial Operations and Evolution

=== Industrial Safety Evolution

Modern industrial fault-tolerant systems are classified by how they *respond to failures*, progressing from simple detection toward autonomous prediction and prevention:

- *Fail Safe*: on fault detection, the system transitions to a known safe, inert state. The priority is preventing harm, even at the cost of stopping all operation. Classic example: a railway signal defaulting to red when the control system loses power.
- *Fail Silent*: instead of entering a safe state, the system simply *stops producing output* on fault. Other components detect the silence and take over. More flexible than fail-safe because no pre-defined safe state is required.
- *Fail Operational*: the system continues functioning, possibly in a degraded mode, by automatically reconfiguring around the failed component. This is required in autonomous vehicles: a self-driving car cannot simply stop in the middle of a motorway when a sensor fails.
- *High Dependability*: the system uses continuous monitoring, telemetry, and analytics to *predict* impending failures and act proactively before the fault occurs, avoiding any disruption.

#note[The progression reflects the increasing autonomy of safety systems: from "stop on failure" (fail safe) to "predict and prevent" (high dependability). Automotive functional safety standards (ISO 26262) and industrial standards (IEC 61508) formalize these levels.]

== Case Study: ALMA Web Service Architecture

=== Small-Scale Example

ALMA ICT has a small problem in answering many requests in a short time for a specific Web Service. A better solution than a *simple server* has to be devised to grant *limited answer times with no errors* and some *fault tolerance to single fault occurrence*.

Users are interested in getting Web server answers after invoking a Web service that interacts asking to a backend database. Requests arrive both from final portal users and also from external programs and other internal UNIBO applications. *Correct answers are very crucial.*

=== ALMA Web Service Architecture

The devised minimal cost solution:
- *Load balancing via a hardware balancer* as a front end of the two main servers.
- *INDEX01 and INDEX02*: two Web Servers in a cluster, two Tomcat instances managed by an Apache proxy.
- *Reliability* granted by a module of *High Availability Linux* master-slave with a heartbeat.

== High Availability Clusters

=== High Availability (HA)

High availability costs tend to decrease and to get better service. Low cost solutions are more and more common with better QoS and better dependability. Solutions are more and more *off-the-shelf*.

=== High Availability Cluster

#def("High Availability Cluster")[
  A cluster for *high availability* consists of a set of *independent nodes* that cooperate to provide a *dependable service, always on 24/7*.
]

The clusters are a good off-the-shelf solution for high availability:
- *Robust* and *reliable*.
- *Cost-effective* (easy to buy off-the-shelf hardware and support).
- *Typically one Front-end*.

Clusters have different motivations: high availability, high performance, load balancing.

=== Cluster Support Operations

The cluster support must provide:
- *Service monitoring*: to dynamically ascertain the current QoS (_final and perceived_).
- *Failover (service migration)*: the failover is a hot migration of a service immediately after the crash, whichever the cause. The failover must take place very fast to limit service unavailability. _Typically, should be automatic, fast, and transparent (the sooner the better)._
- *Heartbeat (node state monitoring)*: the heartbeat is the protocol to check node state to monitor and ascertain any copy failure. *Exchange of are-you-alive messages with low intrusion*. Some clusters can also work in case of partitioning and allow to go on and support reconciliation when reconnected.

=== Cluster: Failover and Heartbeat

In case of failover, the data must be available to the new node of the cluster via a *shared component* over the cluster. The detection of problem is via a *lightweight heartbeat protocol*: messages exchanged over both IP and non-IP networks for redundancy.

=== Storage Area Network (SAN)

#def("SAN: Storage Area Network")[
  A *set of interconnected resources with several QoS* to grant the storage service with the best suitability for different users. Users can employ SAN to get the storage resource they need without any interference and ideally without any capacity limit and with minimal delay.
]

*In Cloud*, the SAN can offer *Storage as-a-Service*.

=== Red Hat Cluster

*Red Hat Cluster suite (open source)*: a typical two-node cluster with shared disk storage. Its main components are:

- *Cluster Infrastructure*: CMAN (Cluster Manager, handles node membership and quorum), DLM (Distributed Lock Manager, coordinates shared access to resources), Fencing (isolates a failed node by cutting off its access to shared storage, preventing data corruption), CCS (Cluster Configuration System).
- *HA Service Management*: rgmanager, the resource group manager that monitors services and triggers failover when a node fails.
- *Shared Storage*: GFS (Global Filesystem, a shared-disk filesystem all nodes can mount simultaneously), CLVM (Clustered LVM, manages logical volumes across the cluster).
- *GNBD* (Global Network Block Device): exports a local disk over the network so other nodes can use it as a block device, enabling shared storage without dedicated SAN hardware.

Red Hat Cluster suite evolved a lot and is off-the-shelf. Red Hat Cluster can coexist with most widespread architectures (e.g., OpenStack: Nova, Glance, Swift, Quantum, Cinder, Keystone).

== Optimistic Lazy Policies and Eventual Consistency

=== Optimistic Lazy Policies

We use *lazy update* when one copy can answer with a little (no) coordination with other copies in an *optimistic policy that can deliver the answer very fast*: as in the case of *Amazon S3* (Amazon Simple Storage Service).

Amazon memory and persistence support *renounces to any strict consistency* and provides both *consistent* and *eventually consistent* operations.

=== Eventual Consistency

#def("Eventual Consistency")[
  *Strong consistency* has the eager update but slow answer. *Eventual consistency* (called final or tending to infinity) is a lazy update in the direction of *released consistency*: updates are commanded but not waited for.
]

So concurrent operations over other copies can see different values. On a long term, copy values are *reconciliated* and a consistent view is achieved. The *inconsistency window* may depend on many factors: communication delays, workload of the system, copy replication degree, ...
#v(-0.7em)
#note[
  The ACID vs. BASE framing (CAP theorem, 2PC, BASE properties) is covered in the #link(<ch06-acid>)[_*ACID*_] and #link(<ch06-base>)[_*BASE* sections of the Cloud and Data Center Global Strategies chapter_]. This section focuses on eventual consistency as a replication policy.
]
#v(-1em)
#note[(We are happy if it is *as limited as possible*.)]

=== Amazon S3: Optimistic Lazy Policies

In the case of *Amazon S3* you can also control both the allocation for your copies and the timing of checkpointing (*SLA control*):

- You can define your data *replicated in different buckets*: in *one local bucket* and in *others* (better than on the same machine), so you can have either a copy *Same-Region Replication* (SRR, close to you) or in a distant bucket *Cross-Region Replication* (CRR).
- The user can control the location of the copies, *either close in distance or very far regions*.
- The *distant copy CRR* can in some cases overcome big crashes of an entire region, but it takes time to propagate.
- The *neighbor bucket SRR* can be fast but may be subjected to common crashes.

*S3 Replication Time Control (RTC)*: Amazon S3 lets you also control not only the location but also the timing of the operations via *S3 Replication time Control*. S3 RTC replicates most objects that you upload to Amazon S3 in seconds, and *99.99 percent of those objects within 15 minutes*.

#note[S3 RTC by default includes S3 replication metrics and S3 event notifications, so to monitor the total number of S3 API operations that are pending replication, the total size of objects pending replication, and the maximum replication time, and also events that notify the bucket owner if object replication exceeds or replicates after the 15-minute threshold.]

== Docker Swarm and Modern Replication

=== Docker Swarm

#def("Docker Swarm")[
  #kw[Docker Swarm] is Docker's native container orchestration mode. A Swarm cluster consists of *manager nodes* and *worker nodes*: managers schedule and coordinate containers (called *services*), while workers execute them. A single manager console can distribute a containerized application across many nodes dynamically.
]

Docker Swarm provides built-in fault tolerance: if a worker node fails, the manager detects it via heartbeats and *reschedules the affected containers onto healthy nodes*, allowing the system to continue running (possibly in a degraded state until the new containers are ready).

For the manager itself, Swarm supports *multiple manager replicas* using the Raft consensus algorithm, removing the single point of failure. As long as a majority of manager nodes are alive, the cluster continues to schedule and coordinate services without interruption.

== Apache ZooKeeper <ch12-zookeeper>

=== ZooKeeper Overview

#def("Apache ZooKeeper")[
  ZooKeeper is a service for storing some *limited client data*, by using a *distributed replicated cluster of nodes* with excellent QoS, both *available and reliable*.
]

ZooKeeper is designed around four core principles:
1. *Simple*: the data model is a small hierarchical namespace of znodes (similar to a filesystem tree), each holding a small amount of data. No complex queries: just read, write, and watch.
2. *Replicated*: ZooKeeper runs as a cluster (an ensemble) of servers, all holding a copy of the state. Clients can connect to any server; all reads are local and fast; writes go through the leader.
3. *Ordered*: every write is assigned a globally unique, monotonically increasing transaction ID. Clients can use these IDs to impose their own ordering invariants on top of ZooKeeper's operations.
4. *Fast*: optimized for read-heavy workloads. Reads are served directly from any server's in-memory state without contacting the leader. The typical workload is far more reads than writes.

Data are kept by ZooKeeper servers as *znodes*, organized in a UNIX-like hierarchical namespace and replicated using *leader-follower (master-slave) replication*.

=== ZooKeeper Architecture

ZooKeeper organizes its data in a *hierarchical namespace* similar to a UNIX filesystem. Each node in the tree is called a *znode* and can hold a small amount of data (typically metadata, not large blobs).

Two types of znodes exist:
- *Persistent znodes*: survive client disconnections. Used for configuration data and service registrations.
- *Ephemeral znodes*: exist only as long as the client session that created them is alive. When the client disconnects or crashes, its ephemeral znodes are automatically deleted. This property is the basis for distributed *presence detection* and *lock release on failure*.

The leader is elected among server nodes using majority voting. A simple API (available in Java and C) lets clients manage the namespace:
- `Create(path, data, flags)`, `Delete(path, version)`
- `getData(path, watch)`, `setData(path, data, version)`
- `getChildren(path, watch)`, `exists(path, watch)`

Clients can attach a *watch* flag to any read call: they receive a one-time notification the next time that znode changes. Watches are reset after firing, so a client that wants continuous notification must re-register after each event. Transaction IDs on every write let servers serve clients fresh, ordered data.

=== ZooKeeper Reads and Writes

ZooKeeper keeps all data *in memory* across the ensemble. This makes reads extremely fast but limits the total data size to available RAM.

- *Reads* are served locally by any server in the ensemble. They are fast but may return slightly stale data (since followers may lag behind the leader momentarily).
- *Writes* always go through the *leader*, which uses a two-phase broadcast (ZAB protocol) to commit the write to a majority of followers before acknowledging the client. This ensures linearizable writes.

Clients can *watch* a znode: they register a one-time notification that fires when that znode's data or children change. This watch mechanism is the foundation for implementing distributed locks, configuration distribution, and leader election on top of ZooKeeper.

=== ZooKeeper Leader Election

*Replication is passive with a leader elected.* In case of leader crash, the election is based on the most recent data change among znodes (*transactionID*) via *majority voting*.

Election is also possible in case of Data Centers *partitioning* so to *work disconnected independently*.

#extra[ZooKeeper is widely used as coordination service in distributed systems, e.g., Apache Kafka uses it for broker metadata and leader election (prior to KRaft mode).]
