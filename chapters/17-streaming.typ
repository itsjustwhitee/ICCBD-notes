#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= STREAM PROCESSING
#extra[
  Package: Stream Processing - `streaming.pdf`
]

Modern data-intensive applications must react to data *as it arrives*, not after collecting it all. #kw[Stream processing] is the paradigm of continuously processing data of *unbounded* and *undefined* dimension, with contracts of high throughput and low latency: and it must *automate everything* to achieve special-purpose behavior at scale.

#def("Stream Processing")[
  #kw[Stream processing] is the continuous processing of data that arrives in an *unbounded*, potentially infinite sequence of records, where results must be produced with *real-time constraints* (typically latencies of a few seconds), without waiting for a finite dataset to accumulate.
]

== Motivation and Challenges

=== Why Streaming?

Large amounts of data arrive continuously and demand *real-time views*:

- *Social network trends*: e.g., Twitter real-time search
- *Website analytics*: e.g., Google Analytics dashboards
- *Intrusion detection systems*: e.g., in most data centers

These use cases share a common requirement: #hl[process contents of data with some time constraints]: with latencies of a few seconds and high throughput; and there is *no viable way to use databases for storing* the stream before processing it.

=== Why Not MapReduce / Batch?

#important("Batch is Not Suitable for Streaming")[
  The standard batch (MapReduce) workflow is *out-of-line*: it requires waiting for the entire computation on a large dataset to complete before producing results. *Batch approaches are not suitable for long-running, unbounded stream-processing*: the stream never ends, so the batch job never starts.
]
#v(-1em)
#analogy("The Assembly Line")[
  Batch processing is like a factory that waits until a full truck of parts arrives before starting the assembly line. Stream processing is like a conveyor belt: parts are processed *one by one as they arrive*, and finished products flow out the other end continuously. There is no "wait for everything."
]

Instead, stream processing uses *message-passing dataflows*: data flows between processing components via asynchronous, MOM-like (Message-Oriented Middleware) channels.

=== Problems with Message-Passing Dataflows

Switching to asynchronous dataflows introduces new problems:

- *Velocity mismatch* between output and input rates #arrow *buffering in a queue* (cost / possible overflow)
- *Node crashes* during processing #arrow *use replication and multiple copies* for fault tolerance
- *Dynamic intervention* while online #arrow *change the graph while provisioning* is live

== The Stream Processing Model

#def("Stream Processing Model")[
  A stream processing system manages three concerns: *allocation* (where operators run), *synchronization* (how operators coordinate on shared state), and *communication* (how data flows between operators). It is organized as a *dataflow graph*: a directed graph of processing operators (kernels) connected by data channels.
]

The dataflow graph receives inputs from an external source (e.g., sensor feeds, message queues) and passes them through a network of #kw[kernels] (operators) that filter, transform, aggregate, and route records.

Applications that benefit most from the streaming model are those with:
- *High computation resource intensity*
- *Data parallelization* potential
- *Data-time locality* requirements (results must be fresh)

=== Support Functions

A stream processing framework must provide:
- *Resource allocation*: place operators onto compute nodes
- *Data classification*: route records to the correct operator
- *Information routing in flows*: manage the dataflow topology
- *Management of execution/processing status*: track progress, state, and failures

#extra[Apache Storm was one of the early influential systems: scalable, fault-tolerant, processing over a million data tuples per second per node, and respecting SLAs over data to be processed.]

== Spark Streaming

#def("Spark Streaming")[
  #kw[Spark Streaming] is an extension of Apache Spark for large-scale stream processing. It scales to hundreds of nodes, achieves second-scale latencies, and integrates batch and stream processing in a single unified system by reusing Spark's batch engine via *micro-batching*.
]

It can absorb live data streams from Kafka, Flume, HDFS/S3, Kinesis, Twitter, ZeroMQ, and others; and outputs to HDFS, databases, or dashboards.

=== Discretized Stream Processing

The core idea behind Spark Streaming is *discretization*: instead of processing each record individually, #hl[run a streaming computation as a series of very small, deterministic batch jobs].

#prop("Discretized Stream Processing")[
  - Chop the live stream into *batches of X seconds*
  - Spark treats each batch as an *RDD* and processes it using standard Spark batch operations
  - Processed results of the RDD operations are returned in batches
  - Batch sizes can be as small as *½ second*, yielding latency of ~1 second
  - This enables combining batch and streaming processing in the *same system*
]
#v(-1em)
#analogy("Film Frames")[
  A cinema projects 24 still frames per second: your eye perceives smooth motion. Spark Streaming takes a continuous stream and "samples" it into mini-batches at fixed intervals, giving the illusion of real-time processing while reusing the well-understood batch machinery underneath.
]

=== DStream: The Core Abstraction

#def("DStream (Discretized Stream)")[
  A #kw[DStream] is a *sequence of RDDs* representing a stream of data. Each RDD in the DStream contains records from a time interval. DStreams are the primary abstraction in Spark Streaming: sources, transformations, and output operations all operate on DStreams.
]

Sources include: Twitter, HDFS, Kafka, Flume, ZeroMQ, Akka Actor, TCP sockets.

=== DStream Operations

There are three kinds of operations on DStreams:

- *Transformations*: modify data in one DStream to create another DStream:
  - Standard RDD operations: `map`, `countByValue`, `reduce`, `join`, ...
  - Stateful operations: `window`, `countByValueAndWindow`, ...
- *Output operations*: send data to an external entity:
  - `saveAsHadoopFiles`: saves every batch to HDFS
  - `foreach`: do anything with each batch of results

#example("Get Hashtags from Twitter")[
  ```scala
  val tweets = ssc.twitterStream(<username>, <password>)
  val hashTags = tweets.flatMap(status => getTags(status))
  hashTags.saveAsHadoopFiles("hdfs://...")
  ```
  Each time interval produces a new batch from the Twitter API. The `flatMap` transformation applies to each batch's RDD in turn, creating a new `hashTags` DStream. The output operation saves every batch to HDFS.
]

=== Fault Tolerance in Spark Streaming

#prop("Spark Streaming Fault Tolerance")[
  RDDs *remember the sequence of operations* (lineage) that created them from the original fault-tolerant input data.
  - Batches of input data are *replicated in memory* across multiple worker nodes
  - Data lost due to worker failure can be *recomputed from input data* using the lineage
  - Lost partitions are recomputed on other workers automatically
]

This is exactly the same RDD fault-tolerance mechanism as in batch Spark: micro-batching means the fault recovery model is inherited for free.

=== Requirements Summary

For a streaming system to be production-grade:
- *Scalable* to large clusters
- *Second-scale* latencies
- *Simple* programming model
- *Integrated* with batch and interactive processing
- #hl[*Efficient fault-tolerance* in stateful computations]: the hardest requirement

The last point is critical: traditional streaming systems use an *event-driven record-at-a-time* model where each node has mutable state. If a node dies, that state is lost, and making stateful stream processing fault-tolerant is fundamentally challenging.

== Apache Flink

#def("Apache Flink")[
  #kw[Apache Flink] is an open-source framework for *stateful stream and batch processing*, built for low latency and high throughput. Unlike Spark Streaming, Flink performs *true stream processing*: it processes events one at a time as they arrive, without micro-batching.
]

=== Core Features

- *True stream processing*: not micro-batching; each event is processed immediately
- *Stateful computations* with fault tolerance via *exactly-once guarantees*
- *Event-time processing* and *windowing*
- High scalability and performance

#why("True Streaming vs. Micro-batching")[
  Spark Streaming achieves ~1 second latency (bounded by batch interval). Flink targets *sub-second latencies* because it does not wait for a batch window to close: operators push data forward as soon as it arrives. The trade-off: Flink's stateful fault tolerance is more complex to implement, since there is no natural "checkpoint boundary" at batch edges.
]

=== Flink Architecture

The Flink runtime consists of two types of processes:

- *JobManager*: the master process (at least one is always present)
- *TaskManagers*: the worker processes (one or more)

==== JobManager

The #kw[JobManager] coordinates distributed execution. It has three sub-components:

- *ResourceManager*: manages resource allocation/deallocation and controls *task slots* (the unit of scheduling). Supports YARN, Kubernetes, and Standalone deployments. In standalone mode, cannot start new TaskManagers; it only distributes existing slots.
- *Dispatcher*: provides a REST interface for job submission, starts a new JobMaster for each job, and hosts the Flink Web UI for monitoring.
- *JobMaster*: manages execution of a single *JobGraph*. One JobMaster per job; multiple jobs can run concurrently in a cluster.

For *high availability*: multiple JobManagers can exist; one is the leader, the rest are standby.

==== TaskManager

#def("TaskManager")[
  A #kw[TaskManager] (also called a worker) executes the tasks of a dataflow and buffers/exchanges data streams between tasks. Each TaskManager exposes a set of *task slots*: fixed subsets of its managed resources (memory).
]

A TaskManager with three slots, for example, dedicates 1/3 of its managed memory to each slot. Tasks running in different slots share the JVM but are isolated in terms of memory.

==== Task Slots and Chains

Flink *chains* operator subtasks together into *tasks*. Each task is executed by one thread. This chaining reduces:
- Thread-to-thread handover overhead
- Buffering between operators

Chaining increases overall throughput while decreasing latency: operators in the same chain communicate via method calls rather than network buffers.

=== Pipelining

#def("Pipelining in Flink")[
  #kw[Pipelining] is the basic building block to "keep the data moving." Operators push data forward immediately; data is shipped as *buffers*, not tuple-by-tuple. The entire pipeline runs *online and concurrently*, giving low latency and natural handling of *back-pressure* (if a downstream operator is slow, upstream buffers fill and the producer slows down automatically).
]
#v(-1em)
#analogy("Factory Production Line")[
  A pipelined factory does not wait for the entire car to be painted before sending it to the next station. Each station works on whatever arrives, and the finished products flow out continuously. Back-pressure is natural: if the painting station is slow, the queue in front of it fills up and the welding station slows down.
]

== Streaming Semantics and Fault Tolerance

=== Processing Guarantees

A critical design decision for any streaming system is *what happens to records on failure*:

#table(
  columns: (auto, 1fr, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header(
    [*Guarantee*], [*Meaning*], [*How achieved*],
  ),
  [*At-least-once*], [All operators see all events (but may see some events *more than once*).], [Storm: replay the stream on failure. Simple but can cause duplicate state updates.],
  [*Exactly-once*], [Operators do not perform duplicate updates to their state: every event is processed *exactly once* even under failures.], [Flink: Distributed Snapshots. Spark: micro-batches on batch runtime (inherits batch atomicity).],
)

#important("Exactly-once is the Gold Standard")[
  Exactly-once semantics is the hardest guarantee to achieve in streaming. It is important especially for stateful computations such as counting, summing, or updating a database: duplicate processing would corrupt the result. Both Flink and Spark Streaming offer exactly-once, but through fundamentally different mechanisms.
]

=== Flink's Distributed Snapshots

Flink achieves exactly-once via a *lightweight, non-blocking snapshot algorithm*: the state of all operators is captured periodically *without pausing execution*, targeting high throughput and low latency.

#def("Distributed Snapshot (Flink)")[
  A #kw[distributed snapshot] in Flink captures a globally consistent state of the entire streaming topology by injecting special *barrier* markers into the data streams. Barriers flow through the topology alongside regular data records, separating the stream into "before snapshot" and "after snapshot" portions.
]

The mechanism uses four steps:

1. *Master initiates a checkpoint*: the JobManager emits stream barriers from all sources, recording the current source positions (e.g., Kafka offset = 162).
2. *Barriers flow downstream*: when an operator receives a barrier on all inputs, it *writes a snapshot of its state* to persistent storage (state backend) and forwards the barrier.
3. *State is acknowledged*: operators report completion to the Master, which records the checkpoint data (source positions + operator states).
4. *Sink acknowledges*: when the sink receives barriers on all inputs, the checkpoint is complete: the system has a consistent global snapshot.

#prop("Properties of Flink Snapshots")[
  - *Non-blocking*: regular data records continue to flow through operators while snapshot is in progress
  - *Incremental*: only changed state needs to be written
  - *Recovery*: on failure, the entire topology is reset to the last successful snapshot, and sources replay from recorded positions
  - *Back-pressure aware*: barriers naturally align with data flow rates
]
#v(-1em)
#example("Barrier Alignment")[
  A Kafka consumer is at offset 162. A counter operator has value 152. A barrier is injected:
  - Records *before* the barrier #arrow part of this snapshot (counted)
  - Records *after* the barrier #arrow belong to the *next* snapshot (backed up until the next checkpoint completes)
  - The snapshot stores: `{Kafka offset: 162, counter: 152}`
  - On crash and recovery, processing resumes from offset 162, counter reset to 152
]

== Comparison: Spark Streaming vs. Flink

#figure(image("../assets/flink-streaming.svg", width: 95%), caption: "Spark Streaming (micro-batch: stream chopped into RDD batches every ~1 s) vs Apache Flink (true event-at-a-time pipeline with barrier-based checkpointing for exactly-once semantics).")

#table(
  columns: (auto, 1fr, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header(
    [*Aspect*], [*Spark Streaming*], [*Apache Flink*],
  ),
  [*Processing model*], [Micro-batching (discretized streams)], [True event-at-a-time streaming],
  [*Latency*], [~1 second (batch interval)], [Sub-second (milliseconds)],
  [*Fault tolerance*], [RDD lineage + replication], [Distributed snapshots (barriers)],
  [*Exactly-once*], [Yes: inherits from batch RDD model], [Yes: via distributed snapshots],
  [*Batch integration*], [Natural: same engine], [Supported but separate path],
  [*State management*], [Limited (stateful ops on DStreams)], [Rich, first-class operator state],
)

#note[
  The fundamental trade-off: Spark Streaming is *simpler* to reason about (batch semantics) and integrates naturally with the Spark ecosystem. Flink achieves *lower latency* and richer stateful processing but at the cost of more complex internals. For latency requirements of seconds, both work; for sub-second requirements, Flink is the right choice.
]
