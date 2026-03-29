package com.yaonet.products.messaging;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yaonet.products.Product;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class ProductEventPublisher {

    private static final Logger log = LoggerFactory.getLogger(ProductEventPublisher.class);

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final RabbitTemplate rabbitTemplate;
    private final ObjectMapper objectMapper;

    @Value("${yaonet.messaging.enabled:true}")
    private boolean messagingEnabled;

    @Value("${yaonet.messaging.kafka.enabled:true}")
    private boolean kafkaEnabled;

    @Value("${yaonet.messaging.kafka.topic:yaonet.product.events}")
    private String kafkaTopic;

    @Value("${yaonet.messaging.rabbitmq.enabled:true}")
    private boolean rabbitEnabled;

    @Value("${yaonet.messaging.rabbitmq.queue:yaonet.product.events}")
    private String rabbitQueue;

    public ProductEventPublisher(
        KafkaTemplate<String, String> kafkaTemplate,
        RabbitTemplate rabbitTemplate,
        ObjectMapper objectMapper
    ) {
        this.kafkaTemplate = kafkaTemplate;
        this.rabbitTemplate = rabbitTemplate;
        this.objectMapper = objectMapper;
    }

    public void publishCreated(Product product, String actorId) {
        publish("product.created", product, actorId);
    }

    public void publishUpdated(Product product, String actorId) {
        publish("product.updated", product, actorId);
    }

    public void publishDeleted(Long productId, String actorId) {
        Map<String, Object> payload = Map.of("id", productId);
        ProductEvent event = ProductEvent.of(
            "product.deleted",
            String.valueOf(productId),
            actorId,
            payload
        );
        publish(event);
    }

    public void publish(ProductEvent event) {
        publishInternal(event);
    }

    private void publish(String eventType, Product product, String actorId) {
        ProductEvent event = ProductEvent.of(
            eventType,
            String.valueOf(product.getId()),
            actorId,
            toPayload(product)
        );
        publish(event);
    }

    private Map<String, Object> toPayload(Product product) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("id", product.getId());
        payload.put("name", product.getName());
        payload.put("description", product.getDescription());
        payload.put("price", product.getPrice());
        payload.put("stock", product.getStock());
        payload.put("imageUrl", product.getImageUrl());
        payload.put("createdAt", product.getCreatedAt());
        payload.put("updatedAt", product.getUpdatedAt());
        return payload;
    }

    private void publishInternal(ProductEvent event) {
        if (!messagingEnabled) {
            return;
        }

        String message;
        try {
            message = objectMapper.writeValueAsString(event);
        } catch (JsonProcessingException e) {
            log.warn("Failed to serialize product event {}", event.eventType(), e);
            return;
        }

        if (kafkaEnabled) {
            try {
                kafkaTemplate.send(kafkaTopic, event.aggregateId(), message);
            } catch (Exception e) {
                log.warn("Failed to publish event to Kafka topic {}", kafkaTopic, e);
            }
        }

        if (rabbitEnabled) {
            try {
                rabbitTemplate.convertAndSend("", rabbitQueue, message);
            } catch (Exception e) {
                log.warn("Failed to publish event to RabbitMQ queue {}", rabbitQueue, e);
            }
        }
    }
}
