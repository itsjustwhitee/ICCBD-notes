#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= DATA BATCHING
#extra[
  Package: Data Batching - `12 - Data_batching 24.pdf`
]

Processing #kw[Big Data] requires a fundamental *shift in mindset*: moving from small-scale, single-machine analysis toward distributed, parallel approaches designed for massive scale. The central questions are: _what are the requirements of Big Data systems, and what operations must they support?_

Big Data analysis settings that are #hl[very common and easy to offer as services] include:
- *Big Data storage, access and management*
- *Data batch processing*
- *Stream data processing*

Data and any service operating on it are treated *as the input* to processing pipelines.

== Big Data Characteristics and Requirements

#def("Big Data System Properties")[
  Big Data environments are characterized by *enormous data volume* and must satisfy:
  - *Distribution and Decentralization*: data lives across many nodes.
  - *Scalability*: must grow with data and users.
  - *Efficiency*: high throughput at low cost.
  - *Quality of Service*: reliable, observable processing.
]

#prop("System Requirements for Big Data Support")[
  - *Long life cycle* (tending to infinity): the system runs continuously.
  - *Open source*: community-driven, no vendor lock-in.
  - *Interoperability and standards*: no lock-in.
  - *Remote control*: dashboard for monitoring.
  - *Transparency and visibility*: black-box simplicity for users, observability for operators.
]

== Batch Data Processing in Large Clusters

#why("Batch")[
  It is often paramount to *automatically process a very large set of data of a specified dimension* so as to provide #hl[fast results for a search]. This is very common in big data installations. Map-Reduce batch, published in 2004, is an excellent mechanism for obtaining a *high-throughput result in a scalable, reliable, and maintainable way*.
]

*Pioneer examples - UNIX batch*: simple log analysis at system level. UNIX batch uses input as immutable and produces output on demand. Parallelism was not a primary goal in UNIX batch (data not so large).

=== Data Parallelism in Today's Large Clusters

Modern workloads exhibit *excellent data parallelism*:
- Data (e.g., web pages crawled by Google for indexing, documents) can be analyzed *independently*.
- One program commonly runs on *thousands of nodes* processing enormous amounts of data.

#important("The Bottleneck")[
  Unlike traditional HPC, in Big Data workloads:
  - *Communication overhead is not the dominant cost* compared to overall execution time.
  - Tasks access *disks frequently* and run complex algorithms.
  - #hl[Access to data and computation time dominates execution time].
  - *Data access rate can become the bottleneck*: disk I/O, not CPU, limits throughput.
]
#v(-1em)
#analogy("HPC vs. Big Data")[
  Traditional HPC (High-Performance Computing) focused on raw compute parallelism with special-purpose languages. Big Data flipped the problem: the bottleneck is *getting data to compute*, not the computation itself. This is why frameworks like MapReduce emerged: to solve the data-access and distribution problem, not just the CPU parallelism problem.
]

== MapReduce: Programming Model

#def("MapReduce")[
  #kw[MapReduce] is a *programming model* for batch processing of huge datasets. You write only *two functions*, `map` and `reduce`, that both work on *(key, value) pairs*. The runtime does everything else: *parallelization and scheduling*, *load balancing*, *fault tolerance*, *I/O scheduling*, and *monitoring*, all on top of a *distributed file system (GFS/HDFS)*.
]

So the engineer writes only the *logic* of `map` and `reduce` and never touches distribution, faults, or synchronization. Every job follows the *same fixed pipeline*:

#align(center)[*input* #arrow *map* (per record) #arrow intermediate (k, v) #arrow *shuffle & sort* (group by key) #arrow *reduce* (per key) #arrow *output*]

#figure(image("../assets/map-reduce.jpg", width: 55%), caption: "MapReduce data flow.")

=== The Two Functions

#def("map and reduce")[
  - #hl[`map(k1, v1)` produces a list of `(k2, v2)`]: called *once per input record*, it turns that record into *zero or more* intermediate key/value pairs.
  - In between, the runtime runs *shuffle & sort*: it *groups all intermediate pairs by key*, so each distinct key ends up with the *full list* of its values.
  - #hl[`reduce(k2, list(v2))` produces a list of `(k3, v3)`]: called *once per distinct key*, with *all* the values collected for that key, it aggregates them into the final result.
]
#v(-1em)
#note[
  Map processes records *independently* (no dependency between them), so it parallelizes trivially. Reduce runs *per key*, and the keys are spread across reducers by *hash partitioning* (`reduce# = hash(k2) % R`). Keys and values may have any type, parsed by the programmer inside the functions.
]

=== Functional Origins

The names come from *functional languages* (LISP, Scheme), where `map` applies a function to every element of a list and `reduce` (a *fold*) collapses a list into a single result. MapReduce keeps that idea but adds the *group-by-key* step in the middle, so its `reduce` runs *once per key* over that key's values, not once over the whole dataset.
#v(-0.7em)
#example("map / reduce on a plain list")[
  ```
  map(square, [1, 2, 3, 4])  => [1, 4, 9, 16]
  reduce(add,  [1, 4, 9, 16]) => 30
  ```
]

=== End-to-End Example: Word Count

#example("Word Count")[
  *Goal*: count how often each word appears across many documents. Input records are `<doc name, text>`. Say two documents hold "Welcome Everyone" and "Hello Everyone".
  + *Map* emits `(word, 1)` for each word: `(Welcome,1) (Everyone,1) (Hello,1) (Everyone,1)`
  + *Shuffle & sort* groups by key: `(Everyone,[1,1]) (Hello,[1]) (Welcome,[1])`
  + *Reduce* sums each list: `(Everyone,2) (Hello,1) (Welcome,1)`
]
#v(-1em)
#important("The Barrier Between Map and Reduce")[
  A reduce on a key needs *all* of that key's values, so *the entire map phase and the shuffle & sort must finish before any reduce can start*. This *global barrier* is the model's main latency limit: no output appears until every map task is done. (Spark later avoids paying this cost on disk by keeping data in memory between stages.)
]

=== Running a MapReduce Program

The user passes a *specification object* with the *input/output file names* and *optional tuning parameters* (e.g. the split size). The *runtime* then calls `map()` and `reduce()` for you: you specify *what* to compute, not *how* to parallelize it.

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

- Large clusters of PCs connected with *Gigabit links*.
- 4–8 GB RAM per machine, dual x86 processors.
- Network bandwidth often significantly less than 1 GB/s.
- *Machine failures are common* due to the large number of machines.
- *GFS* (Google File System): distributed file system managing data; storage provided by cheap IDE disks attached to machines.
- *Job scheduling system*: jobs composed of tasks, scheduler assigns tasks to machines.
- Implementation is a C++ library linked into user programs.

=== Architecture: Master and Workers

A *job* is one run of a MapReduce program (e.g. "count the words in this corpus"). Running a job follows a *Master/Worker* (Farm) pattern:

1. The framework launches *many copies of the same user binary* across the cluster. *One* copy becomes the *master* (the coordinator), all the others are *workers*. This happens *once per job*, not per task.
2. The job is divided into *M map tasks* and *R reduce tasks*. The *master* hands these tasks out to *free workers*, one at a time, reusing each worker for many tasks over the job's life.
3. A *map worker* reads its input split from GFS, runs `map`, and writes the intermediate pairs to its *local disk*, split into R regions.
4. A *reduce worker* *remotely reads* its region from every map worker, runs `reduce`, and writes the final output to GFS.

#note[
  Keep the *three levels* straight. A *job* (one program run) has *one master* and a *pool of workers*. That job is split into *M map + R reduce tasks*, with M and R far larger than the worker count (typically M = 200,000, R = 4,000, workers = 2,000, each map split ~64 MB). A *task* is just a unit of work the master assigns to a worker, it never starts a master of its own.
]

#figure(
  image("../assets/map-reduce-architecture.jpg", width: 50%),
  caption: [Map reduce architecture (master/worker).]
)

=== Scheduling and Execution

*Master assigns each map task to a free worker:*
- Considers *locality of data* #swarrow prefers putting map tasks on the same machine (or rack) as the input replica.
- Workers read input often from *local disk* #swarrow avoids network traffic.
- Intermediate key/value pairs written to *local disk*, divided into R regions; region locations passed to master.

*Master assigns each reduce task to a free worker:*
- Worker reads intermediate k/v pairs from map workers via *remote read*
- Worker applies the user reduce function and stores output in *GFS*

=== Favouring Data Locality

#why("Data Locality Matters")[
  GFS stores data files divided into *64 MB blocks* with *3 replicas* on different machines. The master schedules map tasks *based on the location of the replicas*: placing map tasks *physically on the same machine* as one of the input replicas (or at least the same rack). This way, machines can read input at local disk speed. Otherwise, rack switches would limit read rate and waste network bandwidth.
]

=== Fault Tolerance

*On master failure:*
- State is checkpointed (periodically) to GFS; new master recovers and continues.

*On worker failure:* (detected via periodic heartbeats)
- *Both completed and in-progress map tasks* on that worker are re-executed (output stored on local disk: inaccessible after failure).
- Only *in-progress reduce tasks* need re-execution (completed reduce output is in GFS: globally accessible).

#extra[#prop("Robustness Example")[
  Google ran a sort program on 1800 machines and lost 1600 of them partway through: the job still completed successfully.
]]

=== Backup Tasks (Stragglers)

#important("The Straggler Problem")[
  *Stragglers* (slow workers finishing last) can significantly lengthen total completion time. Causes include: other jobs consuming resources, bad disks with soft errors (slow correctable transfers), disabled processor caches at machine init.

  *Solution*: close to completion, spawn *backup copies* of the remaining in-progress tasks. Whichever copy finishes first wins.\
  Additional cost: a few percent more resource usage.\
  Result: a sort program *without backup tasks was 44% longer*.
]

== Hadoop: The Open-Source MapReduce

#def("Apache Hadoop")[
  #kw[Hadoop] is an *open source platform for MapReduce by Apache*. It started as open source MapReduce written in *Java* but evolved to support other Apache languages such as Pig and Hive.
]

Core subprojects:
- *Hadoop Common*: set of utilities (FileSystem, RPC, serialization libraries).
- *HDFS* (Hadoop Distributed File System).
- *MapReduce*: the processing engine.
- *YARN* (Yet Another Resource Negotiator): cluster resource management.

=== YARN Resource Manager

#def("YARN")[
  #kw[YARN] (Yet Another Resource Negotiator) provides *management for virtual Hadoop clusters over a large physical cluster*. It treats each server as a collection of *containers*, where a container = fixed CPU + fixed memory (think Linux cgroups but even lighter).
]

YARN responsibilities:
- Handles *node allocation* in a cluster.
- Supplies new nodes with configuration.
- Distributes Hadoop to allocated nodes.
- Starts Map/Reduce and HDFS workers.
- Includes management and monitoring.

Other resource managers are available, such as *Apache MESOS*.

=== YARN Architecture

YARN has three main components:

1. *Global Resource Manager (GRM)*: single node that:
   - Globally allocates the required resources.
   - Contains the *Scheduler* and *ApplicationsManager*.

2. *Application Master (AM)*: per-application (per job):
   - Container negotiation with Resource Manager and Node Managers.
   - Detecting task failures for that job.

3. *Per-server Node Manager (NM)*:
   - Daemon with server-specific functions that manage local resources.
   - Instantiates containers to run tasks.
   - Monitors container resource usage.

#figure(
  image("../assets/yarn.jpg",width: 70%),
  caption: [YARN architecture and flow.]
)

=== YARN Workflow

A typical YARN job submission follows these steps:
1. Client submits job (copies job resources to HDFS).
2. Client requests application from Resource Manager.
3. Resource Manager requests container for Application Master.
4. Node Manager starts Application Master.
5. AM retrieves input data from HDFS.
6. AM requests resource allocation from Scheduler.
7. Node Manager starts container with Map/Reduce task.
8. Task retrieves job resources from HDFS.
9. Results stored back to HDFS.

#extra[
  Hadoop extensions (out of primary scope): *Avro* (serialization), *Chukwa* (log collection), *HBase* (structured data storage for large tables), *Hive* (data warehousing, Facebook), *Pig* (parallel SQL-like, Yahoo), *ZooKeeper* (coordination), *Mahout* (ML/data mining), *Sahara* (deployment on OpenStack).
]

=== Hadoop on OpenStack (Sahara)

Hadoop can exploit *OpenStack virtualization* for more flexible clusters and better resource utilization. OpenStack's *Sahara* service allows deploying and configuring Hadoop clusters in a Cloud environment, adding:
- *Cluster scaling functions*.
- *Analytics as a Service (AaaS)* functions.

Sahara is accessible via dashboard, CLI, or RESTful API.

#figure(
  image("../assets/sahara-hadoop.jpg", width: 60%),
  caption: [Sahara (OpenStack) components.]
)

== Apache Spark

=== Why Spark?

MapReduce greatly simplified Big Data analysis, but as it became popular, users wanted more:
- *More complex, multi-stage applications* (e.g., iterative graph algorithms and machine learning): MapReduce chains require writing intermediate results to disk between every job.
- *More interactive ad-hoc queries*.

Both multi-stage and interactive apps require faster *data sharing across parallel jobs*.

#important("MapReduce Data Sharing Problem")[
  In MapReduce: iterative jobs require HDFS read → process → HDFS write → HDFS read → process → ... for every iteration. Interactive queries each need a fresh HDFS read. Both are *slow due to replication, serialization, and disk I/O*. This is the fundamental bottleneck MapReduce cannot solve.
]
#v(-1em)
#def("Apache Spark")[
  #kw[Spark] is *not a modified version of Hadoop* but a separate, fast, MapReduce-like engine, optimized for in-memory processing. It provides:
  - *In-memory data storage* for very fast iterative queries.
  - *General execution* of graphs and powerful optimizations.
  - Up to *40× faster than Hadoop* for iterative workloads.
  - Compatible with Hadoop storage APIs (HDFS, HBase, SequenceFiles, etc.).
]
#v(-1em)
#analogy("Spark vs. Hadoop Data Sharing")[
  Hadoop is like passing notes by printing them, distributing copies, collecting them, shredding them, and printing new ones for each step. Spark keeps the notes *in RAM*, passing them directly between steps. First read from disk is unavoidable, but subsequent iterations are 10–100× faster.
]

=== Spark Basics

Spark offers various types of data processing computations in *one single tool*:
- *Batch/streaming* analysis, *interactive* queries, and *iterative* algorithms.
- Previously these required several different and independent tools.

Supports *several storage options and streaming inputs* for parsing. APIs available in *Java, Scala, Python, R*.

=== Resilient Distributed Datasets (RDDs)

The key data abstraction in Spark is the #kw[RDD]:

#def("Resilient Distributed Dataset (RDD)")[
  An #kw[RDD] is a *distributed, immutable collection of objects* that is:
  - Maintained *in memory* (when possible).
  - *Distributed* across cluster nodes.
  - *Immutable*: transformations create new RDDs, not modified ones.
  - *Can be cached in memory* across cluster nodes for reuse.

  RDDs achieve fault tolerance through *lineage* rather than replication.
]
#side-note(color: rgb("#002fff"))[
  💯 #text(fill: rgb("#002fff"))[*Prof. Question*]: #text(fill: rgb("#002fff").lighten(50%))[_What is an RDD? Why is it important?_]\
  An *RDD* (Resilient Distributed Dataset) is Spark's core data unit: a *distributed, immutable, fault-tolerant* collection partitioned across workers.\
  *Resilient*: on a worker failure it is *recomputed from its lineage* (the chain of transformations), so no replication is needed.\
  *Distributed*: partitioned for parallelism.\
  *Dataset*: an abstraction over data wherever it lives. It enables lazy, optimized evaluation.
]

=== RDD Operations

RDD operations come in two kinds, and the difference is *when they run*:
- *#kw[Transformations]* are #hl[*lazy*: they compute nothing, they just *record* the step, chaining into a *DAG*] (the RDD's lineage).
  #extra[Examples: `map`, `filter`, `groupBy`, `sort`, `join`, `union`, `reduceByKey`, `groupByKey`, `partitionBy`, `cogroup`, `cross`, `leftOuterJoin`, `rightOuterJoin`, `sample`.]
- *Actions* are *eager*: an action *triggers the whole DAG to run* and produces a result (returned or written out).
  #extra[Examples: `reduce`, `count`, `first`, `take`, `collect`, `save`, `pipe`.]

#def("DAG and Lineage")[
  Chaining transformations builds a *DAG* (Directed Acyclic Graph): each node is an RDD (a step), each edge is a *dependency*, and there are *no cycles*. This same graph is the RDD's *#kw[lineage]*, and Spark uses it for two things:
  - *Execution*: when an action fires, Spark *optimizes the DAG and splits it into stages* to run.
  - *Fault tolerance*: if a partition is lost (a node crash), Spark *recomputes only that partition* by replaying its branch of the lineage *from the source*, with *no data replication*.
]
#v(-1em)
#example("Lineage Graph")[
  ```
  messages = textFile(...).filter(_.contains("error"))
                          .map(_.split('\t')(2))
  ```
  Lineage: `HadoopRDD (path=hdfs://...)` ← `FilteredRDD (func=_.contains(...))` ← `MappedRDD (func=_.split(...))`

  If MappedRDD is lost, Spark retraces from HadoopRDD.
]

#side-note(color: rgb("#002fff"))[
  💯 #text(fill: rgb("#002fff"))[*Prof. Question*]: #text(fill: rgb("#002fff").lighten(50%))[_Difference between a Transformation and an Action in Spark?_]\
  A *Transformation* (`map`, `filter`, `flatMap`) is *lazy*: it builds a new RDD but runs nothing yet. An *Action* (`count`, `collect`, `save`) is *eager*: it triggers execution of the accumulated DAG and returns a result.
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

Because RDDs are *lazy and hold no data*, *every action recomputes the RDD's whole lineage from the original source*. So triggering ten actions on the same RDD (for example ten iterations of an algorithm) re-reads and re-maps the data *ten times*.

#hl[`persist()`] (or its shortcut `cache()`) fixes this: after the RDD is computed the *first* time, Spark #hl[*keeps its partitions in memory* across the workers], so later actions *reuse* them instead of recomputing.

```scala
val lines = sc.textFile("data.txt")
val lineLengths = lines.map(s => s.length)
lineLengths.persist()   // keep lineLengths in memory after its first use
```
#v(-0.7em)
#note[
  `cache()` is `persist()` with the default *memory-only* level. `persist()` also offers other *storage levels* (memory, disk, serialized). A cached partition that is lost is still *recomputed from lineage*, so caching never breaks fault tolerance. This *load once, iterate many* behaviour is what makes Spark fast on iterative algorithms.
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

- *General graphs of operators* (e.g., map-reduce-reduce chains), not just two-phase pipelines.
- *Hash-based reduces*: faster than Hadoop's sort-based approach.
- *Controlled data partitioning* adapted to lower communication overhead.

=== Spark Architecture

#def("Spark Architecture")[
  Spark programs create *Directed Acyclic Graphs (DAGs)* of all transformations and actions, internally optimized for execution. The graph is split into *stages*, composed by *tasks* (the smallest unit of work).

  The support is a *master/slave system*:
  - *Driver*: central coordinator node running the `main()` method of the program, dispatching tasks.
  - *Cluster Master*: launches and manages actual executors.
  - *Executors*: responsible for running tasks; each spawns at least one dedicated JVM with an assigned share of CPU threads and RAM memory.
]

#figure(
  image("../assets/spark-architecture.png", width: 50%),
  caption: [Spark architecture.]
)

#side-note(color: rgb("#002fff"))[
  💯 #text(fill: rgb("#002fff"))[*Prof. Question*]: #text(fill: rgb("#002fff").lighten(50%))[_What is the base architecture of Apache Spark?_]\
  A *master/worker* architecture. The *Driver* builds the *DAG* of lazy transformations on RDDs. When an *Action* is called, the DAG is optimized and split into *Stages*, each split into *Tasks* (one per partition). The *Cluster Manager* allocates *Executors* (JVMs), which run the tasks and return results to the Driver.
]

=== Spark Deployment Modes

Spark can be deployed:
- *Standalone cluster*: its own cluster master independently launches and manages executors.
- *Hadoop YARN*: relies on YARN for resource management (already seen above).
- *Apache MESOS*: fine-grained sharing, richer scheduling queues.

External resource managers provide richer functionalities (scheduling queues, multi-tenancy) not available in standalone mode.

=== Spark Provisioning and Output

Spark can produce *very large results*. Managing large aggregations (e.g., document at a URL) requires automation. The experience points toward storing produced batch data in *NoSQL repositories* for scalable access.

== The Big Data Tools Ecosystem

The Big Data processing landscape organizes along two dimensions: the *computational model* and the *use case*:

#figure(
  image("../assets/bd-tools.png"),
  caption: [Big Data tools ecosystem.]
)

== Big Data Resource Analysis

=== Resources as Unifying Concepts

All Big Data systems ultimately deal with the same *resource management issues*, categorized by when they must be handled:

*Runtime issues (dynamic, in-band):*
- *Resource Sharing* (multicast).
- *Resource Distribution* (events).
- *Resource Synchronization*.
- *Resource Replication*.
- *Resource Control*.

*Static issues (before runtime):*
- *Resource Configuration*.
- *Resource Timing*.

=== IT Properties Required

For Big Data and cloud systems to function reliably at scale, the following technical properties are required:
- *Dynamicity and adaptability*: systems must react to changing conditions.
- *Fault tolerance or Replication*: availability and reliability.
- *Loose Consistency*: CAP theorem trade-offs accepted for scale.
- *Group communication*: coordinating many nodes.
- *Data configuration and access*.
- *Resource life cycle support*.

And cross-cutting concerns:
- *Transparency*: hide distribution complexity from users.
- *Low intrusion*: management overhead must be minimal.
- *Time awareness*: event ordering, timeouts, expiry.
- *Simplicity*: the dominant design goal; complexity kills adoption.

#important("The MapReduce/Spark Lesson")[
  The success of MapReduce and Spark is not just about performance: it is about *abstraction and simplicity*. By hiding fault tolerance, scheduling, data movement, and parallelism behind a clean API, these frameworks allow engineers to write Big Data programs without expertise in distributed systems. The internal complexity is real; the user-visible model is not.
]
