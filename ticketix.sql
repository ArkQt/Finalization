-- Create Database
CREATE DATABASE IF NOT EXISTS TICKETIX;
USE TICKETIX;

-- Drop tables if they already exist (in correct order to handle foreign key constraints)
DROP TABLE IF EXISTS BRANCH;
DROP TABLE IF EXISTS TICKET;
DROP TABLE IF EXISTS PAYMENT;
DROP TABLE IF EXISTS RESERVE_SEAT;
DROP TABLE IF EXISTS RESERVE;
DROP TABLE IF EXISTS SEAT;
DROP TABLE IF EXISTS MOVIE_SCHEDULE;
DROP TABLE IF EXISTS MOVIE;
DROP TABLE IF EXISTS USER_ACCOUNT;
DROP TABLE IF EXISTS TICKET_FOOD;

-- 1️⃣ USER_ACCOUNT Table
CREATE TABLE USER_ACCOUNT(
    acc_id INT PRIMARY KEY AUTO_INCREMENT,
    firstName VARCHAR(50) NOT NULL,
    lastName VARCHAR(50) NOT NULL,
    contNo VARCHAR(12),
    email VARCHAR(50) UNIQUE NOT NULL,
    address VARCHAR(50),
    birthdate DATE,
    user_password VARCHAR(70),
    time_created DATETIME,
    user_status ENUM('online', 'offline') DEFAULT 'offline'
) ENGINE=InnoDB;

ALTER TABLE USER_ACCOUNT
ADD COLUMN reset_token_hash VARCHAR(64) NULL,
ADD COLUMN reset_token_expires_at DATETIME NULL;

ALTER TABLE USER_ACCOUNT ADD COLUMN role VARCHAR(50) DEFAULT 'user';
UPDATE USER_ACCOUNT 
SET role = 'admin' 
WHERE email = 'ticketix0@gmail.com';

CREATE TABLE IF NOT EXISTS BRANCH(
branch_id INT PRIMARY KEY auto_increment,
branch_name VARCHAR(100) NOT NULL,
branch_location VARCHAR(150),
contact_number VARCHAR (15)
) ENGINE=InnoDB;

INSERT INTO BRANCH (branch_name, branch_location, contact_number)
VALUES
('Light Residences', 'EDSA Cor Madison St., Brgy Barangka Ilaya, Mandaluyong City', '09171234567'),
('SM City Baguio', 'Luneta Hill, Upper Session Road, Baguio City', '09179876543'),
('SM City Marikina', 'Marcos Highway, Kalumpang, Marikina City NCR Second', '09171239876'),
('SM Aura Premier', 'McKinley Parkway, Bonifacio Global City, Taguig City', '09171239876'),
('SM Center Angono', 'E. Rodriguez Jr. Avenue, Angono, Rizal', '09171239876'),
('SM City Sta. Mesa', 'G. Araneta Ave., Sta. Mesa, Manila', '09171239876'),
('SM City Sto. Tomas', 'Poblacion, Sto. Tomas, Batangas', '09171239876'),
('SM Mall of Asia', 'Seaside Blvd., Pasay City', '09171239876'),
('SM Megacenter Cabanatuan', 'Brgy. Balintawak, Cabanatuan City, Nueva Ecija', '09171239876');

SELECT branch_id, branch_name FROM BRANCH;


-- 2️⃣ MOVIE Table
CREATE TABLE MOVIE(
    movie_show_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(50),
    genre VARCHAR(100),
    duration INT,
    rating VARCHAR(20),
    movie_descrp TEXT,
    image_poster VARCHAR(100),
    carousel_image VARCHAR(100),
    now_showing BOOLEAN DEFAULT FALSE,
    coming_soon BOOLEAN DEFAULT FALSE
) ENGINE=InnoDB;

ALTER TABLE MOVIE ADD COLUMN is_deleted TINYINT(1) DEFAULT 0;
ALTER TABLE MOVIE ADD COLUMN deleted_at DATETIME NULL;
CREATE INDEX idx_is_deleted ON MOVIE(is_deleted);
SHOW COLUMNS FROM MOVIE;

SELECT movie_show_id, title, now_showing FROM MOVIE;

ALTER TABLE MOVIE ADD COLUMN carousel_image VARCHAR(100);
ALTER TABLE MOVIE MODIFY COLUMN genre VARCHAR(100);
ALTER TABLE MOVIE ADD COLUMN now_showing BOOLEAN DEFAULT FALSE;
ALTER TABLE MOVIE ADD COLUMN coming_soon BOOLEAN DEFAULT FALSE;

-- 3️⃣ MOVIE_SCHEDULE Table
CREATE TABLE MOVIE_SCHEDULE(
    schedule_id INT PRIMARY KEY AUTO_INCREMENT,
    movie_show_id INT NOT NULL,
    show_date DATE,
    show_hour TIME,
    FOREIGN KEY (movie_show_id) REFERENCES MOVIE(movie_show_id)
) ENGINE=InnoDB;
INSERT INTO MOVIE_SCHEDULE (movie_show_id, show_date, show_hour, branch_id)
VALUES
-- Light Residences (branch_id = 1)
(22, CURDATE(), '12:00:00', 31),
(22, CURDATE(), '16:00:00', 31),
(23, CURDATE(), '14:00:00', 31),
(23, CURDATE(), '18:00:00', 31),

-- SM City Baguio (branch_id = 2)
(22, CURDATE(), '11:00:00', 32),
(22, CURDATE(), '15:00:00', 32),
(23, CURDATE(), '13:00:00', 32),
(23, CURDATE(), '17:00:00', 32),

-- SM City Marikina (branch_id = 3)
(22, CURDATE(), '12:30:00', 33),
(22, CURDATE(), '16:30:00', 33),
(23, CURDATE(), '14:30:00', 33),
(23, CURDATE(), '18:30:00', 33),

-- SM Aura Premier (branch_id = 4)
(22, CURDATE(), '11:15:00', 34), 
(22, CURDATE(), '15:15:00', 34),
(23, CURDATE(), '13:15:00', 34),
(23, CURDATE(), '17:15:00', 34),

-- SM Center Angono (branch_id = 5)
(22, CURDATE(), '12:00:00', 35),
(22, CURDATE(), '16:00:00', 35),
(23, CURDATE(), '14:00:00', 35),
(23, CURDATE(), '18:00:00', 35),

-- SM City Sta. Mesa (branch_id = 6)
(22, CURDATE(), '11:45:00', 36),
(22, CURDATE(), '15:45:00', 36),
(23, CURDATE(), '13:45:00', 36),
(23, CURDATE(), '17:45:00', 36),


-- SM City Sto. Tomas (branch_id = 7)
(22, CURDATE(), '12:30:00', 37),
(22, CURDATE(), '16:30:00', 37),
(23, CURDATE(), '14:30:00', 37),
(23, CURDATE(), '18:30:00', 37),

-- SM Mall of Asia (branch_id = 8)
(22, CURDATE(), '11:00:00', 38), 
(22, CURDATE(), '15:00:00', 38),
(23, CURDATE(), '13:00:00', 38),
(23, CURDATE(), '17:00:00', 38),

-- SM Megacenter Cabanatuan (branch_id = 9)
(22, CURDATE(), '12:15:00', 39), 
(22, CURDATE(), '16:15:00', 39),
(23, CURDATE(), '14:15:00', 39),
(23, CURDATE(), '18:15:00', 39);

ALTER TABLE MOVIE_SCHEDULE
ADD COLUMN branch_id INT NOT NULL;

ALTER TABLE MOVIE_SCHEDULE
ADD CONSTRAINT fk_branch FOREIGN KEY (branch_id) REFERENCES BRANCH(branch_id);

-- 4️⃣ SEAT Table
CREATE TABLE SEAT(
    seat_id INT PRIMARY KEY AUTO_INCREMENT,
    seat_number VARCHAR(10),
    seat_type ENUM('Regular','VIP') DEFAULT 'Regular',
    seat_price DECIMAL(10,2)
) ENGINE=InnoDB;

-- 5️⃣ RESERVE Table
CREATE TABLE RESERVE(
    reservation_id INT PRIMARY KEY AUTO_INCREMENT,
    acc_id INT,
    schedule_id INT,
    reserve_date DATETIME,
    ticket_amount INT,
    sum_price DECIMAL(10,2),
    FOREIGN KEY (acc_id) REFERENCES USER_ACCOUNT(acc_id),
    FOREIGN KEY (schedule_id) REFERENCES MOVIE_SCHEDULE(schedule_id)
) ENGINE=InnoDB;

ALTER TABLE RESERVE ADD COLUMN food_total DECIMAL(10,2) DEFAULT 0.00;


-- 6️⃣ RESERVE_SEAT Table
CREATE TABLE RESERVE_SEAT(
    reserve_seat_id INT PRIMARY KEY AUTO_INCREMENT,
    reservation_id INT,
    seat_id INT,
    FOREIGN KEY (reservation_id) REFERENCES RESERVE(reservation_id),
    FOREIGN KEY (seat_id) REFERENCES SEAT(seat_id)
) ENGINE=InnoDB;

-- 7️⃣ PAYMENT Table
CREATE TABLE PAYMENT(
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    reserve_id INT,
    payment_type ENUM('cash','credit','e-wallet'),
    amount_paid DECIMAL(10,2),
    payment_status ENUM('paid','pending','not-yet'),
    payment_date DATETIME,
    reference_number VARCHAR(100),
    FOREIGN KEY (reserve_id) REFERENCES RESERVE(reservation_id)
) ENGINE=InnoDB;

CREATE TABLE TICKET(
ticket_id INT PRIMARY KEY auto_increment,
reserve_id INT,
payment_id INT,
ticket_number VARCHAR(50),
date_issued DATETIME,
ticket_status ENUM('valid','cancelled','refunded'),
FOREIGN KEY (payment_id) REFERENCES PAYMENT(payment_id),
FOREIGN KEY (reserve_id) REFERENCES RESERVE(reservation_id)
);

ALTER TABLE TICKET
ADD COLUMN e_ticket_code VARCHAR(100) UNIQUE,
ADD COLUMN e_ticket_file VARCHAR(255);
ALTER TABLE TICKET MODIFY ticket_status ENUM('valid','cancelled','refunded');

CREATE TABLE FOOD (
food_id INT PRIMARY KEY AUTO_INCREMENT,
food_name VARCHAR(50) NOT NULL,
food_price DECIMAL(10,2) DEFAULT 0.00
) ENGINE=InnoDB;
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE FOOD;

ALTER TABLE FOOD ADD COLUMN image_path VARCHAR(255);
INSERT INTO FOOD(food_name, food_price, image_path) VALUES
('All-In-Combo', 199.00, 'images/all-in.png'),
('HotCoke', 165.00, 'images/hotdog-coke.png'),
('Froke', 120.00, 'images/fries-coke.png'),
('Fries', 50.00, 'images/fries-solo.png'),
('Hotdog', 60.00, 'images/hotdog-solo.png'),
('Coke', 40.00, 'images/coke-solo.png'),
('Popcorn', 40.00, 'images/popcorn-solo.png');

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE FOOD;
SET FOREIGN_KEY_CHECKS = 1;
TRUNCATE TABLE FOOD;

CREATE TABLE TICKET_FOOD (
    ticket_food_id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_id INT NOT NULL,
    food_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    FOREIGN KEY (ticket_id) REFERENCES TICKET(ticket_id) ON DELETE CASCADE,
    FOREIGN KEY (food_id) REFERENCES FOOD(food_id) ON DELETE CASCADE,
    UNIQUE KEY unique_ticket_food (ticket_id, food_id)
) ENGINE=InnoDB;

ALTER TABLE TICKET_FOOD
ADD COLUMN quantity INT NOT NULL DEFAULT 1;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE MOVIE_SCHEDULE;
SET FOREIGN_KEY_CHECKS = 1;

DELETE FROM MOVIE_SCHEDULE;
TRUNCATE TABLE BRANCH;
TRUNCATE TABLE MOVIE_SCHEDULE;

SET SQL_SAFE_UPDATES = 0;

DELETE FROM MOVIE_SCHEDULE;  -- delete child rows first
DELETE FROM BRANCH;          -- then delete branches

SET SQL_SAFE_UPDATES = 1;    -- re-enable safe updates

SET SQL_SAFE_UPDATES = 0;
DELETE FROM BRANCH;
SET SQL_SAFE_UPDATES = 1;

SELECT branch_id, branch_name FROM BRANCH;
SELECT movie_show_id, title, now_showing FROM MOVIE;
DESCRIBE MOVIE_SCHEDULE;

SELECT * FROM BRANCH;
SELECT * FROM USER_ACCOUNT;
SELECT * FROM MOVIE;
SELECT * FROM MOVIE_SCHEDULE;
SELECT * FROM SEAT;
SELECT * FROM RESERVE;
SELECT * FROM RESERVE_SEAT;
SELECT * FROM PAYMENT;
SELECT * FROM TICKET;
SELECT * FROM FOOD;
SELECT * FROM TICKET_FOOD;
SHOW COLUMNS FROM RESERVE;

ALTER TABLE TICKET_FOOD
ADD COLUMN IF NOT EXISTS ticket_food_id INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- Add the unique constraint
ALTER TABLE TICKET_FOOD 
ADD UNIQUE KEY unique_ticket_food (ticket_id, food_id);