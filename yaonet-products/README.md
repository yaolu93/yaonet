# yaonet-products

Spring Boot product service for the yaonet hybrid microservices architecture.

## Run locally

```bash
cd yaonet-products
mvn spring-boot:run
```

Default API:
- `GET /api/products`
- `GET /api/products/{id}`
- `POST /api/products`
- `PUT /api/products/{id}`
- `DELETE /api/products/{id}`

## Environment variables

- `PRODUCTS_DB_URL` (default: `jdbc:postgresql://localhost:5432/yaonet_db`)
- `PRODUCTS_DB_USER` (default: `yaonet_user`)
- `PRODUCTS_DB_PASSWORD` (default: `yaonet_secure_pwd_2024`)
- `SERVER_PORT` (default: `8080`)

## Messaging (Kafka + RabbitMQ)

This service publishes product domain events after successful write operations:

- `product.created`
- `product.updated`
- `product.deleted`

Default targets:

- Kafka topic: `yaonet.product.events`
- RabbitMQ queue: `yaonet.product.events`

Delivery architecture:

- Write-side transaction stores event into `outbox_events`
- Scheduler dispatches outbox rows to Kafka + RabbitMQ
- Built-in consumers process normal events
- Failures are routed to Kafka DLT and RabbitMQ DLQ

Additional environment variables:

- `MESSAGING_ENABLED` (default: `true`)
- `KAFKA_ENABLED` (default: `true`)
- `KAFKA_BOOTSTRAP_SERVERS` (default: `localhost:9092`)
- `KAFKA_TOPIC_PRODUCT_EVENTS` (default: `yaonet.product.events`)
- `RABBITMQ_ENABLED` (default: `true`)
- `RABBITMQ_HOST` (default: `localhost`)
- `RABBITMQ_PORT` (default: `5672`)
- `RABBITMQ_USERNAME` (default: `guest`)
- `RABBITMQ_PASSWORD` (default: `guest`)
- `RABBITMQ_VHOST` (default: `/`)
- `RABBITMQ_PRODUCT_EVENTS_QUEUE` (default: `yaonet.product.events`)
- `RABBITMQ_PRODUCT_EVENTS_DLX` (default: `yaonet.product.events.dlx`)
- `RABBITMQ_PRODUCT_EVENTS_DLQ` (default: `yaonet.product.events.dlq`)
- `RABBITMQ_PRODUCT_EVENTS_DLQ_ROUTING_KEY` (default: `yaonet.product.events.dlq`)
- `RABBITMQ_CONSUMER_ENABLED` (default: `true`)
- `KAFKA_TOPIC_PRODUCT_EVENTS_DLT` (default: `yaonet.product.events.DLT`)
- `KAFKA_CONSUMER_ENABLED` (default: `true`)
- `KAFKA_CONSUMER_GROUP` (default: `yaonet-products-kafka-consumer`)
- `KAFKA_DLT_CONSUMER_GROUP` (default: `yaonet-products-kafka-dlt-consumer`)
- `OUTBOX_DISPATCH_INTERVAL_MS` (default: `2000`)

Quick run checklist:

1. Start brokers: `docker compose up -d rabbitmq kafka`
2. Start service: `cd yaonet-products && mvn spring-boot:run`
3. Call `POST/PUT/DELETE /api/products` once.
4. Check logs for:
	- outbox dispatch
	- Kafka consumer receive
	- RabbitMQ consumer receive
5. To test DLQ quickly, publish a malformed JSON message to main queue/topic and verify:
	- RabbitMQ DLQ listener logs it
	- Kafka DLT listener logs it
