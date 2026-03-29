package com.yaonet.products.messaging;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Component
public class OutboxDispatcher {

    private static final Logger log = LoggerFactory.getLogger(OutboxDispatcher.class);

    private final OutboxEventRepository outboxEventRepository;
    private final ProductEventPublisher productEventPublisher;
    private final ObjectMapper objectMapper;

    @Value("${yaonet.messaging.enabled:true}")
    private boolean messagingEnabled;

    public OutboxDispatcher(
        OutboxEventRepository outboxEventRepository,
        ProductEventPublisher productEventPublisher,
        ObjectMapper objectMapper
    ) {
        this.outboxEventRepository = outboxEventRepository;
        this.productEventPublisher = productEventPublisher;
        this.objectMapper = objectMapper;
    }

    @Scheduled(fixedDelayString = "${yaonet.messaging.outbox.dispatch-interval-ms:2000}")
    @Transactional
    public void dispatchPendingEvents() {
        if (!messagingEnabled) {
            return;
        }

        List<OutboxEvent> pending = outboxEventRepository.findTop100ByPublishedAtIsNullOrderByCreatedAtAsc();
        if (pending.isEmpty()) {
            return;
        }

        for (OutboxEvent row : pending) {
            try {
                ProductEvent event = objectMapper.readValue(row.getPayload(), ProductEvent.class);
                productEventPublisher.publish(event);
                row.markPublished();
            } catch (Exception e) {
                row.registerFailure(e.getMessage());
                log.warn("Outbox dispatch failed eventId={} attempts={}", row.getEventId(), row.getAttempts(), e);
            }
        }
    }
}
