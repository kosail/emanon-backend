package com.korealm.emanon.security;

import jakarta.servlet.http.HttpServletRequest;

public class SecurityHelper {

    public static String getClientIpAddress(HttpServletRequest request) {
        // Common headers used by proxies to pass the real client IP
        final String[] IP_HEADER_CANDIDATES = {
                "X-Forwarded-For",
                "Proxy-Client-IP",
                "WL-Proxy-Client-IP",
                "HTTP_X_FORWARDED_FOR",
                "HTTP_X_FORWARDED",
                "HTTP_CLUSTER_CLIENT_IP",
                "HTTP_CLIENT_IP",
                "X-Real-IP"
        };

        for (String header : IP_HEADER_CANDIDATES) {
            String ipList = request.getHeader(header);
            if (ipList != null && !ipList.isEmpty() && !"unknown".equalsIgnoreCase(ipList)) {
                // X-Forwarded-For can contain a comma-separated list of proxy IPs.
                // The first one is always the original client IP.
                return ipList.split(",")[0].trim();
            }
        }

        // Fallback if no proxy headers are present
        return request.getRemoteAddr();
    }
}
