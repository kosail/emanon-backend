package com.korealm.emanon.projects.data;

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
@Table(name = "project", schema = "projects")
public class Project {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @Column(name = "archived_at")
    private OffsetDateTime archivedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @OnDelete(action = OnDeleteAction.RESTRICT)
    @JoinColumn(name = "archived_by")
    private AppUser archivedBy;

    @ColumnDefault("CURRENT_TIMESTAMP")
    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.RESTRICT)
    @JoinColumn(name = "created_by", nullable = false)
    private AppUser createdBy;

    @Column(name = "deleted_at")
    private OffsetDateTime deletedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @OnDelete(action = OnDeleteAction.RESTRICT)
    @JoinColumn(name = "deleted_by")
    private AppUser deletedBy;

    @ColumnDefault("CURRENT_TIMESTAMP")
    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.RESTRICT)
    @JoinColumn(name = "updated_by", nullable = false)
    private AppUser updatedBy;

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