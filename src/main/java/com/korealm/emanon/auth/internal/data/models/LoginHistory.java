package com.korealm.emanon.auth.internal.data.models;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.net.InetAddress;
import java.time.OffsetDateTime;

@Getter
@Setter
@Entity
@Table(name = "login_history", schema = "auth")
public class LoginHistory {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @Column(name = "success", nullable = false)
    private Boolean success;

    @ColumnDefault("CURRENT_TIMESTAMP")
    @Column(name = "attempt_at", nullable = false)
    private OffsetDateTime attemptAt;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.RESTRICT)
    @JoinColumn(name = "user_id", nullable = false)
    private AppUser user;

    @Column(name = "ip_address", nullable = false)
    private InetAddress ipAddress;

    @Column(name = "user_agent", nullable = false)
    private String userAgent;


}