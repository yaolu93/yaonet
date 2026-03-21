INSERT INTO products (name, description, price, stock, image_url, created_at, updated_at)
VALUES
('DevOps Handbook', 'A practical guide to DevOps and platform engineering.', 39.99, 120, 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=800', NOW(), NOW()),
('Kubernetes T-Shirt', 'Cotton T-shirt for cloud native enthusiasts.', 24.90, 80, 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800', NOW(), NOW()),
('Mechanical Keyboard', 'Hot-swappable keyboard for programmers.', 89.00, 35, 'https://images.unsplash.com/photo-1511467687858-23d96c32e4ae?w=800', NOW(), NOW())
ON CONFLICT DO NOTHING;
