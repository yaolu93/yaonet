package com.yaonet.products.messaging;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.DirectExchange;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.rabbit.config.SimpleRabbitListenerContainerFactory;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.HashMap;
import java.util.Map;

@Configuration
public class RabbitMessagingConfig {

    @Bean
    public Queue productEventsQueue(
        @Value("${yaonet.messaging.rabbitmq.queue:yaonet.product.events}") String queueName,
        @Value("${yaonet.messaging.rabbitmq.dlx:yaonet.product.events.dlx}") String dlxName,
        @Value("${yaonet.messaging.rabbitmq.dlq-routing-key:yaonet.product.events.dlq}") String dlqRoutingKey
    ) {
        Map<String, Object> args = new HashMap<>();
        args.put("x-dead-letter-exchange", dlxName);
        args.put("x-dead-letter-routing-key", dlqRoutingKey);
        return new Queue(queueName, true, false, false, args);
    }

    @Bean
    public DirectExchange productEventsDlx(
        @Value("${yaonet.messaging.rabbitmq.dlx:yaonet.product.events.dlx}") String dlxName
    ) {
        return new DirectExchange(dlxName, true, false);
    }

    @Bean
    public Queue productEventsDlq(
        @Value("${yaonet.messaging.rabbitmq.dlq:yaonet.product.events.dlq}") String dlqName
    ) {
        return new Queue(dlqName, true);
    }

    @Bean
    public Binding productEventsDlqBinding(
        Queue productEventsDlq,
        DirectExchange productEventsDlx,
        @Value("${yaonet.messaging.rabbitmq.dlq-routing-key:yaonet.product.events.dlq}") String dlqRoutingKey
    ) {
        return BindingBuilder.bind(productEventsDlq).to(productEventsDlx).with(dlqRoutingKey);
    }

    @Bean
    public SimpleRabbitListenerContainerFactory rabbitListenerContainerFactory(ConnectionFactory connectionFactory) {
        SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
        factory.setConnectionFactory(connectionFactory);
        factory.setDefaultRequeueRejected(false);
        return factory;
    }
}
