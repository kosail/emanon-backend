package com.korealm.emanon.auth.internal.exception;

import com.korealm.emanon.shared.exceptions.DomainException;
import org.springframework.http.HttpStatus;

public class IllegalUserStateException extends DomainException {
    public IllegalUserStateException(HttpStatus httpStatus, String message) {
        super(httpStatus, message);
    }
}
