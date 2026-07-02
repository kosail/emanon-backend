package com.korealm.emanon.shared;

import com.korealm.emanon.shared.api.ApiErrorDto;
import com.korealm.emanon.shared.exceptions.DomainException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(DomainException.class)
    public ResponseEntity<ApiErrorDto> handleErrorResponse(DomainException err) {
        var apiError = ApiErrorDto.builder()
                .timestamp(err.getTimestamp())
                .message(err.getErrorMessage())
                .build();

        return ResponseEntity
                .status(err.getHttpStatus().value())
                .body(apiError);
    }
}
