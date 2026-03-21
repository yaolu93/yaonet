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
