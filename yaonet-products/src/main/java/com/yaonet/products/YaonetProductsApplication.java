package com.yaonet.products;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class YaonetProductsApplication {

    public static void main(String[] args) {
        SpringApplication.run(YaonetProductsApplication.class, args);
    }
}
