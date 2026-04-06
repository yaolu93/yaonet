package com.yaonet.products.reflectiondemo;

@DemoComponent("miniProductController")
public class MiniProductController {

    @DemoValue("yaonet.product-service")
    private String serviceName;

    @DemoGetMapping("/api/products")
    public String listProducts() {
        return "Listing products from " + serviceName;
    }

    @DemoGetMapping("/api/products/42")
    public String getProduct42() {
        return "Product 42 from " + serviceName;
    }
}