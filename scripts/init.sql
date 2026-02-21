CREATE DATABASE IF NOT EXISTS spring_starter;
USE spring_starter;

CREATE TABLE IF NOT EXISTS app_bootstrap_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    message VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO app_bootstrap_log (message)
SELECT 'mysql init script executed'
WHERE NOT EXISTS (
    SELECT 1 FROM app_bootstrap_log WHERE message = 'mysql init script executed'
);
