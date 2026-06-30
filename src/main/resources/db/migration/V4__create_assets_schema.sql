-- =========================================================================
-- Schema: assets
-- Purpose: Core asset management. Defines logical assets, their versions,
--          and the file upload pipeline with SHA-256 integrity verification.
--
-- Immutability principle:
--   Assets and versions are immutable after creation. You cannot change an
--   asset's name and then retroactively apply it to old versions — you
--   create a new version. Files are never overwritten in S3; every upload
--   produces a new asset_version and asset_file row with a unique s3_key.
--
-- Architectural layers:
--   1. asset          → Logical identity (name, project, description).
--                       One per conceptual asset (e.g., "Character Portrait").
--   2. asset_version  → A specific iteration of the asset (e.g., "v5").
--                       Tracks draft/published state and version numbering.
--   3. asset_file     → The actual binary upload. Decoupled from
--                       asset_version so that upload pipeline state
--                       (UPLOADING, VERIFYING, FAILED) does not pollute
--                       the versioning model.
--
-- Upload flow (see AGENTS.md for full specification):
--   1. Frontend calculates SHA-256, sends to backend.
--   2. Backend creates asset + new version as DRAFT (no version number).
--   3. Backend creates asset_file row with status = UPLOADING.
--   4. File is uploaded to S3/MinIO.
--   5. Backend calculates SHA-256 from S3 object.
--      Match   → status = ACCEPTED, calculated_sha256_hash set.
--      Mismatch → status = REJECTED, rejection_reason set.
--   6. User promotes DRAFT → PUBLISHED. Version number assigned.
--
-- Concurrency:
--   Two artists uploading to the same asset simultaneously will create
--   two separate drafts (two asset_version rows). The user chooses which
--   to publish. This is intentional "concurrent draft" handling.
--
-- Deletion:
--   Soft-delete on asset and asset_version (deleted_at). asset_file is
--   append-only and never deleted — it records the full history of every
--   upload attempt, successful or failed, for diagnostic purposes.
--
--   When a project is tombstoned (status = DELETED), all asset rows,
--   asset_version rows, and their files are hard-deleted from the database
--   and S3/MinIO. See V2 project deletion flow.
--
-- Designed by: kosail
-- Date: June 30, 2026
-- =========================================================================

BEGIN TRANSACTION;

CREATE SCHEMA IF NOT EXISTS assets;


-- =========================================================================
-- Table: assets.asset
-- Purpose: Logical representation of an asset (e.g., "Character Portrait").
--          Not a file. One row per conceptual asset within a project.
--
-- Lifecycle: Created when the first version (draft) is initiated. Soft-
--            deleted when the asset is removed. All versions are also
--            soft-deleted at that point (application-level coordination).
--
-- Uniqueness: asset_name and asset_codename are each unique within a
--             project. Two projects can have an asset named "Hero" without
--             conflict. See indexes in V7.
-- =========================================================================
CREATE TABLE assets.asset (
    -- Surrogate primary key. Referenced by asset_version.
    id                  BIGINT GENERATED ALWAYS AS IDENTITY,

    -- The project this asset belongs to. FK to projects.project(id).
    -- Every asset lives inside exactly one project.
    project_id          BIGINT NOT NULL,

    -- Human-readable display name (e.g., "Main Character Portrait").
    -- Unique within the project (see partial index in V7).
    asset_name          VARCHAR(255) NOT NULL,

    -- Machine-readable internal identifier. Used by developers and scripts
    -- to reference assets programmatically (e.g., "char_main_portrait").
    -- Unique within the project (see partial index in V7).
    asset_codename      VARCHAR(255) NOT NULL,

    -- Free-text description of the asset. Optional. No length limit
    -- because artists may provide detailed technical notes.
    asset_description   TEXT,

    -- Optional thumbnail or icon representing this asset in listings.
    -- Points to S3/MinIO object path. Max 512 for full qualified URLs.
    asset_icon_url      VARCHAR(512),

    -- Record lifecycle timestamps.
    -- updated_at is maintained by trigger (trg_assets_asset_update in V8).
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at          TIMESTAMPTZ, -- NULL = active asset

    -- Actor tracking. FK to auth.app_user(id).
    created_by          BIGINT NOT NULL,
    updated_by          BIGINT NOT NULL,
    deleted_by          BIGINT,

    CONSTRAINT pk_asset PRIMARY KEY (id)
);


-- =========================================================================
-- Table: assets.asset_version
-- Purpose: A specific version of an asset. Immutable after creation.
--          Tracks the draft/published lifecycle and version numbering.
--
-- Draft → Published flow:
--   1. Version is created as DRAFT (version_number = NULL).
--   2. File is uploaded and verified via asset_file.
--   3. User promotes to PUBLISHED.
--   4. version_number is assigned: max existing version number for this
--      asset + 1. If it's the first version, version_number = 1.
--   5. published_at is set to CURRENT_TIMESTAMP.
--
-- Concurrent drafts:
--   Two artists can upload to the same asset simultaneously. Each creates
--   a separate asset_version row (both status = DRAFT). The user (Producer/
--   Admin) chooses which draft to publish. The unpromoted draft remains as
--   a DRAFT and can be published later, soft-deleted, or left indefinitely.
--   There is no automatic cleanup of abandoned drafts.
--
-- Immutability:
--   Once published, a version is immutable. version_number, status,
--   published_at, and file_id cannot change. The application must enforce
--   this — the database CHECK constraint only covers valid status values,
--   not the transition rules (DRAFT → PUBLISHED is a one-way transition).
-- =========================================================================
CREATE TABLE assets.asset_version (
    -- Surrogate primary key. Referenced by asset_file.
    id              BIGINT GENERATED ALWAYS AS IDENTITY,

    -- The asset this version belongs to. FK to assets.asset(id).
    -- NOT NULL: every version must be associated with an asset.
    asset_id        BIGINT NOT NULL,

    -- Points to the current/active file for this version. FK to
    -- assets.asset_file(id). Denormalization for performance: avoids
    -- querying asset_file with ORDER BY created_at DESC to find the
    -- latest file. Updated when a file transitions to ACCEPTED.
    -- NULL when no file has been accepted yet (draft with UPLOADING file).
    file_id         BIGINT,

    -- Assigned version number. NULL for DRAFT versions. Assigned at
    -- publish time as MAX(version_number) + 1 for the parent asset.
    -- First published version = 1.
    version_number  INTEGER,

    -- Lifecycle state. CHECK constraint enforces valid values.
    -- DRAFT     : Upload in progress or pending review. Not in production.
    -- PUBLISHED : Available for download. Immutable.
    status          VARCHAR(16) NOT NULL,

    -- Optional free-text notes about this version (e.g., "Fixed lighting
    -- on the character's left side, reduced poly count by 15%").
    -- Useful for artists to document changes between versions.
    version_notes   TEXT,

    -- Record lifecycle timestamps.
    -- created_at   : When the version row was created (draft initiated).
    -- updated_at   : Maintained by trigger (trg_assets_asset_version_update).
    -- published_at : When status changed from DRAFT to PUBLISHED.
    --                NULL for DRAFT versions.
    -- deleted_at   : Soft-delete marker. NULL = active version.
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at    TIMESTAMPTZ,
    deleted_at      TIMESTAMPTZ,

    -- Actor tracking. FK to auth.app_user(id).
    created_by      BIGINT NOT NULL,
    updated_by      BIGINT NOT NULL,
    deleted_by      BIGINT,

    -- Constraints
    CONSTRAINT pk_asset_version PRIMARY KEY (id),
    CONSTRAINT chk_asset_version_status CHECK (status IN ('DRAFT', 'PUBLISHED'))
);


-- =========================================================================
-- Table: assets.asset_file
-- Purpose: Tracks the upload and verification of a single binary file.
--          Decoupled from asset_version to separate the upload pipeline
--          state machine from the versioning model.
--
-- Append-only design:
--   This table has no soft-delete or update lifecycle. Once a row is
--   created, it is never modified except for status transitions and
--   timestamp/hash updates during verification. A failed upload row
--   remains as a permanent record for diagnostics. The application never
--   deletes rows from this table — even REJECTED files stay for debugging
--   and audit purposes.
--
-- Upload pipeline state machine:
--   UPLOADING  → File is being transferred to S3. No hash verification
--                has occurred yet. calculated_sha256_hash IS NULL.
--   VERIFYING  → Upload complete. Backend is calculating SHA-256 from
--                the S3 object. calculated_sha256_hash IS NULL.
--   FAILED     → Upload or verification failed for a technical reason
--                (network error, S3 unavailable, etc.). Not a hash
--                mismatch — that's REJECTED. calculated_sha256_hash IS NULL.
--   ACCEPTED   → Upload succeeded AND hash matches. File is ready for
--                version publishing. calculated_sha256_hash IS NOT NULL.
--   REJECTED   → Upload succeeded but hash does NOT match. File integrity
--                compromised in transit. rejection_reason records details.
--                S3 object should be deleted (application responsibility).
--                calculated_sha256_hash IS NOT NULL.
--
--   Valid transitions:
--     UPLOADING → VERIFYING (upload complete)
--     VERIFYING → ACCEPTED  (hash match)
--     VERIFYING → REJECTED  (hash mismatch)
--     UPLOADING → FAILED    (technical failure)
--     VERIFYING → FAILED    (technical failure during verification)
--
--   Invalid transitions (enforced by application):
--     ACCEPTED → anything   (terminal state)
--     REJECTED → anything   (terminal state)
--     FAILED → anything     (terminal state)
--
-- SHA-256 verification:
--   expected_sha256_hash is submitted by the frontend before upload.
--   calculated_sha256_hash is computed by the backend from the S3 object
--   after upload completes. If they match → ACCEPTED. If they differ →
--   REJECTED with rejection_reason = "File checksum mismatch. Expected:
--   <expected>, Calculated: <calculated>."
--
-- S3 key determinism:
--   s3_key is deterministic: derived from project, asset, and version
--   identifiers before upload begins. This means the S3 key is known at
--   row creation time (status = UPLOADING), not after upload. The
--   application can pre-generate a presigned URL for the exact key.
--   s3_key is globally unique (enforced by UNIQUE constraint).
-- =========================================================================
CREATE TABLE assets.asset_file (
    -- Surrogate primary key.
    id                      BIGINT GENERATED ALWAYS AS IDENTITY,

    -- The version this file belongs to. FK to assets.asset_version(id).
    -- NOT NULL: every file upload is associated with a specific version.
    asset_version_id        BIGINT NOT NULL,

    -- Original filename as provided by the user during upload
    -- (e.g., "character_v5_final.psd"). Informational only.
    file_name               VARCHAR(255) NOT NULL,

    -- File size in bytes. Provided by the frontend before upload (from
    -- the browser's File API) and validated against the actual S3 object
    -- size during verification. Used for progress tracking and storage
    -- quota enforcement.
    file_size               BIGINT NOT NULL,

    -- MIME type of the file (e.g., "image/png", "application/octet-stream").
    -- Provided by the frontend. Used by download endpoints to set the
    -- Content-Type response header without querying S3 metadata.
    content_type            VARCHAR(128) NOT NULL,

    -- SHA-256 hash reported by the frontend before upload begins.
    -- Hex-encoded (64 characters for 256 bits).
    -- This is the expected value; calculated_sha256_hash is the actual
    -- value computed by the backend from the S3 object.
    expected_sha256_hash    VARCHAR(64) NOT NULL,

    -- Deterministic S3/MinIO object key. Globally unique (see UNIQUE
    -- constraint). Format: projects/{project_id}/assets/{asset_id}/
    -- versions/{version_id}/{file_name}. Generated at row creation time.
    s3_key                  VARCHAR(512) NOT NULL,

    -- SHA-256 hash calculated by the backend from the uploaded S3 object.
    -- NULL during UPLOADING, VERIFYING, and FAILED states.
    -- Set when the backend finishes computing the hash and the file is
    -- either ACCEPTED or REJECTED.
    -- Hex-encoded (64 characters).
    calculated_sha256_hash  VARCHAR(64),

    -- Upload pipeline status. See state machine documentation above.
    -- CHECK constraint enforces valid values at the database level.
    status                  VARCHAR(16) NOT NULL,

    -- Human-readable reason for rejection. Only set when status = REJECTED.
    -- Example values:
    --   "File checksum mismatch. Expected: abc123, Calculated: def456"
    --   "File size mismatch. Expected: 1048576 bytes, Actual: 524288 bytes"
    -- NULL for all other statuses.
    rejection_reason        TEXT,

    -- Row creation timestamp. Set when the upload is initiated.
    -- Not the same as upload start time — this is record creation.
    created_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- When the file bytes finished transferring to S3. Set during the
    -- UPLOADING → VERIFYING transition. NULL during UPLOADING state.
    -- Not affected by the DEFAULT clause — set explicitly by application.
    upload_completed_at     TIMESTAMPTZ,

    -- When the backend finished computing calculated_sha256_hash and
    -- determined the ACCEPTED or REJECTED verdict. NULL during UPLOADING
    -- and VERIFYING states.
    verified_at             TIMESTAMPTZ,

    -- Who initiated the upload. FK to auth.app_user(id).
    -- NOT NULL: every file is uploaded by an authenticated user.
    uploaded_by             BIGINT NOT NULL,

    -- Constraints
    CONSTRAINT pk_assets_asset_file PRIMARY KEY (id),

    -- No two files can share the same S3 key. Enforces the "never
    -- overwrite" principle at the storage layer: even if application
    -- logic has a bug, the database will reject a duplicate s3_key.
    CONSTRAINT uq_asset_file_s3_key UNIQUE (s3_key),

    -- Valid upload pipeline states.
    CONSTRAINT chk_asset_file_status CHECK (
        status IN ('UPLOADING', 'VERIFYING', 'FAILED', 'ACCEPTED', 'REJECTED')
    ),

    -- Status-hash consistency invariant. Enforced at the database level
    -- so that no application bug can create a logically inconsistent row:
    --
    --   UPLOADING, VERIFYING, FAILED → hash IS NULL (no hash computed yet)
    --   ACCEPTED, REJECTED           → hash IS NOT NULL (verdict reached)
    --
    -- This CHECK constraint is the database-level enforcement of the
    -- upload pipeline state machine. Without it, a developer could set
    -- status = ACCEPTED without providing the hash — and the bug would
    -- only surface when a download fails hash verification weeks later.
    CONSTRAINT chk_asset_file_status_consistency CHECK (
            (
                (status = 'UPLOADING' OR status = 'VERIFYING' OR status = 'FAILED')
                    AND
                (calculated_sha256_hash IS NULL)
            )
        OR
            (
                (status = 'ACCEPTED' OR status = 'REJECTED')
                    AND
                (calculated_sha256_hash IS NOT NULL)
            )
    )
);

COMMIT TRANSACTION;
