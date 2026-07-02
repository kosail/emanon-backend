package com.korealm.emanon.assets.internal.data.models;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;

import java.time.OffsetDateTime;

@Getter
@Setter
@Entity
@Table(name = "asset", schema = "assets")
public class Asset {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @ColumnDefault("CURRENT_TIMESTAMP")
    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    @Column(name = "created_by", nullable = false)
    private Long createdByUserId;

    @Column(name = "deleted_at")
    private OffsetDateTime deletedAt;

    @Column(name = "deleted_by")
    private Long deletedByUserId;

    @Column(name = "project_id", nullable = false)
    private Long projectId;

    @ColumnDefault("CURRENT_TIMESTAMP")
    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @Column(name = "updated_by", nullable = false)
    private Long updatedByUserId;

    @Column(name = "asset_icon_url", length = 512)
    private String assetIconUrl;

    @Column(name = "asset_codename", nullable = false)
    private String assetCodename;

    @Column(name = "asset_name", nullable = false)
    private String assetName;

    @Column(name = "asset_description", length = Integer.MAX_VALUE)
    private String assetDescription;


}