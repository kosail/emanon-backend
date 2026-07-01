package com.korealm.emanon;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.modulith.core.ApplicationModules;

@SpringBootTest
class EmanonApplicationTests {

	@Test
	void modulithTest() {
		ApplicationModules.of(EmanonApplication.class).verify();
	}

}
