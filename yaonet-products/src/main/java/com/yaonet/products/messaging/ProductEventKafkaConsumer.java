package com.yaonet.products.messaging;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "yaonet.messaging.kafka.consumer-enabled", havingValue = "true", matchIfMissing = true)
public class ProductEventKafkaConsumer {

    private static final Logger log = LoggerFactory.getLogger(ProductEventKafkaConsumer.class);

    private final ObjectMapper objectMapper;

    public ProductEventKafkaConsumer(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @KafkaListener(
        topics = "${yaonet.messaging.kafka.topic:yaonet.product.events}",
        groupId = "${yaonet.messaging.kafka.consumer-group:yaonet-products-kafka-consumer}",
        containerFactory = "kafkaListenerContainerFactory"
    )
    public void consume(String message) throws Exception {
        ProductEvent event = objectMapper.readValue(message, ProductEvent.class);
        log.info("Kafka consumed event type={} aggregateId={} eventId={}",
            event.eventType(), event.aggregateId(), event.eventId());

        // Simulate validation path so malformed messages can be routed to DLT by the error handler.
        if (event.eventType() == null || event.eventType().isBlank()) {
            throw new IllegalArgumentException("event_type must not be blank");
        }
    }

    @KafkaListener(
        topics = "${yaonet.messaging.kafka.dlt-topic:yaonet.product.events.DLT}",
        groupId = "${yaonet.messaging.kafka.dlt-consumer-group:yaonet-products-kafka-dlt-consumer}"
    )
    public void consumeDlt(String message) {
        log.error("Kafka DLT received message={}", message);
    }
}
