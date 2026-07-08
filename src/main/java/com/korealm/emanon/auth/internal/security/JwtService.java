package com.korealm.emanon.auth.internal.security;

import com.korealm.emanon.auth.internal.data.models.AppUser;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.security.Key;
import java.util.Date;
import java.util.Map;
import java.util.UUID;

@Service
public class JwtService {

    @Value("${jwt.secret}") private String secretKey;
    @Value("${jwt.issuer}") private String issuer;
    @Value("${jwt.expiration.access}") private long accessExpirationTime;
    @Value("${jwt.expiration.refresh}") private long refreshExpirationTime;

    public String generateAccessToken(AppUserDetailsAdapter userDetailsAdapter) {
        final var user = userDetailsAdapter.user();
        return buildToken(user, accessExpirationTime);
    }

    public String generateRefreshToken(AppUserDetailsAdapter userDetailsAdapter) {
        final var user = userDetailsAdapter.user();
        return buildToken(user, refreshExpirationTime);
    }

    private String buildToken(AppUser user, long expirationTime) {
        final var now = System.currentTimeMillis();

        return Jwts.builder()
                .issuer(issuer)
                .subject(user.getPublicId().toString())
                .claim("token_version", user.getTokenVersion())
                .claim("username", user.getUsername())
                .issuedAt(new Date(now))
                .expiration(new Date(now + accessExpirationTime))
                .signWith(getSignKey())
                .compact();
    }

    public String extractSubject(String token) {
        return parseClaims(token).getSubject();
    }

    public Integer extractTokenVersion(String token) {
        return (Integer) parseClaims(token).get("jwt_version", Integer.class);
    }

    public boolean isTokenValid (String token) {
        try {
            // throws if expired, malformed, wrong signature
            parseClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith((SecretKey) getSignKey())
                .requireIssuer(issuer)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private Key getSignKey() {
        byte[] keyBytes = Decoders.BASE64.decode(secretKey);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
