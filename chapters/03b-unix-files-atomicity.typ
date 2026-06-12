#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= UNIX FILES AND SINGLE PRIMITIVE ATOMICITY

#extra[
  Package: UNIX files and Single Primitive Atomicity — `unix file direttori.pdf`
]

UNIX has a very clean and simple semantic model: #hl[only a few *primitives* on files and directories are] #hl[*guaranteed atomic*] operations in the kernel. Everything above that level is the application's responsibility. Understanding this model is fundamental for reasoning about consistency and synchronization in any system built on top of UNIX-like operating systems.

== UNIX File Primitives

#prop("Atomic Primitives in UNIX")[
  - *File operations*: `open` / `read` / `write` / `close` / `remove`
  - *Directory operations*: `opendir` / `readdir` / `closedir` / `rmdir`

  The kernel grants #hl[*minimal atomicity* on each *#underline[single] primitive*]. It #hl[offers only mechanisms, no policy].
]
#v(-1em)
#note[
  Policies are chosen by the application itself.
]
#v(-0.5em)
#def("Atomicity in UNIX")[
  A #kw[UNIX primitive] is *atomic* if the kernel guarantees that its effects are applied as one *uninterruptible action*, so that no other process can observe a partial result.
]
#v(-1em)
#note[
  #hl[Atomicity in UNIX ensures *kernel-level consistency*, not application-level isolation.] That is the base for predictable behavior under concurrency. Synchronization and consistency *across* primitives are left entirely to the applications.
]

== UNIX File System Architecture

The UNIX file system has a layered structure connecting user space to persistent disk storage:

#prop("File Access Layers (recalls)")[
  - *User space*: each process holds *file descriptors (fd)* pointing into the process table for open files.
  - *System space*: the kernel maintains a *Global File Table* with all active file entries. Each entry holds the current *I/O pointer*.
  - *i-node*: the kernel-level data structure that tracks all disk blocks constituting a file. A file is managed and accessed via its i-node.
  - *Memory cache*: block copies are loaded into a kernel cache to shorten access time (open → read/write → close operates on cached data).
  - *Persistent disk*: the actual data blocks.
  When a father process forks a son process, they may *share the same open file entry* (same I/O pointer).
]

#figure(
  image("../assets/unix-full-pic.jpg", width: 70%),
  caption: [Unix full picture.]
)

=== i-nodes and Directories (recalls)

#def("i-node")[
  An #kw[i-node] is the metadata structure that keeps track of all *disk blocks constituting a file*. It stores file *metadata* (permissions, timestamps, size) and *pointers* to data blocks on disk.
]
#v(-1em)
#def("Directory")[
  In UNIX, a #kw[directory] is a *special file* (with ad-hoc primitives: `opendir`, `readdir`, `closedir`) that maps names to i-nodes of contained files and subdirectories.\
  Every directory contains:
  - `.` #swarrow a reference to itself.
  - `..` #swarrow a reference to its parent directory.
  - Entries for all contained files (pointing to their i-nodes).
]

#figure(
  image("../assets/inodes-diffs.jpg", width: 60%),
  caption: [Inode comparison (file vs. directory).]
)

== Consequences of\ Per-Primitive Atomicity

=== Non-Determinism Under Concurrent Writes

#example("Two Processes Writing the Same File")[
  In UNIX, two processes may open the same file with different I/O pointers (two separate `open` calls):
  - P1 writes at position 0: `"AAAAA"`
  - P2 writes at position 3: `"BBBBB"`

  Each write is individually atomic, but the *ordering between the two is not defined* (non-determinism in scheduler). The final pattern depends on scheduling:
  - `"AAABBBBB"` (P1 first, P2 second #swarrow P2 overwrites from position 3)
  - `"AAAAABBB"` (P2 first, P1 second #swarrow P1 overwrites from position 0)

  If both insist on the *same position*, either `"AAAAA"` or `"BBBBB"` wins, it is unpredictable. *No application-level isolation is provided by the kernel*.
]
#v(-1em)
#important("No Cross-Primitive Consistency")[
  UNIX guarantees atomicity *per primitive only*, not across sequences of primitives. Any compound operation (read-then-write, check-then-act) is subject to race conditions if multiple processes operate concurrently on the same files.
  Applications must implement their own locking or coordination mechanisms (e.g., `fcntl` locks, lock files, atomic rename).
]

=== Directory Listing Under Concurrent Modification

#example("Recursive Directory Listing as a Moving Target")[
  In UNIX, listing a directory recursively (e.g., `ls -R`) makes *many separate* `opendir()` and `readdir()` calls. The kernel guarantees each `readdir()` call is atomic, but the *whole traversal is not*.

  If files are being created or deleted concurrently:
  - Some listed files may no longer exist by the time they are printed.
  - Other files created during traversal may not appear at all.

  The entire listing is *inconsistent*, it is *not a snapshot* but a sequence of many pictures of a moving target. This is #hl[*eventual consistency at the primitive level*], not an atomic view.
]
#v(-0.3em)
#extra[#why("not make the whole traversal atomic")[
  Making a recursive traversal atomic would require locking the #underline[entire] subtree for the duration. This would be prohibitively expensive and would block all concurrent access. UNIX's design philosophy is to keep the kernel simple and minimal, providing mechanisms, not policies. Applications that need consistent snapshots must implement them at a higher level (e.g., copy-on-write filesystems, snapshots, or versioned databases).
]]
#v(-1em)
#analogy("The Panoramic Scan Error")[
  UNIX per-primitive atomicity is like taking a panoramic photo while moving the smartphone. Each single vertical slice captured by the sensor is crisp and accurate (atomic `readdir()`), but the entire sweep takes time. If the subject moves during the scan, the final image will be distorted and inconsistent (showing duplicates or missing pieces of a moving target). A true atomic snapshot would require a 360 camera that freezes the entire landscape instantly, but that would mean forcing everyone in the scene to stand perfectly still during the shot.
]