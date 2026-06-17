-- ============================================================================
-- InfraLab Local Dev Stack — seed database
-- ============================================================================
-- Application:    VProfile (3-tier Java reference app)
-- Engine:         MariaDB 10.5+ / MySQL 8+
-- Charset:        utf8mb4
-- Purpose:        Demo schema + seed users for local development only.
--                 Passwords are bcrypt-hashed; all credentials are
--                 placeholders not intended for production use.
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;
SET SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';

-- ----------------------------------------------------------------------------
-- Table: role
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS `role`;
CREATE TABLE `role` (
  `id`         INT          NOT NULL AUTO_INCREMENT,
  `name`       VARCHAR(45)  NOT NULL,
  `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_role_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `role` (`name`) VALUES
  ('ROLE_USER'),
  ('ROLE_ADMIN');

-- ----------------------------------------------------------------------------
-- Table: user
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id`                 INT          NOT NULL AUTO_INCREMENT,
  `username`           VARCHAR(50)  NOT NULL,
  `email`              VARCHAR(255) NOT NULL,
  `password`           VARCHAR(100) NOT NULL,
  `date_of_birth`      DATE         DEFAULT NULL,
  `father_name`        VARCHAR(100) DEFAULT NULL,
  `mother_name`        VARCHAR(100) DEFAULT NULL,
  `gender`             VARCHAR(10)  DEFAULT NULL,
  `marital_status`     VARCHAR(20)  DEFAULT NULL,
  `permanent_address`  VARCHAR(255) DEFAULT NULL,
  `nationality`        VARCHAR(50)  DEFAULT NULL,
  `language`           VARCHAR(100) DEFAULT NULL,
  `primary_occupation` VARCHAR(100) DEFAULT NULL,
  `created_at`         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_username` (`username`),
  UNIQUE KEY `uk_user_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- All passwords are bcrypt hashes of 'admin123' — demo only.
INSERT INTO `user`
  (`username`, `email`, `password`, `date_of_birth`, `father_name`, `mother_name`,
   `gender`, `marital_status`, `permanent_address`, `nationality`, `language`, `primary_occupation`)
VALUES
  ('admin',  'admin@infralab.local',  '$2b$11$xtX1r8mu8YS80aBSsLq/nO5/ztnCodlfrXNdZtZIg.1FlKCwBJ.By',
    '1990-01-01', 'John Doe',  'Jane Doe',  'male',   'single',   'San Francisco, CA',  'American', 'English',           'System Administrator'),
  ('alice',  'alice@infralab.local',  '$2b$11$xtX1r8mu8YS80aBSsLq/nO5/ztnCodlfrXNdZtZIg.1FlKCwBJ.By',
    '1992-05-12', 'Robert Smith', 'Mary Smith', 'female', 'married', 'New York, NY',       'American', 'English, Spanish',  'Software Engineer'),
  ('bob',    'bob@infralab.local',    '$2b$11$xtX1r8mu8YS80aBSsLq/nO5/ztnCodlfrXNdZtZIg.1FlKCwBJ.By',
    '1988-11-03', 'Carl Johnson', 'Linda Johnson', 'male', 'married', 'Austin, TX',         'American', 'English',           'DevOps Engineer'),
  ('carol',  'carol@infralab.local',  '$2b$11$xtX1r8mu8YS80aBSsLq/nO5/ztnCodlfrXNdZtZIg.1FlKCwBJ.By',
    '1995-07-22', 'David Lee',  'Susan Lee', 'female', 'single',   'Seattle, WA',         'American', 'English, Mandarin', 'Data Engineer'),
  ('dave',   'dave@infralab.local',   '$2b$11$xtX1r8mu8YS80aBSsLq/nO5/ztnCodlfrXNdZtZIg.1FlKCwBJ.By',
    '1985-03-15', 'Frank Brown','Helen Brown','male',   'divorced', 'Boston, MA',          'American', 'English, French',   'Security Engineer');

-- ----------------------------------------------------------------------------
-- Table: user_role  (many-to-many join)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS `user_role`;
CREATE TABLE `user_role` (
  `user_id` INT NOT NULL,
  `role_id` INT NOT NULL,
  PRIMARY KEY (`user_id`,`role_id`),
  KEY `idx_user_role_role_id` (`role_id`),
  CONSTRAINT `fk_user_role_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_role_role` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `user_role` (`user_id`, `role_id`) VALUES
  (1, 2),  -- admin -> ROLE_ADMIN
  (2, 1),  -- alice -> ROLE_USER
  (3, 1),  -- bob   -> ROLE_USER
  (4, 1),  -- carol -> ROLE_USER
  (5, 1);  -- dave  -> ROLE_USER

SET FOREIGN_KEY_CHECKS=1;
