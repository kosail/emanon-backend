package com.korealm.emanon.auth.internal.data.models;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.Generated;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import org.hibernate.generator.EventType;

import java.time.OffsetDateTime;

@Getter
@Setter
@Entity
@Table(name = "app_user_profile", schema = "auth")
public class AppUserProfile {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @Column(name = "deleted_at")
    private OffsetDateTime deletedAt;

    @Generated(event = EventType.UPDATE)
    @ColumnDefault("CURRENT_TIMESTAMP")
    @Column(name = "updated_at", insertable = false, nullable = false)
    private OffsetDateTime updatedAt;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.RESTRICT)
    @JoinColumn(name = "updated_by", nullable = false)
    private AppUser updatedBy;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.RESTRICT)
    @JoinColumn(name = "user_id", nullable = false)
    private AppUser user;

    @Column(name = "profile_picture_url", length = 128)
    private String profilePictureUrl;

    @Column(name = "user_description")
    private String userDescription;


}