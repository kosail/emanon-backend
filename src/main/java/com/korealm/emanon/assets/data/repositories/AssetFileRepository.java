package com.korealm.emanon.assets.data.repositories;

import com.korealm.emanon.assets.data.models.AssetFile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AssetFileRepository extends JpaRepository<AssetFile, Long> {
}
