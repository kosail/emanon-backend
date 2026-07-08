package com.korealm.emanon.security.jwt;

import com.korealm.emanon.auth.AuthenticationUserInfo;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.security.Key;
import java.util.Date;

@Component
public class JwtService {

    @Value("${jwt.secret}") private String secretKey;
    @Value("${jwt.issuer}") private String issuer;
    @Value("${jwt.expiration.access}") private long accessExpirationTime;
    @Value("${jwt.expiration.refresh}") private long refreshExpirationTime;

    public String generateAccessToken(final AuthenticationUserInfo authInfo) {
        return buildToken(authInfo, accessExpirationTime);
    }

    public String generateRefreshToken(final AuthenticationUserInfo authInfo) {
        return buildToken(authInfo, refreshExpirationTime);
    }

    private String buildToken(final AuthenticationUserInfo authInfo, final long expirationTime) {
        final var now = System.currentTimeMillis();

        return Jwts.builder()
                .issuer(issuer)
                .subject(authInfo.publicId().toString())
                .claim("token_version", authInfo.tokenVersion())
                .claim("username", authInfo.username())
                .issuedAt(new Date(now))
                .expiration(new Date(now + expirationTime))
                .signWith(getSignKey())
                .compact();
    }

    public String extractSubject(final String token) {
        return parseClaims(token).getSubject();
    }

    public Integer extractTokenVersion(final String token) {
        return parseClaims(token).get("token_version", Integer.class);
    }

    public boolean isTokenValid (final String token) {
        try {
            // throws if expired, malformed, wrong signature
            parseClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    private Claims parseClaims(final String token) {
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
