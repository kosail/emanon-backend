package com.korealm.emanon.auth.internal.exception;

import com.korealm.emanon.shared.exceptions.DomainException;
import org.springframework.http.HttpStatus;

public class UserAlreadyExistsException extends DomainException {
    public UserAlreadyExistsException(HttpStatus httpStatus, String message) {
        super(httpStatus, message);
    }
}
