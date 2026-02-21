-- init.sql
CREATE DATABASE IF NOT EXISTS spring_starter;
USE spring_starter;

-- =========================================================
-- 0) bootstrap log (기존)
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
-- 1) Tables for UserMapper (추가)
-- =========================================================

-- 1-1) user table
-- mapper에서 사용: id, email, username, avatar_file_id, active, deleted, salt, status
CREATE TABLE IF NOT EXISTS `user` (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    email VARCHAR(255) NOT NULL,
    username VARCHAR(100) NOT NULL,

    -- avatar 파일을 별도 테이블로 관리한다면 FK로 바꿔도 됨 (일단 BIGINT만)
    avatar_file_id BIGINT NULL,

    -- 활성/삭제 플래그
    active BOOLEAN NOT NULL DEFAULT TRUE,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,

    -- access_token 조회에서 u.salt 사용
    salt VARCHAR(255) NULL,

    -- resultMap에 status가 매핑되어 있으나, selectUserData에는 active만 있으니
    -- 향후 확장 고려해 status 컬럼도 포함(없으면 매핑 null)
    status VARCHAR(50) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_user_email (email),
    UNIQUE KEY uk_user_username (username),
    KEY idx_user_deleted (deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 1-2) user_role table
-- mapper에서 사용: user_role.user (컬럼명 자체가 예약어 가능성) / role
-- 쿼리: left join user_role UR on UR.user = U.id
--      UR.role roleId
CREATE TABLE IF NOT EXISTS user_role (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    `user` BIGINT NOT NULL,
    role VARCHAR(50) NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- 같은 유저에 같은 role 중복 방지
    UNIQUE KEY uk_user_role (`user`, role),
    KEY idx_user_role_user (`user`),
    CONSTRAINT fk_user_role_user
      FOREIGN KEY (`user`) REFERENCES `user`(id)
      ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 1-3) access_token table
-- mapper에서 사용: id, user, token, revoked
-- 쿼리:
--   FROM access_token act
--   LEFT JOIN user u ON act.user = u.id
--   WHERE act.token = #{token} AND act.revoked is false
CREATE TABLE IF NOT EXISTS access_token (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    `user` BIGINT NOT NULL,

    token VARCHAR(512) NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uk_access_token_token (token),
    KEY idx_access_token_user (`user`),
    KEY idx_access_token_revoked (revoked),

    CONSTRAINT fk_access_token_user
      FOREIGN KEY (`user`) REFERENCES `user`(id)
      ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- (선택) 샘플 데이터가 필요하면 아래처럼 추가 가능
-- =========================================================
-- INSERT INTO `user` (email, username, active, deleted, salt, status)
-- SELECT 'admin@example.com', 'admin', TRUE, FALSE, 'salt-demo', 'ACTIVE'
-- WHERE NOT EXISTS (SELECT 1 FROM `user` WHERE username='admin');