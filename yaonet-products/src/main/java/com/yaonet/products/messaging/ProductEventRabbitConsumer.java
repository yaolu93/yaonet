package com.yaonet.products.messaging;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "yaonet.messaging.rabbitmq.consumer-enabled", havingValue = "true", matchIfMissing = true)
public class ProductEventRabbitConsumer {

    private static final Logger log = LoggerFactory.getLogger(ProductEventRabbitConsumer.class);

    private final ObjectMapper objectMapper;

    public ProductEventRabbitConsumer(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @RabbitListener(queues = "${yaonet.messaging.rabbitmq.queue:yaonet.product.events}")
    public void consume(String message) throws Exception {
        ProductEvent event = objectMapper.readValue(message, ProductEvent.class);
        log.info("RabbitMQ consumed event type={} aggregateId={} eventId={}",
            event.eventType(), event.aggregateId(), event.eventId());

        if (event.eventType() == null || event.eventType().isBlank()) {
            throw new IllegalArgumentException("event_type must not be blank");
        }
    }

    @RabbitListener(queues = "${yaonet.messaging.rabbitmq.dlq:yaonet.product.events.dlq}")
    public void consumeDlq(String message) {
        log.error("RabbitMQ DLQ received message={}", message);
    }
}
