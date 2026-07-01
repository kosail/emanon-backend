![Naoko logo](.images/logo.webp)

## Words left behind.

**Naoko** is a minimalist text editor. A data integrity first one.

No markdown, no extra functions.

Built with Wails and React, Naoko focuses on a single goal: writing text without distractions while keeping your work safe. Fast startup, fast automatic saving, crash recovery, and a clean interface are prioritized over feature overload.

The project takes its name from Naoko, one of the central characters of *Norwegian Wood* by Haruki Murakami, which is my favorite novel from all times.  She is quiet, simple, and introspective, and the editor follows the same philosophy.

---

### Current state

* 🚧 Under development. I just started the project.

---


## Setup

Clone the repository:

```bash
git clone https://codeberg.org/kosail/naoko.git
cd naoko
```

Run the application on dev:

```bash
# On Ubuntu based distros
wails dev 

# On arch based distros
wails dev  -tags webkit2_41
```

Build a distribution:

```bash
# For Ubuntu based
wails build

# For Arch based
wails build -tags webkit2_41
```

---

## Philosophy

I decided to create this project because my laptop has a faulty motherboard, and it randomly crashes or reboots many times per day. What I needed was a blazing fast, extremely reliable notepad, and this is it.

Naoko is intentionally small. Many text editors grow into development environments, note-taking systems, synchronization platforms, AI assistants and so on.
I don't aim to make any of those things because there are better tools out there already (like Obsidian or Anytype), and that's the issue: is hard to find a simple, reliable notepad that is dead simple to use.

So I built this app thinking in the old school Windows notepad, but with a modern UI and a clean interface. And of course, a fine-grained internal mechanism that keeps atomic snapshots of the file. But more about this in the next section:

### Crash Recovery Architecture

Naoko keeps the active document entirely in memory for maximum editing performance.

To protect against crashes, power loss, and unexpected system reboots, the editor continuously creates recovery snapshots in the background.

Instead of modifying the original file, it alternates between two independent recovery slots:

- snapshot_a
- snapshot_b

> [!IMPORTANT]  
> Each snapshot is composed by 2 independent files
>
> - snapshot_a.meta                            <-- Metadata containing file name, datetime and checksum
> - snapshot_a.content                        <-- Actual file contents
>
> In fact, these files are not called "snapshot_a", but use an UUID.

Only one snapshot is written at a time, and they rotate fast on every autosave. The reason of having a rotated snapshot strategy is that if the application crashes during snapshot creation or a failure occurs (e.g. memory corruption), the previous snapshot remains intact.

When a snapshot is created:

1. The current document is converted to bytes.
2. A SHA-256 checksum is calculated from those raw bytes.
3. Snapshot files, both metadata and content, are written as temporary files to disk.
4. If the write to disk was successful, then the temporary files are atomically renamed to their parents snapshot.

This way we ensure that not only the original file is protected, but also the snapshots itself.

> [!NOTE]  
> This is an over simplified view of what goes inside Naoko. In reality, one single file is actually managed in 8 parts:
> - original.txt                              -- Original file on disk:
>
>   -- Rotating snapshots.
> - snapshot_a.meta
> - snapshot_a.content
> - snapshot_b.meta
> - snapshot_b.content
> 
>    -- Temporary files created when writing from memory to disk. If the write is succesful, then are rename to replaced their parents snapshot
> - snapshot_a.meta.tmp
> - snapshot_a.content.tmp
> - snapshot_b.meta.tmp
> - snapshot_b.content.tmp
>
> If autosave is enabled, a debounced service checks the checksum of the most recent snapshot by that moment and atomically replaces the original file every X seconds.


At startup, both snapshots are validated:

- Read snapshots metadata.
- Read snapshots content.
- Recalculate SHA-256.
- Compare with the stored checksum.

The newest valid snapshot is recovered automatically.

This approach may seem overkill for a simple notepad, and it may be the case. But Naoko exists because I needed a notepad like this. This app prioritizes data integrity over storage efficiency. 

> [!TIP]
> Recovery requires reading a single snapshot file and does not depend on replaying journals, reconstructing edit histories, or processing incremental changes.



---

## Contributing

Contributions are welcome! Feel free to fork the repository and submit pull requests.

If you have ideas, suggestions, or bug reports, open an issue on GitHub.

---

## License

Naoko is licensed under the Mozilla Public License 2.0 (MPL-2.0).

You are free to:

* Use the software for personal, academic, or commercial purposes
* Modify the source code
* Distribute original or modified versions
* Include Naoko within larger proprietary or commercial projects

If you modify files that are covered by the MPL, those modified files must remain available under the MPL when distributed. However, the rest of your project may use a different license, including proprietary licenses.

For the complete license text, see the LICENSE file included in this repository.

---

Naoko Copyright © 2026, kosail <br> With love, from Honduras.