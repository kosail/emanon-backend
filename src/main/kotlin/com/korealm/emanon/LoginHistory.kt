package com.korealm.emanon

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import org.hibernate.annotations.ColumnDefault
import java.net.InetAddress
import java.time.OffsetDateTime

@Entity
@Table(name = "login_history", schema = "auth")
class LoginHistory {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    var id: Long = 0L

    @Column(name = "user_id", nullable = false)
    var userId: Long = 0L

    @Column(name = "ip_address", nullable = false)
    var ipAddress: InetAddress? = null

    @Column(name = "user_agent", nullable = false)
    var userAgent: String = ""

    @Column(name = "success", nullable = false)
    var success: Boolean = false

    @ColumnDefault("CURRENT_TIMESTAMP")
    @Column(name = "attempt_at", nullable = false)
    var attemptAt: OffsetDateTime = OffsetDateTime.now()

}