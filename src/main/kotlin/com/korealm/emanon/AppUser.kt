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
@Table(name = "app_user", schema = "auth")
class AppUser {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    var id: Long = 0L

    @Column(name = "first_name", nullable = false, length = 128)
    var firstName: String = ""

    @Column(name = "last_name", nullable = false, length = 128)
    var lastName: String = ""

    @Column(name = "username", nullable = false, length = 128)
    var username: String = ""

    @Column(name = "email", nullable = false, length = 128)
    var email: String = ""

    @Column(name = "password_hash", nullable = false, length = 128)
    var passwordHash: String = ""

    @ColumnDefault("0")
    @Column(name = "token_version", nullable = false)
    var tokenVersion: Int = 0

    @ColumnDefault("CURRENT_TIMESTAMP")
    @Column(name = "last_seen_at", nullable = false)
    var lastSeenAt: OffsetDateTime = OffsetDateTime.now()

    @ColumnDefault("CURRENT_TIMESTAMP")
    @Column(name = "created_at", nullable = false)
    var createdAt: OffsetDateTime = OffsetDateTime.now()

    @ColumnDefault("CURRENT_TIMESTAMP")
    @Column(name = "updated_at", nullable = false)
    var updatedAt: OffsetDateTime = OffsetDateTime.now()

    @Column(name = "deleted_at")
    var deletedAt: OffsetDateTime? = null

    @ManyToOne(fetch = FetchType.LAZY)
    @OnDelete(action = OnDeleteAction.RESTRICT)
    @JoinColumn(name = "created_by")
    var createdBy: AppUser? = null

    @ManyToOne(fetch = FetchType.LAZY)
    @OnDelete(action = OnDeleteAction.RESTRICT)
    @JoinColumn(name = "updated_by")
    var updatedBy: AppUser? = null

    @ManyToOne(fetch = FetchType.LAZY)
    @OnDelete(action = OnDeleteAction.RESTRICT)
    @JoinColumn(name = "deleted_by")
    var deletedBy: AppUser? = null

}