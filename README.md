# EMANON

**Enterprise Metadata & Asset Network, Orchestrator Node.** A videogame asset management system for small teams.

Built with Spring Boot 4 and Kotlin 2.3. It runs as a modular monolith with PostgreSQL 18 for metadata and S3/MinIO for binary files. Nothing more.

The name came from a manga I love, which is called "Emanon". But a name must have a reason to be, right? So I called it "Enterprise Metadata & Asset Network, Orchestrator Node" and made the acronym fit.

---

### Current state

*   The database schema is defined across schemas: `auth`, `projects`, `tags`, `assets`, `permissions`.
*   The backend has been initialized and dependencies are configured.
*   I am creating the modules and setting up entities.

---

## Setup

Clone the repository:

```bash
git clone https://github.com/kosail/emanon.git
cd emanon

# You need a PostgreSQL and MinIO instance running
# Run the app in dev mode
./gradlew bootRun
```

Build a native image (GraalVM required):

```bash
./gradlew nativeCompile
```

---

## Architecture

Five modules. Each one has three layers: contracts (interfaces), implementation, and tests. Spring Modulith enforces that no module reaches into another module's internals. The dependency between modules flows in one direction:

```
auth ← projects ← assets ← versions ← permissions
```

Auth owns everything related to identity. Permissions owns what actions can be performed. Projects owns the container. Assets owns the logical entity. Versions owns the file. The separation overlaps with database schemas.

There is no event bus, no message queue, no Redis, no Kubernetes. The upload flow is synchronous: frontend calculates a SHA-256, sends it, backend uploads to S3, verifies the hash, accepts or rejects. The download flow mirrors that: backend sends the file and its hash, frontend verifies locally.

### Why a modular monolith

I work alone on this. Splitting into microservices would multiply the operational surface, deployments, networking, observability... for zero benefit at this scale. A modular monolith gives the same internal boundary discipline (via Spring Modulith) without the distributed system tax. If the project ever needs to split, the module boundaries are already drawn.

---

## Database

Six schemas are defined, five are implemented:

| Schema | Purpose |
|---|---|
| `auth` | User accounts, login history, project memberships |
| `projects` | Project lifecycle with tombstone deletion |
| `tags` | Global or project-scoped asset tags |
| `assets` | Asset identity, versioning, and upload pipeline |
| `permissions` | Action/target permission matrix |
| `audit` | Reserved for future |

Every schema uses `TIMESTAMPTZ` for timestamps. Every ID is `BIGINT GENERATED ALWAYS AS IDENTITY`. Soft-delete is the default strategy everywhere except project deletion, which uses a tombstone pattern because assets are large and keeping them around wastes storage.

The `asset_file` table has two CHECK constraints that enforce the upload pipeline state machine at the database level. If the status says `ACCEPTED`, the `calculated_sha256_hash` must be non-null. If it says `UPLOADING`, the hash must be null. The database refuses to store an inconsistent row even if the application code has a bug.

---

## Decisions that mattered

**BIGINT over UUIDv7.** The system has one database. Distributed IDs solve a problem that does not exist here. It is virtually impossible to fill a BIGINT-typed column.

**`ON DELETE RESTRICT` everywhere.** Hard deletes should fail unless the application explicitly accounts for them. CASCADE destroys data silently. RESTRICT makes the database the last line of defense.

**Foreign keys on audit-by columns.** Every `created_by`, `updated_by`, and `deleted_by` column references `auth.app_user(id)` with `ON DELETE RESTRICT`. This prevents hard-deleting a user who has created records.

**Partial unique indexes.** Used everywhere soft-delete applies. A soft-deleted row does not block a new row with the same name. The `WHERE deleted_at IS NULL` clause on the index makes this work without sacrificing uniqueness on active data.

---

## Contributing

This is a learning project. I am building it to understand backend architecture, database design, storage systems, and preparing myself to become a senior dev. If you find a bug or an architectural issue, open an issue. If you want to discuss a design decision, please, feel free to open a PR and leave an explanation so I can understand the whys, pros and cons.

---

## License

EMANON is licensed under the Mozilla Public License 2.0 (MPL-2.0).

You can use it for internal studio projects, modify it, distribute it, or embed it in larger works. If you modify files that are under the MPL, those changes must stay under the MPL when distributed. The rest of your project can use any license.

See the LICENSE file in the repository root for the full text.

---

EMANON System 2026, kosail <br> With love, from Honduras.
