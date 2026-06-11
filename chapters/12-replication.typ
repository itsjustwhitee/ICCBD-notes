#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= REPLICATION FOR DEPENDABILITY
#extra[
  Package: Replication for Dependability — `7  - Replication for Dependability 26.pdf`
]

Dependable systems must continue to operate correctly even in the presence of faults. This chapter introduces the core concepts of #kw[fault tolerance], the models behind system replication, and the architectural strategies used in practice to achieve high availability and reliability.

== Core Concepts: Dependability and Faults

=== Some Definitions

#def("Dependability / Fault Tolerance (FT)")[
  The customer has a *full confidence in the system*, both in the sense of hardware, software, and in general any design aspect. Complete confidence in *any* design aspect.
]

#def("Availability (continuity of services)")[
  The system must provide *correct answers in an agreed limited time* — the stress is on correct response, *not on timing*. Memory copies can provide fast response time.
]

#def("Reliability (correct answers)")[
  The system must provide *only correct results* (no time constraints). Disk copies can achieve it via stable memory.
]

#def("Recoverability (recovery via state persistency)")[
  *Safety is Correctness* and there are also other aspects of Reliability: Safety, Consistency, Security, Privacy, ... (ACID typically).
]

=== Faults, Errors, and Failures

#def("Fault, Error, Failure")[
  - *Failure*: any behavior not conforming with the requirements.
  - *Error*: any problem that can generate an incorrect behavior or a failure (unsafety).
  - *Fault*: set of events in a system that can cause errors.
]

An application can fail — and it can cause a wrong update on a database.

- *Fault* is the _concrete causing occurrence_ (several processes entering at the same time).
- *Error* is the _sequence of events_ (mutual exclusion has not been enforced) that can generate the visible effect of *Failures* (to be prevented).

#so fault tolerance.

=== Types of Faults

Faults can be *transient*, *intermittent*, or *permanent*:

- *Bohrbug*: repeatable, neat failures, often easy to be corrected.
- *Eisenbug*: less repeatable, hard to be understood failures, hard to correct. _Eisenbug is often tied to specific runs and events, so not easy to be corrected._

=== Services Unavailability

Any system can crash and may become unavailable for some time. Causes of unavailability can stem from many different reasons, either planned ones or not planned. We need phases of *fault/error identification* and *recovery* to go back to normal operations.

Common causes of downtime include: hardware drive/server failures (55%), human factors (22%), software errors (18%), and natural disasters (5%).

The main downtime causes by frequency: Human Error (60), Unexpected Updates (56), Server Room Environment (44), Power Outages (29), On-site Disaster (26), Virus or Malware Attack (18), Hardware Error/Theft (14), Natural Disaster (10).

=== Service Unavailability Indicators

#def("Number of 9s")[
  The standard metric for measuring availability. It expresses not only the *frequency of crashes* and the *percentage of uptime*, but also the *capacity of fast recovery*, because the uptime depends not only from fatal failure occurrences but also from the capacity of recovering.
]

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

Client and Server play a reciprocal role in control and identification:
- The *client waits* for the answer from the server synchronously.
- The *server waits* for the answer delivery, verifying it — messages have timeout and are resent.

Fault identification and recovery strategies:
- *Faults that can be tolerated without causing failure* (at any time, all together and during the recovery protocol).
- *Number of repetitions* #arrow *possible fault number*.

#note[The design can be very hard and intricate. Fault assumptions simplify the complex duty.]

=== Single Point of Failure (SPoF)

#def("Single Point of Failure (SPoF)")[
  Unique points that must be available at any time — a *single point of failure* in an architecture. Single fault assumption #arrow general, not so reliable.
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
  *A = MTBF / (MTBF + MTTR)* — defines the percentage of *correct services in time* (the number of 9s). It can also be different for read and write operations: if we consider more copies, the read can be answered also if only one copy is available, and other ones are not (action that does not modify).
]

#def("Reliability")[
  Probability of an available service depending on time and based on a period of Δt:
  - R(Δt) = reliable over time Δt.
  - R(0) = A, as a general limit.
]

=== Correctness and Vitality

Formal properties of dependable systems:

- *Correctness = Safety = RELIABILITY*: guarantees that there are *no problems* — all invariants are always met.
- *Vitality = Liveness = AVAILABILITY*: achieving goals with *success* — the goal is completely reached.

#note[
  A system *without* safety and liveness gives no guarantee for any specific fault (no tolerance). A system *with safety* without liveness operates always correctly and can give results, without guarantee of respecting timing constraints. A system *without safety* with liveness always provides a result in the required time, even if the results may be incorrect (e.g., an exception). In any case, to grant any of those solutions should *consider replication either in time or space*.
]

== Fault-Tolerance Architectures

=== Replicated Components

Fault-tolerant architectures use *replicated components* that introduce added costs and require new execution models. HW replication, but replication also propagates at any level.

Differentiated execution: *several copies* either all active or not, over the same service, or working on different operations:

1. *(Passive copies)*: only *one component executes* and produces the result; all the others are there as *backups*.
2. *(Active copies)*: all components are *equal in role* and execute the same operation to produce a coordinated unique result (_maximum correctness: also by executing diverse algorithms and comparing results_).
- *All components equal and playing the same role*, executing different services at the same time and giving out different answers (*max throughput* in clusters of processors).

#note[These architectures are typically *metalevel organizations*, because they introduce parts that control the system behavior and manage replication.]

=== Stable Memory

#def("Stable Memory")[
  Uses replication strategies (*persistency on disk*) to guarantee not losing any information. It is based on the *limiting fault assumption*: a low and negligible probability of multiple faults over related memory components (single fault over connected blocks of memory).
]

Any error is converted into an *omission* (a control code is associated to the block and the block is considered correct or faulty). Blocks are organized in *two different copies* over different disks, with a really low probability of simultaneous faults (conjunct faults): the two copies contain the same information. *Replication degree is two.*

#note[High cost of implementation, especially in terms of timing (how to limit the recovery time?)]

=== Stable Memory — Support Protocols

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
  A special-purpose system with *online data* (not disk). TANDEM (bought and adopted by Compaq and HP, nonstop) uses replication via *two copies of any system component* (two processors, two buses, two disks, …) and the system works in a *perfectly synchronous approach*.
]

The goal: *fail-safe* system dependable with *single fault assumption*.
- Any error is identified via component replication and the double approach can tolerate it.
- The stable memory approach is implemented via access to the double bus to a doubled disk with double data replicated.

#note[The system cost is high and makes it special purpose (banks). Tandem has a high cost, both for resources and timing.]

Replicated copies can push to two strategies: make actions *twice*, in any component, or make actions *only once* and use the other copy as a back up.

=== RAID — Redundant Array of Inexpensive Disks

#def("RAID")[
  A *general-purpose organization of disks* with a replication goal but low-cost intention. A set of low-cost disks coordinated toward common actions with different goals in shared common actions to achieve different standard objectives. Commercial low cost off-the-shelf systems.
]

The initial goal of RAID was to offer *low response time* via *data striping*, so that a content is split among different disks to be read/written in parallel. Then some standards extended to consider *data replication*. Some classes consider different organizations for different standard goals.

- *RAID 0 — simple striping*: parallel I/O but no redundancy; suitable for I/O intensive applications but *worse MTBF*.
- *RAID 1 — mirroring*: maximum redundancy; for high availability even if higher cost; good performances in reading and less in writing.
- *RAID 3 & 4 — striping with dedicated parity disk*: high speed to support operations on large contents (images); one I/O operation at a time, for the contention on the parity disk.
- *RAID 5 & 6 — striping without dedicated parity disk*: the *distributed parity check* achieves good speed in case of many readings for small contents and good writing operations for large contents.

== Fault Tolerant Support — Costs and Principles

=== Fault Tolerant Support Overview

*Fault tolerance requires support, resources, protocols.* Protocols are expensive in terms of required resources:
- Complexity and length of the algorithms.
- Implementation of the algorithm (and their correctness).

There is no *unique strategy* for always accepted solutions — dependability is a non-functional property with many facets. In general terms, the recovery protocol must be more reliable than the application itself.

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

Cost may depend on many different factors: memory and persistency costs, communication overhead, implementation complexity — what to replicate, how many copies, where to keep them, how to coordinate, etc.

#note[The general trend is in the sense of *optimizing protocols, supports, infrastructures*.]

== Resource Management and Replication Architectures

=== Resource Management with Replicated Resources

In distributed systems, we can consider *replicated resources* with an obvious need of coordination toward a common goal (also software fault-tolerance):

- *Replicated resources*: multiple resource copies on different nodes with *several replication degrees*.
- *Partitioned resources*: multiple resource copies on different nodes (without any replication degree) to work *independently*.

Redundancy can suggest architectures to get a better QoS — *replication of processes and data*.

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

*Fault Recovery* — who identifies the fault and when:

Secondary copies (slaves) must identify the fault of the master *by observing its activity* — by using application messages coming from the master and by keeping the timing into account. Even ad-hoc management messages can be used and exchanged.

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

=== Active Copies Replication — Manager Strategy

Usually, the FT is an *implicit private strategy* of resources:
- *Either* there exists *one manager only* (static organization): centralized farm that receives the request and commands the operations, collects the answer and gives it back to the client.
- *Or* there exist *several managers* (dynamic): any operation gets a different manager in charge of it, with no central role and also balancing of requests.

Policy for choosing the manager:
- *Static*.
- *Dynamic* — by *locality* or by *rotation*.

#note[If several operations are alive at the same time, we need to avoid any interference among the different concurrent managers.]

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

The *update action* must occur *before delivering the answer* to grant a complete consistency but that impacts on response time (more delay in case of failures) — (*eager policies vs. lazy*).

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

The client can send the request of an operation:
- *Only to one of the copies*.
- *To all copies*.

In case of a delivery to copy only, it is that copy that should propagate the requests to all other ones. The *manager* is in charge of re-bouncing the first phase. The specific copy can be decided either dynamically or statically.

=== Phase 2: Copy Coordination

The copies must *coordinate with each other*, to define a negotiated policy in scheduling. One master copy can become the manager of that operation:
- All copies must decide *how and when to execute* the operation to prepare the correct execution.
- Different copies may have *different weight* within the group and also *different roles*.

This is the *first coordination phase*.

=== Phase 3: Copy Execution

The coordination phase influences the execution and some scheduling can be avoided or prevented. In general, some degree of freedom can be still left to individual decisions:
- All copies *execute* with proper decision (some copies maybe prevented, up to a master-slave case).
- Clashing executions may require coordination or a-posteriori actions.

=== Phase 4: Copy Agreement

All copies (some are out of the group) must agree on the result to be given back: some results are not conformant to the group whole decision. The group must decide either the commit or also some undo on some actions and the exclusion of related divergent copies from the group for incorrectness.

This is the *second coordination phase*.

=== Phase 5: Result Delivery

This phase has the goal of *delivering the correct result to the waiting client*:
- *One unified answer* to the client that has sent the request.
- *Answers from all copies separately* (overhead of handling all responses).

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

Flow: Phase 1 (Client) #arrow Phase 2 (Atomic Broadcast in Server Coordination) #arrow Phase 3 (Execution + Update all copies — skipping Phase 4) #arrow Phase 5 (Client Response).

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
  [*Hardware Replication*], [—], [Disks, Processors, Batteries, Energy, ...],
  [*Software Replication*], [Passive Model], [Hot Copies, Warm Copies, Cold Copies],
  [*Software Replication*], [Active Model], [Coordination required],
)

- *Hot copies*: continuous updating.
- *Cold copies*: no update actions.
- *Warm copies*: some update actions, but not continuous.

=== Widespread Replication Models

Which is the FT replication model more common and widespread?
- The *Master-Slave* model is simpler and with only one execution point.
- The *Active Copies* is more complex and implies more coordination.

In any model, the cost is influenced by the *group replication degree* — the number of copies, either working or not. A search on the most common applications and more widespread ones, the *replication degree is typically very limited* (no more than a few copies).

There are also *intermediate replication models*, non-FT oriented, with a set of resources able to work independently on the same kind of operations — they operate on *different services at the same time*, and they can share the *responsibility of being a back-up of each other* (throughput driven and load balancing).

== Industrial Operations and Evolution

=== Industrial Safety Evolution

After many years, such assumptions have dictated safety rules. *Once you detect the problem it is also correcting*:

- *2016 — Fail Safe* (High Failure): Detection.
- *2018 — Fail Silent* (Flexible Failure): Reaction.
- *2020 — Fail Operational* (Intelligent Failure): Reconfiguration.
- *2030 — High Dependability* (Advanced Failure): Prediction.

#note[Modern industrial operations move from detection to prediction, with increasing levels of safety and security.]

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

In case of failover, the data must be available to the new node of the cluster via a *shared component* over the cluster. The detection of problem is via a *lightweight heartbeat protocol* — messages exchanged over both IP and non-IP networks for redundancy.

=== Storage Area Network (SAN)

#def("SAN — Storage Area Network")[
  A *set of interconnected resources with several QoS* to grant the storage service with the best suitability for different users. Users can employ SAN to get the storage resource they need without any interference and ideally without any capacity limit and with minimal delay.
]

*In Cloud*, the SAN can offer *Storage as-a-Service*.

=== Red Hat Cluster

*Red Hat Cluster suite (open source)* — a replication degree of two comprising also some shared disks to share data:

- *Cluster Infrastructure*: CMAN/DLM, Fencing, CCS.
- *HA Service Management*: rgmanager.
- *Shared Storage*: GFS and CLVM.
- *Cluster Administration tools*.
- *GNBD*.

Red Hat Cluster suite evolved a lot and is off-the-shelf. Red Hat Cluster can coexist with most widespread architectures (e.g., OpenStack: Nova, Glance, Swift, Quantum, Cinder, Keystone).

== Optimistic Lazy Policies and Eventual Consistency

=== Optimistic Lazy Policies

We use *lazy update* when one copy can answer with a little (no) coordination with other copies in an *optimistic policy that can deliver the answer very fast* — as in the case of *Amazon S3* (Amazon Simple Storage Service).

Amazon memory and persistence support *renounces to any strict consistency* and provides both *consistent* and *eventually consistent* operations.

=== Eventual Consistency

#def("Eventual Consistency")[
  *Strong consistency* has the eager update but slow answer. *Eventual consistency* (called final or tending to infinity) is a lazy update in the direction of *released consistency*: updates are commanded but not waited for.
]

So concurrent operations over other copies can see different values. On a long term, copy values are *reconciliated* and a consistent view is achieved. The *inconsistency window* may depend on many factors: communication delays, workload of the system, copy replication degree, ...

#note[(We are happy if it is *as limited as possible*.)]

=== Amazon S3 — Optimistic Lazy Policies

In the case of *Amazon S3* you can also control both the allocation for your copies and the timing of checkpointing (*SLA control*):

- You can define your data *replicated in different buckets*: in *one local bucket* and in *others* (better than on the same machine), so you can have either a copy *Same-Region Replication* (SRR — close to you) or in a distant bucket *Cross-Region Replication* (CRR).
- The user can control the location of the copies, *either close in distance or very far regions*.
- The *distant copy CRR* can in some cases overcome big crashes of an entire region, but it takes time to propagate.
- The *neighbor bucket SRR* can be fast but may be subjected to common crashes.

*S3 Replication Time Control (RTC)*: Amazon S3 lets you also control not only the location but also the timing of the operations via *S3 Replication time Control*. S3 RTC replicates most objects that you upload to Amazon S3 in seconds, and *99.99 percent of those objects within 15 minutes*.

#note[S3 RTC by default includes S3 replication metrics and S3 event notifications, so to monitor the total number of S3 API operations that are pending replication, the total size of objects pending replication, and the maximum replication time — also events that notify the bucket owner if object replication exceeds or replicates after the 15-minute threshold.]

== Docker Swarm and Modern Replication

=== Docker Swarm

#def("Docker Swarm (orchestrator)")[
  Docker Swarm proposes the feature of *loading a distributed system*: the picture is with three nodes with one manager invoked via a central console for a *portable dynamic loading*.
]

Docker Swarm can *automatically take care* of the case of failure of a node, and can *transfer some components to new or available containers* for a 'degraded' execution.

Docker Swarm can also allow *high availability* and can replicate also the *manager* for the distribution to overcome the *single point of failure of the manager*. In case of failure of *any kind of node*, it *can still operate and without interruption*.

== Apache ZooKeeper

=== ZooKeeper Overview

#def("Apache ZooKeeper")[
  ZooKeeper is a service for storing some *limited client data*, by using a *distributed replicated cluster of nodes* with excellent QoS, both *available and reliable*.
]

Design goals:
1. *Zookeeper is Simple*.
2. *Zookeeper is Replicated*.
3. *How is the Order Beneficial?*
4. *Zookeeper is Fast*.

The *Zookeeper service* is to store *very high-quality data available to all clients*. The internal architecture is based on several nodes to keep in memory data clients are interested in getting *very fast*.

Data are kept by Zookeeper server *znodes*, by using a *master/slave replication* (leader-followers).

=== ZooKeeper Architecture

Internally, *znodes organize a name space UNIX-like*. Servers implement *regular znodes* that, internally, *elect a leader*, majority voted, to control that data. Clients add *ephemeral nodes* (copies with limited lifetime dependent on client presence).

- The permanent znodes use *passive replication*. The *master is elected* and it is capable of *triggering also clients interested on the data change*.
- A simple set of primitives is available to client (Java & C) to manage data in hierarchies via API:
  - `Create` (path, data, flags) and `Delete` (path, version)
  - `getData` (path, watch)
  - `setData` (path, data, version) ...

The servers are capable of granting access to *fresh data to the group of authorized clients* via *transaction numbering*.

=== ZooKeeper Reads and Writes

Znodes create *in memory copies* of client requested data:

- The permanent znodes use *passive replication*: the master is elected and it is capable of triggering also clients interested on the data change.

The servers are capable of granting access to fresh data to the group of authorized clients via *transaction numbering*.

=== ZooKeeper Leader Election

*Replication is passive with a leader elected.* In case of leader crash, the election is based on the most recent data change among znodes (*transactionID*) via *majority voting*.

Election is also possible in case of Data Centers *partitioning* so to *work disconnected independently*.

#extra[ZooKeeper is widely used as coordination service in distributed systems — e.g., Apache Kafka uses it for broker metadata and leader election (prior to KRaft mode).]
