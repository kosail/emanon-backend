package com.korealm.emanon.projects.internal.data;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.Generated;
import org.hibernate.generator.EventType;

import java.time.OffsetDateTime;

@Getter
@Setter
@Entity
@Table(name = "project", schema = "projects")
public class Project {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @Column(name = "archived_at")
    private OffsetDateTime archivedAt;

    @Column(name = "archived_by")
    private Long archivedByUserId;

    @ColumnDefault("CURRENT_TIMESTAMP")
    @Column(name = "created_at", insertable = false, updatable = false, nullable = false)
    private OffsetDateTime createdAt;

    @Column(name = "created_by", nullable = false)
    private Long createdByUserId;

    @Column(name = "deleted_at")
    private OffsetDateTime deletedAt;

    @Column(name = "deleted_by")
    private Long deletedByUserId;

    @Generated(event = EventType.UPDATE)
    @ColumnDefault("CURRENT_TIMESTAMP")
    @Column(name = "updated_at", insertable = false, nullable = false)
    private OffsetDateTime updatedAt;

    @Column(name = "updated_by", nullable = false)
    private Long updatedByUserId;

    @ColumnDefault("'ACTIVE'")
    @Column(name = "status", nullable = false, length = 32)
    private String status;

    @Column(name = "project_name", nullable = false, length = 128)
    private String projectName;

    @Column(name = "slug", nullable = false, length = 128)
    private String slug;

    @Column(name = "project_external_url", length = 512)
    private String projectExternalUrl;

    @Column(name = "project_icon_url", length = 512)
    private String projectIconUrl;

    @Column(name = "description", length = Integer.MAX_VALUE)
    private String description;


}