package com.yaonet.products.messaging;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

public record ProductEvent(
    String eventId,
    String eventType,
    Instant occurredAt,
    String aggregate,
    String aggregateId,
    String actorId,
    Map<String, Object> payload
) {
    public static ProductEvent of(
        String eventType,
        String aggregateId,
        String actorId,
        Map<String, Object> payload
    ) {
        return new ProductEvent(
            UUID.randomUUID().toString(),
            eventType,
            Instant.now(),
            "product",
            aggregateId,
            actorId,
            payload
        );
    }
}
