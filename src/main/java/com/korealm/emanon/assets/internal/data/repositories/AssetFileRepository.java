package com.korealm.emanon.assets.internal.data.repositories;

import com.korealm.emanon.assets.internal.data.models.AssetFile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AssetFileRepository extends JpaRepository<AssetFile, Long> {
}
