package com.korealm.emanon

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.JoinColumn
import jakarta.persistence.ManyToOne
import jakarta.persistence.Table
import org.hibernate.annotations.ColumnDefault
import org.hibernate.annotations.OnDelete
import org.hibernate.annotations.OnDeleteAction
import java.time.OffsetDateTime

@Entity
@Table(name = "asset_file", schema = "assets")
class AssetFile {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    var id: Long = 0L

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.RESTRICT)
    @JoinColumn(name = "asset_version_id", nullable = false)
    var assetVersion: AssetVersion? = null

    @Column(name = "file_name", nullable = false)
    var fileName: String = ""

    @Column(name = "file_size", nullable = false)
    var fileSize: Long = 0L

    @Column(name = "content_type", nullable = false, length = 128)
    var contentType: String = ""

    @Column(name = "expected_sha256_hash", nullable = false, length = 64)
    var expectedSha256Hash: String = ""

    @Column(name = "s3_key", nullable = false, length = 512)
    var s3Key: String = ""

    @Column(name = "calculated_sha256_hash", length = 64)
    var calculatedSha256Hash: String? = null

    @Column(name = "status", nullable = false, length = 16)
    var status: String = ""

    @Column(name = "rejection_reason", length = Integer.MAX_VALUE)
    var rejectionReason: String? = null

    @ColumnDefault("CURRENT_TIMESTAMP")
    @Column(name = "created_at", nullable = false)
    var createdAt: OffsetDateTime = OffsetDateTime.now()

    @Column(name = "upload_completed_at")
    var uploadCompletedAt: OffsetDateTime? = null

    @Column(name = "verified_at")
    var verifiedAt: OffsetDateTime? = null

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.RESTRICT)
    @JoinColumn(name = "uploaded_by", nullable = false)
    var uploadedBy: AppUser? = null

}