#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= DATA BATCHING
#extra[
  Package: Data Batching - `12 - Data_batching 24.pdf`
]

Processing #kw[Big Data] requires a fundamental *shift in mindset*: moving from small-scale, single-machine analysis toward distributed, parallel approaches designed for massive scale. The central questions are: what are the requirements of Big Data systems, and what operations must they support?

Big Data analysis settings that are #hl[very common and easy to offer as services] include:
- *Big Data storage, access and management*
- *Data batch processing*
- *Stream data processing*

Data and any service operating on it are treated *as the input* to processing pipelines.

== Big Data Characteristics and Requirements

#def("Big Data System Properties")[
  Big Data environments are characterized by *enormous data volume* and must satisfy:
  - *Distribution and Decentralization*: data lives across many nodes
  - *Scalability*: must grow with data and users
  - *Efficiency*: high throughput at low cost
  - *Quality of Service*: reliable, observable processing
]

#prop("System Requirements for Big Data Support")[
  - *Long life cycle* (tending to infinity): the system runs continuously
  - *Open source*: community-driven, no vendor lock-in
  - *Interoperability and standards*: no lock-in
  - *Remote control*: dashboard for monitoring
  - *Transparency and visibility*: black-box simplicity for users, observability for operators
]

== Batch Data Processing in Large Clusters

#why("Why Batch?")[
  It is often paramount to *automatically process a very large set of data of a specified dimension* so as to provide #hl[fast results for a search]. This is very common in big data installations. Map-Reduce batch, published in 2004, is an excellent mechanism for obtaining a *high-throughput result in a scalable, reliable, and maintainable way*.
]

*Pioneer examples - UNIX batch*: simple log analysis at system level. UNIX batch uses input as immutable and produces output on demand. Parallelism was not a primary goal in UNIX batch (data not so large).

=== Data Parallelism in Today's Large Clusters

Modern workloads exhibit *excellent data parallelism*:
- Data (e.g., web pages crawled by Google for indexing, documents) can be analyzed *independently*
- One program commonly runs on *thousands of nodes* processing enormous amounts of data

#important("The Bottleneck")[
  Unlike traditional HPC, in Big Data workloads:
  - *Communication overhead is not the dominant cost* compared to overall execution time
  - Tasks access *disks frequently* and run complex algorithms
  - #hl[Access to data and computation time dominates execution time]
  - *Data access rate can become the bottleneck*: disk I/O, not CPU, limits throughput
]

#analogy("HPC vs. Big Data")[
  Traditional HPC (High-Performance Computing) focused on raw compute parallelism with special-purpose languages. Big Data flipped the problem: the bottleneck is *getting data to compute*, not the computation itself. This is why frameworks like MapReduce emerged: to solve the data-access and distribution problem, not just the CPU parallelism problem.
]

== MapReduce: Programming Model

#def("MapReduce")[
  #kw[MapReduce] is a *programming framework* that provides a high-level API to specify parallel tasks while the runtime automatically handles:
  - Automatic parallelization and scheduling
  - Load balancing
  - Fault tolerance
  - I/O scheduling
  - Monitoring and status updates

  Everything runs on top of a *distributed file system (GFS/HDFS)*.
]

The key promise: engineers can *focus only on the application logic and parallel tasks*, without dealing with scheduling, fault-tolerance, or synchronization.

#figure(image("../assets/mapreduce-flow.svg", width: 95%), caption: "MapReduce data flow: input splits → parallel Map tasks → Shuffle & Sort (global barrier) → parallel Reduce tasks → output. Spark avoids the disk I/O bottleneck by keeping RDDs in memory across stages.")

=== Functional Language Origins

MapReduce borrows its semantics from *functional languages* (LISP, Scheme): a sequence of two complementary steps for parallel exploration and result harvesting. The same concepts appear in Python, Perl, Java, and others as built-in `map` and `reduce` functions.

#def("Map (distribution phase)")[
  1. *Input*: a list of data and one function
  2. *Execution*: the function is *applied to each list item* independently
  3. *Result*: a *new list* with all results of the function

  In the Big Data context: map processes each record to generate *intermediate key/value pairs*.
]
#v(-1em)
#def("Reduce (result harvesting phase)")[
  1. *Input*: a list and one function
  2. *Execution*: the function *combines/aggregates* the list items
  3. *Result*: *one new final item*

  In the Big Data context: reduce merges all intermediate values *associated per key*.
]

#example("Sum of Squares")[
  ```
  map(square, [1, 2, 3, 4])  => [1, 4, 9, 16]
  reduce(add, [1, 4, 9, 16]) => 30
  ```
  `map` processes each record *sequentially and independently*; `reduce` processes the *set of all records in batches*.
]

=== The Google MapReduce Definition

In the Google formulation:

- `map(String key, String val)` runs on each item in the set: input is a set of files, keys are *file names*, values are *file contents*. The function *emits (new-key, new-val) pairs*. The size of the output set can differ from the input.
- `reduce(String key, Iterator vals)` runs for each *unique key* emitted by map. It is possible to have more values for one key. Emits *final output pairs* (possibly smaller than the intermediate set).
- The runtime aggregates the output of map by key (the *shuffle and sort* phase) before calling reduce.

#note[Keys and values can have different types: the programmer converts between Strings and appropriate types inside `map()`. The runtime takes care of grouping: all values for the same key are sent to the same reducer.]

=== Map Phase in Detail

The MAP phase runs *in parallel* across a large number of records:
- Each *Map Task* processes a subset of the input data
- Each record is processed independently (*no data dependencies between records*)
- Output: intermediate `(key, value)` pairs

#example("Word Count: Map")[
  Input: `<filename, file text>` containing "Welcome Everyone / Hello Everyone"\
  Map emits: `(Welcome, 1), (Everyone, 1), (Hello, 1), (Everyone, 1)`
]

=== Reduce Phase in Detail

The REDUCE phase *merges all intermediate values per key*:
- Each key is assigned to exactly one Reduce task
- Reduce tasks run *in parallel by partitioning keys*
- Popular splitting: *hash partitioning* - reduce\# = `hash(key) % number_of_reduce_tasks`

#example("Word Count: Reduce")[
  Intermediate pairs: `(Welcome,1), (Everyone,1), (Hello,1), (Everyone,1)`\
  After reduce: `(Everyone, 2), (Hello, 1), (Welcome, 1)`
]

#important("Barrier Between Map and Reduce")[
  *Map and aggregation (shuffle+sort) must finish before Reduce can start.* This is a global barrier. The runtime aggregates intermediate values by output key, then distributes key groups to reducers. This barrier is the fundamental constraint on latency: the entire map phase must complete before results begin to emerge.
]

=== Running a MapReduce Program

The user provides a *specification object* containing:
- *Input/output file names*
- *Optional tuning parameters* (e.g., size to split input/output into)

The user defines a *MapReduce function* and passes it the specification object. The *runtime system* calls `map()` and `reduce()`: the user only specifies the operations, not the parallelization.

=== Word Count Example (Full Code)

```
map(String input_key, String input_value):
  // input_key: document name
  // input_value: document contents
  for each word w in input_value:
    Emit.Intermediate(w, "1");

reduce(String output_key, Iterator intermediate_values):
  // output_key: a word
  // output_values: a list of counts
  int result = 0;
  for each v in intermediate_values:
    result += ParseInt(v);
  Emit(AsString(result));
```

=== Other MapReduce Applications

#prop("MapReduce is General-Purpose")[
  - *Distributed grep*: map() emits a line if it matches a pattern; reduce() is an identity function
  - *Distributed sort*: map() extracts a sorting key and outputs (key, record) pairs; reduce() is identity: the actual sort is done automatically by the runtime
  - *Reverse web-link graph*: map() emits (target, source) pairs for each link to a target URL found in a source file; reduce() emits (target, list(source))
  - *Machine learning* (clustering, classification)
  - *Google news clustering*, *popular query extraction* (Zeitgeist)
  - *Processing satellite imagery data*
  - *Graph computations*, *language models for machine translation*
  - Google rewrote its *indexing code in MapReduce* (used until 2011)
]

== MapReduce Implementation and Architecture

=== Implementation at Google

- Large clusters of PCs connected with *Gigabit links*
- 4–8 GB RAM per machine, dual x86 processors
- Network bandwidth often significantly less than 1 GB/s
- *Machine failures are common* due to the large number of machines
- *GFS* (Google File System): distributed file system managing data; storage provided by cheap IDE disks attached to machines
- *Job scheduling system*: jobs composed of tasks, scheduler assigns tasks to machines
- Implementation is a C++ library linked into user programs

=== Architecture: Master and Workers

The MapReduce execution follows a *Master/Worker* (Farm) pattern:

1. User program *forks* master and worker processes
2. *Master* assigns map and reduce tasks to free workers
3. Map workers *read input splits* from GFS and write intermediate results to local disk, divided into R regions
4. Reduce workers *remotely read* intermediate data from map workers
5. Reduce workers *write final output* to GFS

#note[Input data is split into M map tasks (typically 64 MB per split). Reduce phase is partitioned into R reduce tasks. Typical values: M=200,000; R=4,000; workers=2,000.]

=== Scheduling and Execution

*Master assigns each map task to a free worker:*
- Considers *locality of data*: prefers putting map tasks on the same machine (or rack) as the input replica
- Workers read input often from *local disk*: avoids network traffic
- Intermediate key/value pairs written to *local disk*, divided into R regions; region locations passed to master

*Master assigns each reduce task to a free worker:*
- Worker reads intermediate k/v pairs from map workers via *remote read*
- Worker applies the user reduce function and stores output in *GFS*

=== Favouring Data Locality

#why("Why Data Locality Matters")[
  GFS stores data files divided into *64 MB blocks* with *3 replicas* on different machines. The master schedules map tasks *based on the location of the replicas*: placing map tasks *physically on the same machine* as one of the input replicas (or at least the same rack). This way, machines can read input at local disk speed. Otherwise, rack switches would limit read rate and waste network bandwidth.
]

=== Fault Tolerance

*On master failure:*
- State is checkpointed to GFS; new master recovers and continues

*On worker failure:* (detected via periodic heartbeats)
- *Both completed and in-progress map tasks* on that worker are re-executed (output stored on local disk: inaccessible after failure)
- Only *in-progress reduce tasks* need re-execution (completed reduce output is in GFS: globally accessible)

#prop("Robustness Example")[
  Google ran a sort program on 1800 machines and lost 1600 of them partway through: the job still completed successfully.
]

=== Backup Tasks (Stragglers)

#important("The Straggler Problem")[
  *Stragglers* (slow workers finishing last) can significantly lengthen total completion time. Causes include: other jobs consuming resources, bad disks with soft errors (slow correctable transfers), disabled processor caches at machine init.

  *Solution*: close to completion, spawn *backup copies* of the remaining in-progress tasks. Whichever copy finishes first wins. Additional cost: a few percent more resource usage. Result: a sort program *without backup tasks was 44% longer*.
]

== Hadoop: The Open-Source MapReduce

#def("Apache Hadoop")[
  #kw[Hadoop] is an *open source platform for MapReduce by Apache*. It started as open source MapReduce written in Java but evolved to support other Apache languages such as Pig and Hive.
]

Core subprojects:
- *Hadoop Common*: set of utilities (FileSystem, RPC, serialization libraries)
- *HDFS* (Hadoop Distributed File System)
- *MapReduce*: the processing engine
- *YARN* (Yet Another Resource Negotiator): cluster resource management

=== YARN Resource Manager

#def("YARN")[
  #kw[YARN] (Yet Another Resource Negotiator) provides *management for virtual Hadoop clusters over a large physical cluster*. It treats each server as a collection of *containers*, where a container = fixed CPU + fixed memory (think Linux cgroups but even lighter).
]

YARN responsibilities:
- Handles *node allocation* in a cluster
- Supplies new nodes with configuration
- Distributes Hadoop to allocated nodes
- Starts Map/Reduce and HDFS workers
- Includes management and monitoring

Other resource managers are available, such as *Apache MESOS*.

=== YARN Architecture

YARN has three main components:

1. *Global Resource Manager (GRM)*: single node that:
   - Globally allocates the required resources
   - Contains the *Scheduler* and *ApplicationsManager*

2. *Application Master (AM)*: per-application (per job):
   - Container negotiation with Resource Manager and Node Managers
   - Detecting task failures for that job

3. *Per-server Node Manager (NM)*:
   - Daemon with server-specific functions that manage local resources
   - Instantiates containers to run tasks
   - Monitors container resource usage

=== YARN Workflow

A typical YARN job submission follows these steps:
1. Client submits job (copies job resources to HDFS)
2. Client requests application from Resource Manager
3. Resource Manager requests container for Application Master
4. Node Manager starts Application Master
5. AM retrieves input data from HDFS
6. AM requests resource allocation from Scheduler
7. Node Manager starts container with Map/Reduce task
8. Task retrieves job resources from HDFS
9. Results stored back to HDFS

#extra[
  Hadoop extensions (out of primary scope): *Avro* (serialization), *Chukwa* (log collection), *HBase* (structured data storage for large tables), *Hive* (data warehousing, Facebook), *Pig* (parallel SQL-like, Yahoo), *ZooKeeper* (coordination), *Mahout* (ML/data mining), *Sahara* (deployment on OpenStack).
]

=== Hadoop on OpenStack (Sahara)

Hadoop can exploit *OpenStack virtualization* for more flexible clusters and better resource utilization. OpenStack's *Sahara* service allows deploying and configuring Hadoop clusters in a Cloud environment, adding:
- *Cluster scaling functions*
- *Analytics as a Service (AaaS)* functions

Sahara is accessible via dashboard, CLI, or RESTful API.

== Apache Spark

=== Why Spark?

MapReduce greatly simplified Big Data analysis, but as it became popular, users wanted more:
- *More complex, multi-stage applications* (e.g., iterative graph algorithms and machine learning): MapReduce chains require writing intermediate results to disk between every job
- *More interactive ad-hoc queries*

Both multi-stage and interactive apps require faster *data sharing across parallel jobs*. MapReduce's answer was writing to HDFS: slow due to replication, serialization, and disk I/O.

#important("MapReduce Data Sharing Problem")[
  In MapReduce: iterative jobs require HDFS read → process → HDFS write → HDFS read → process → ... for every iteration. Interactive queries each need a fresh HDFS read. Both are *slow due to replication, serialization, and disk I/O*. This is the fundamental bottleneck MapReduce cannot solve.
]
#v(-1em)
#def("Apache Spark")[
  #kw[Spark] is *not a modified version of Hadoop* but a separate, fast, MapReduce-like engine. It is a *new optimized version of Hadoop* that provides:
  - *In-memory data storage* for very fast iterative queries
  - *General execution* of graphs and powerful optimizations
  - Up to *40× faster than Hadoop* for iterative workloads
  - Compatible with Hadoop storage APIs (HDFS, HBase, SequenceFiles, etc.)
]
#v(-1em)
#analogy("Spark vs. Hadoop Data Sharing")[
  Hadoop is like passing notes by printing them, distributing copies, collecting them, shredding them, and printing new ones for each step. Spark keeps the notes *in RAM*, passing them directly between steps. First read from disk is unavoidable, but subsequent iterations are 10–100× faster.
]

=== Spark Basics

Spark offers various types of data processing computations in *one single tool*:
- *Batch/streaming* analysis, *interactive* queries, and *iterative* algorithms
- Previously these required several different and independent tools

Supports *several storage options and streaming inputs* for parsing. APIs available in *Java, Scala, Python, R*.

=== Resilient Distributed Datasets (RDDs)

The key data abstraction in Spark is the #kw[RDD]:

#def("Resilient Distributed Dataset (RDD)")[
  An #kw[RDD] is a *distributed, immutable collection of objects* that is:
  - Maintained *in memory* (when possible)
  - *Distributed* across cluster nodes
  - *Immutable*: transformations create new RDDs, not modified ones
  - *Can be cached in memory* across cluster nodes for reuse

  RDDs achieve fault tolerance through *lineage* rather than replication.
]

=== RDD Operations

Two kinds of operations on RDDs:

#prop("Transformations (lazy)")[
  Act on existing RDDs by *creating new ones*. Similar to Hadoop map tasks. *Lazily evaluated*: no computation happens until an action is triggered. Examples: `map`, `filter`, `groupBy`, `sort`, `join`, `union`, `reduceByKey`, `groupByKey`, `partitionBy`, `cogroup`, `cross`, `leftOuterJoin`, `rightOuterJoin`, `sample`.
]
#v(-1em)
#prop("Actions (eager)")[
  *Return results* from input RDDs. Similar to Hadoop reduce tasks. *Force immediate evaluation* of all pending transformations in the input RDD. Examples: `reduce`, `count`, `first`, `take`, `save`, `pipe`.
]

#example("Lazy Evaluation")[
  ```scala
  val lines = sc.textFile("data.txt")          // Transformation
  val lineLengths = lines.map(s => s.length)   // Transformation
  val totalLength = lineLengths.reduce((a, b) => a + b)  // Action
  ```
  Until the third line (the action), *no operation is performed*. The `reduce()` action forces a read from the text file and the `map()` transformation.
]

=== Persisting RDDs

By default, all transformations are recomputed on *every action requested*. This can be expensive. Using the `persist()` method, the RDD data (read and mapped) is *saved for future actions*:

```scala
val lines = sc.textFile("data.txt")
val lineLengths = lines.map(s => s.length)
lineLengths.persist()
```

#note[Persisting is the key to Spark's speed advantage for iterative algorithms: load data once into memory, then iterate over it many times without re-reading from disk.]

=== Fault Tolerance via Lineage

#def("RDD Lineage")[
  RDDs track the *series of transformations used to build them* (their #kw[lineage]) to re-compute lost data. If a partition is lost (node crash), Spark recomputes only that partition from the original source using the lineage graph: without needing to replicate all data.
]

#example("Lineage Graph")[
  ```
  messages = textFile(...).filter(_.contains("error"))
                          .map(_.split('\t')(2))
  ```
  Lineage: `HadoopRDD (path=hdfs://...)` ← `FilteredRDD (func=_.contains(...))` ← `MappedRDD (func=_.split(...))`

  If MappedRDD is lost, Spark retraces from HadoopRDD.
]

=== Spark Performance: Why It Wins on Iterative Workloads

#example("Logistic Regression: Spark vs. Hadoop")[
  Iterative ML algorithm (gradient descent):
  ```scala
  val data = spark.textFile(...).map(readPoint).cache()
  var w = Vector.random(D)
  for (i <- 1 to ITERATIONS) {
    val gradient = data.map(p =>
      (1 / (1 + exp(-p.y*(w dot p.x))) - 1) * p.y * p.x
    ).reduce(_ + _)
    w -= gradient
  }
  ```
  Data is loaded once and cached. Each iteration reuses the in-memory RDD.\
  *Results*: Hadoop ~127s/iteration; Spark ~174s first iteration (loading), then *~6s for further iterations*: 20× speedup at 30 iterations.
]

#extra[
  PageRank performance: Hadoop 171s/iteration, Basic Spark 72s/iteration, Spark + Controlled Partitioning *23s/iteration*. Controlled data partitioning avoids unnecessary shuffling by keeping related data co-located across iterations.
]

=== Other Spark Engine Features

- *General graphs of operators* (e.g., map-reduce-reduce chains), not just two-phase pipelines
- *Hash-based reduces*: faster than Hadoop's sort-based approach
- *Controlled data partitioning* adapted to lower communication overhead

=== Spark Architecture

#def("Spark Architecture")[
  Spark programs create *Directed Acyclic Graphs (DAGs)* of all transformations and actions, internally optimized for execution. The graph is split into *stages*, composed by *tasks* (the smallest unit of work).

  The support is a *master/slave system*:
  - *Driver*: central coordinator node running the `main()` method of the program, dispatching tasks
  - *Cluster Master*: launches and manages actual executors
  - *Executors*: responsible for running tasks; each spawns at least one dedicated JVM with an assigned share of CPU threads and RAM memory
]

=== Spark Deployment Modes

Spark can be deployed:
- *Standalone cluster*: its own cluster master independently launches and manages executors
- *Hadoop YARN*: relies on YARN for resource management (already seen above)
- *Apache MESOS*: fine-grained sharing, richer scheduling queues

External resource managers provide richer functionalities (scheduling queues, multi-tenancy) not available in standalone mode.

=== Spark Provisioning and Output

Spark can produce *very large results*. Managing large aggregations (e.g., document at a URL) requires automation. The experience points toward storing produced batch data in *NoSQL repositories* for scalable access.

== The Big Data Tools Ecosystem

The Big Data processing landscape organizes along two dimensions: the *computational model* and the *use case*:

#table(
  columns: (auto, 1fr, 1fr, 1fr, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 0.7em,
  table.header(
    [*Use Case*], [*DAG Model*], [*MapReduce Model*], [*Graph Model*], [*BSP/Collective*],
  ),
  [*Iterations / Learning*], [Spark, Dryad/DryadLINQ], [Hadoop, HaLoop, Twister, Spark], [Giraph, GraphLab, GraphX, Hama], [MPI, Harp],
  [*Query*], [Drill, Dryad], [Pig/PigLatin, Hive, Tez, Shark, MRQL], [-], [-],
  [*Streaming*], [S4, Samza], [Storm, Spark Streaming], [-], [-],
)

#extra[
  A layered architecture view shows these tools sitting above distributed file systems (HDFS), resource managers (YARN, MESOS), and cloud infrastructure (OpenStack, AWS, Azure), with cross-cutting capabilities like in-memory databases, NoSQL stores, ORM/mapping, and DevOps/deployment tooling.
]

== Big Data Resource Analysis

=== Resources as Unifying Concepts

All Big Data systems ultimately deal with the same *resource management issues*, categorized by when they must be handled:

*Runtime issues (dynamic, in-band):*
- *Resource Sharing* (multicast)
- *Resource Distribution* (events)
- *Resource Synchronization*
- *Resource Replication*
- *Resource Control*

*Static issues (before runtime):*
- *Resource Configuration*
- *Resource Timing*

=== IT Properties Required

For Big Data and cloud systems to function reliably at scale, the following technical properties are required:
- *Dynamicity and adaptability*: systems must react to changing conditions
- *Fault tolerance or Replication*: availability and reliability
- *Loose Consistency*: CAP theorem trade-offs accepted for scale
- *Group communication*: coordinating many nodes
- *Data configuration and access*
- *Resource life cycle support*

And cross-cutting concerns:
- *Transparency*: hide distribution complexity from users
- *Low intrusion*: management overhead must be minimal
- *Time awareness*: event ordering, timeouts, expiry
- *Simplicity*: the dominant design goal; complexity kills adoption

#important("The MapReduce/Spark Lesson")[
  The success of MapReduce and Spark is not just about performance: it is about *abstraction and simplicity*. By hiding fault tolerance, scheduling, data movement, and parallelism behind a clean API, these frameworks allow engineers to write Big Data programs without expertise in distributed systems. The internal complexity is real; the user-visible model is not.
]
