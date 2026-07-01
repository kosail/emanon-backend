package com.korealm.emanon.assets.data.models;

import com.korealm.emanon.auth.data.models.AppUser;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.OffsetDateTime;

@Getter
@Setter
@Entity
@Table(name = "asset_file", schema = "assets")
public class AssetFile {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.RESTRICT)
    @JoinColumn(name = "asset_version_id", nullable = false)
    private AssetVersion assetVersion;

    @ColumnDefault("CURRENT_TIMESTAMP")
    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    @Column(name = "file_size", nullable = false)
    private Long fileSize;

    @Column(name = "upload_completed_at")
    private OffsetDateTime uploadCompletedAt;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.RESTRICT)
    @JoinColumn(name = "uploaded_by", nullable = false)
    private AppUser uploadedBy;

    @Column(name = "verified_at")
    private OffsetDateTime verifiedAt;

    @Column(name = "status", nullable = false, length = 16)
    private String status;

    @Column(name = "calculated_sha256_hash", length = 64)
    private String calculatedSha256Hash;

    @Column(name = "expected_sha256_hash", nullable = false, length = 64)
    private String expectedSha256Hash;

    @Column(name = "content_type", nullable = false, length = 128)
    private String contentType;

    @Column(name = "s3_key", nullable = false, length = 512)
    private String s3Key;

    @Column(name = "file_name", nullable = false)
    private String fileName;

    @Column(name = "rejection_reason", length = Integer.MAX_VALUE)
    private String rejectionReason;


}