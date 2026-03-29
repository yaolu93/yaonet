package com.yaonet.products;

import jakarta.validation.Valid;
import com.yaonet.products.messaging.OutboxService;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/products")
public class ProductController {

    private final ProductRepository productRepository;
    private final FlaskTokenValidator flaskTokenValidator;
    private final OutboxService outboxService;

    public ProductController(
        ProductRepository productRepository,
        FlaskTokenValidator flaskTokenValidator,
        OutboxService outboxService
    ) {
        this.productRepository = productRepository;
        this.flaskTokenValidator = flaskTokenValidator;
        this.outboxService = outboxService;
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
    @Transactional
    public Product create(
        @Valid @RequestBody Product product,
        @RequestHeader(name = "Authorization", required = false) String authorization,
        @RequestHeader(name = "X-Yaonet-User-Id", required = false) String userId
    ) {
        requireValidToken(authorization, userId);
        product.setId(null);
        Product created = productRepository.save(product);
        outboxService.enqueueCreated(created, userId);
        return created;
    }

    @PutMapping("/{id}")
    @Transactional
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
        Product updated = productRepository.save(existing);
        outboxService.enqueueUpdated(updated, userId);
        return updated;
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Transactional
    public void delete(
        @PathVariable Long id,
        @RequestHeader(name = "Authorization", required = false) String authorization,
        @RequestHeader(name = "X-Yaonet-User-Id", required = false) String userId
    ) {
        requireValidToken(authorization, userId);
        Product existing = productRepository.findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found"));
        productRepository.deleteById(id);
        outboxService.enqueueDeleted(existing.getId(), userId);
    }
}
