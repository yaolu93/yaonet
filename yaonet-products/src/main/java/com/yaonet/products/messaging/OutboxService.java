package com.yaonet.products.messaging;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yaonet.products.Product;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class OutboxService {

    private static final Logger log = LoggerFactory.getLogger(OutboxService.class);

    private final OutboxEventRepository outboxEventRepository;
    private final ObjectMapper objectMapper;

    public OutboxService(OutboxEventRepository outboxEventRepository, ObjectMapper objectMapper) {
        this.outboxEventRepository = outboxEventRepository;
        this.objectMapper = objectMapper;
    }

    public void enqueueCreated(Product product, String actorId) {
        enqueue(productEvent("product.created", product, actorId));
    }

    public void enqueueUpdated(Product product, String actorId) {
        enqueue(productEvent("product.updated", product, actorId));
    }

    public void enqueueDeleted(Long productId, String actorId) {
        ProductEvent event = ProductEvent.of(
            "product.deleted",
            String.valueOf(productId),
            actorId,
            Map.of("id", productId)
        );
        enqueue(event);
    }

    private ProductEvent productEvent(String type, Product product, String actorId) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("id", product.getId());
        payload.put("name", product.getName());
        payload.put("description", product.getDescription());
        payload.put("price", product.getPrice());
        payload.put("stock", product.getStock());
        payload.put("imageUrl", product.getImageUrl());
        payload.put("createdAt", product.getCreatedAt());
        payload.put("updatedAt", product.getUpdatedAt());

        return ProductEvent.of(type, String.valueOf(product.getId()), actorId, payload);
    }

    private void enqueue(ProductEvent event) {
        try {
            OutboxEvent row = new OutboxEvent();
            row.setEventId(event.eventId());
            row.setEventType(event.eventType());
            row.setAggregate(event.aggregate());
            row.setAggregateId(event.aggregateId());
            row.setActorId(event.actorId());
            row.setPayload(objectMapper.writeValueAsString(event));
            outboxEventRepository.save(row);
        } catch (JsonProcessingException e) {
            log.error("Failed to serialize event for outbox type={}", event.eventType(), e);
            throw new IllegalStateException("Failed to serialize outbox event", e);
        }
    }
}
