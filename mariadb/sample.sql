-- 데이터베이스 생성
CREATE DATABASE skeleton;

-- 데이터베이스 사용
USE skeleton;

-- user 테이블 생성
CREATE TABLE user (
    id INT AUTO_INCREMENT PRIMARY KEY,  -- 기본 키 및 자동 증가
    userName VARCHAR(255) NOT NULL,    -- 사용자 이름
    password VARCHAR(255) NOT NULL     -- 비밀번호
);

INSERT INTO user (userName, password) VALUES ('Alice', 'password123');
INSERT INTO user (userName, password) VALUES ('Bob', 'securepass456');

-- 테이블 확인
SHOW TABLES;

-- 테이블 구조 확인
DESCRIBE user;

SELECT * FROM skeketon.user;
