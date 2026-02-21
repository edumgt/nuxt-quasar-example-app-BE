-- init.sql
CREATE DATABASE IF NOT EXISTS spring_starter;
USE spring_starter;

-- =========================================================
-- 0) bootstrap log
-- =========================================================
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

-- =========================================================
-- 1) Core tables for JWT login flow
-- =========================================================

CREATE TABLE IF NOT EXISTS `user` (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_user BIGINT NULL,
    created_date DATETIME NULL,
    updated_user BIGINT NULL,
    updated_date DATETIME NULL,

    email VARCHAR(255) NOT NULL,
    username VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,

    default_locale TINYINT(1) NULL,
    avatar_file_id BIGINT NULL,
    cover_file_id BIGINT NULL,

    active BOOLEAN NOT NULL DEFAULT TRUE,
    salt VARCHAR(255) NULL,
    status VARCHAR(50) NULL,

    UNIQUE KEY uk_user_email (email),
    UNIQUE KEY uk_user_username (username),
    KEY idx_user_deleted (deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS api_client (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    created_user BIGINT NULL,
    created_date DATETIME NULL,
    updated_user BIGINT NULL,
    updated_date DATETIME NULL,

    api_name VARCHAR(100) NOT NULL,
    api_token VARCHAR(255) NULL,
    by_pass BOOLEAN DEFAULT FALSE,
    status BOOLEAN DEFAULT TRUE,

    UNIQUE KEY uk_api_client_name (api_name),
    UNIQUE KEY uk_api_client_token (api_token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS user_agent (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    agent VARCHAR(255) NOT NULL,
    KEY idx_user_agent_agent (agent)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS login_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    userAgent BIGINT NULL,
    login_from TINYINT(1) NULL,
    ip VARCHAR(50) NULL,
    host_name VARCHAR(100) NULL,
    `user` BIGINT NULL,
    device_id VARCHAR(125) NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    KEY idx_login_log_device (device_id),
    KEY idx_login_log_user (`user`),
    KEY idx_login_log_user_agent (userAgent),
    CONSTRAINT fk_login_log_user FOREIGN KEY (`user`) REFERENCES `user`(id) ON DELETE SET NULL,
    CONSTRAINT fk_login_log_user_agent FOREIGN KEY (userAgent) REFERENCES user_agent(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS access_token (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    token VARCHAR(100) NOT NULL,
    fcm_token VARCHAR(255) NULL,
    fcm_enable BOOLEAN DEFAULT TRUE,
    service TINYINT(2) DEFAULT 1,
    `user` BIGINT NULL,
    api_client BIGINT NULL,
    login_log BIGINT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    expires_at DATETIME NULL,
    created_date DATETIME NULL,
    logouted_date DATETIME NULL,
    lastest_active DATETIME NULL,

    UNIQUE KEY uk_access_token_token (token),
    KEY idx_access_token_user (`user`),
    KEY idx_access_token_api_client (api_client),
    KEY idx_access_token_login_log (login_log),
    KEY idx_access_token_revoked (revoked),

    CONSTRAINT fk_access_token_user FOREIGN KEY (`user`) REFERENCES `user`(id) ON DELETE CASCADE,
    CONSTRAINT fk_access_token_api_client FOREIGN KEY (api_client) REFERENCES api_client(id) ON DELETE SET NULL,
    CONSTRAINT fk_access_token_login_log FOREIGN KEY (login_log) REFERENCES login_log(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Optional table referenced by User many-to-many mapping
CREATE TABLE IF NOT EXISTS user_role (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    `user` BIGINT NOT NULL,
    role BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_role (`user`, role),
    KEY idx_user_role_user (`user`),
    CONSTRAINT fk_user_role_user FOREIGN KEY (`user`) REFERENCES `user`(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- 2) Seed data for login test
--   공통 평문 비밀번호: 1234
--   bcrypt hash: $2a$10$VvK6.mMEdt9sdEjIFE.g8uN4I33dbV9luiFkhGV773wPIBHLEamhe
-- =========================================================
INSERT INTO api_client (api_name, api_token, by_pass, status)
SELECT 'default', '10b7b78c-6544-4a04-9839-8f8c10d9445e', TRUE, TRUE
WHERE NOT EXISTS (SELECT 1 FROM api_client WHERE api_name = 'default');

INSERT INTO `user` (email, username, password, active, deleted, salt, status)
SELECT 'admin@mydomain.com', 'admin', '$2a$10$VvK6.mMEdt9sdEjIFE.g8uN4I33dbV9luiFkhGV773wPIBHLEamhe', TRUE, FALSE, '0d1af063-ed5c-4387-91b2-04292799b06c', 'ACTIVE'
WHERE NOT EXISTS (SELECT 1 FROM `user` WHERE username='admin');

INSERT INTO `user` (email, username, password, active, deleted, salt, status)
SELECT 'manager@mydomain.com', 'manager', '$2a$10$VvK6.mMEdt9sdEjIFE.g8uN4I33dbV9luiFkhGV773wPIBHLEamhe', TRUE, FALSE, '84e85f3b-2eb8-42d2-9c22-8e521e8f79c8', 'ACTIVE'
WHERE NOT EXISTS (SELECT 1 FROM `user` WHERE username='manager');

INSERT INTO `user` (email, username, password, active, deleted, salt, status)
SELECT 'tester@mydomain.com', 'tester', '$2a$10$VvK6.mMEdt9sdEjIFE.g8uN4I33dbV9luiFkhGV773wPIBHLEamhe', TRUE, FALSE, '293a5422-3d37-46dd-9476-3898b9e6d2db', 'ACTIVE'
WHERE NOT EXISTS (SELECT 1 FROM `user` WHERE username='tester');
