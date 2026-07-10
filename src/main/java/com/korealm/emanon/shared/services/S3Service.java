package com.korealm.emanon.shared.services;

import com.korealm.emanon.shared.StorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.HeadObjectRequest;
import software.amazon.awssdk.services.s3.model.NoSuchKeyException;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

import java.time.Duration;

@Service
@RequiredArgsConstructor
public class S3Service implements StorageService {
    private final S3Client s3;
    private final S3Presigner presigner;

    @Value("${storage.bucket}") private String bucket;
    @Value("${storage.presigned_url_expiration_seconds}") private int presignedUrlExpirationSeconds;

    @Override
    public String generateUploadUrl(final String objectKey) {
        final var request = PutObjectPresignRequest.builder()
                .signatureDuration(Duration.ofSeconds(presignedUrlExpirationSeconds))
                .putObjectRequest(b -> b.bucket(bucket).key(objectKey))
                .build();

        return presigner.presignPutObject(request).url().toString();
    }

    @Override
    public String generateDownloadUrl(final String objectKey) {
        final var request = GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofSeconds(presignedUrlExpirationSeconds))
                .getObjectRequest(b -> b.bucket(bucket).key(objectKey))
                .build();

        return presigner.presignGetObject(request).url().toString();
    }

    @Override
    public boolean objectExists(final String objectKey) {
        try {
            s3.headObject(
                    HeadObjectRequest.builder()
                            .bucket(bucket)
                            .key(objectKey)
                            .build()
            );

            return true;
        } catch (NoSuchKeyException e) {
            return false;
        }
    }

    @Override
    public void deleteObject(final String objectKey) {
        s3.deleteObject(DeleteObjectRequest.builder()
                .bucket(bucket)
                .key(objectKey)
                .build()
        );
    }
}
