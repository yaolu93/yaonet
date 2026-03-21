package com.yaonet.products;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/products")
public class ProductController {

    private final ProductRepository productRepository;
    private final FlaskTokenValidator flaskTokenValidator;

    public ProductController(
        ProductRepository productRepository,
        FlaskTokenValidator flaskTokenValidator
    ) {
        this.productRepository = productRepository;
        this.flaskTokenValidator = flaskTokenValidator;
    }

    private void requireValidToken(String authorization, String userId) {
        if (!flaskTokenValidator.validate(authorization, userId)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid or expired token");
        }
    }

    @GetMapping
    public List<Product> list() {
        return productRepository.findAll();
    }

    @GetMapping("/{id}")
    public Product getById(@PathVariable Long id) {
        return productRepository.findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found"));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Product create(
        @Valid @RequestBody Product product,
        @RequestHeader(name = "Authorization", required = false) String authorization,
        @RequestHeader(name = "X-Yaonet-User-Id", required = false) String userId
    ) {
        requireValidToken(authorization, userId);
        product.setId(null);
        return productRepository.save(product);
    }

    @PutMapping("/{id}")
    public Product update(
        @PathVariable Long id,
        @Valid @RequestBody Product payload,
        @RequestHeader(name = "Authorization", required = false) String authorization,
        @RequestHeader(name = "X-Yaonet-User-Id", required = false) String userId
    ) {
        requireValidToken(authorization, userId);
        Product existing = productRepository.findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found"));

        existing.setName(payload.getName());
        existing.setDescription(payload.getDescription());
        existing.setPrice(payload.getPrice());
        existing.setStock(payload.getStock());
        existing.setImageUrl(payload.getImageUrl());
        return productRepository.save(existing);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(
        @PathVariable Long id,
        @RequestHeader(name = "Authorization", required = false) String authorization,
        @RequestHeader(name = "X-Yaonet-User-Id", required = false) String userId
    ) {
        requireValidToken(authorization, userId);
        if (!productRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found");
        }
        productRepository.deleteById(id);
    }
}
