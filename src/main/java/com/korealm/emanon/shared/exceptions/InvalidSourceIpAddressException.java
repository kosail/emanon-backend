package com.korealm.emanon.shared.exceptions;

import org.springframework.http.HttpStatus;

public class InvalidSourceIpAddressException extends DomainException {
    public InvalidSourceIpAddressException(HttpStatus httpStatus, String message) {
        super(httpStatus, message);
    }
}
