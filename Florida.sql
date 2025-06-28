-- =============================================
-- HOTEL MANAGEMENT DATABASE SYSTEM
-- Complete Implementation with:
-- - Optimized Schema
-- - Comprehensive Indexing
-- - Triggers
-- - Stored Procedures
-- - Functions
-- - Views
-- - Backup/Recovery System
-- =============================================
here i changed on the remote repository
-- 1. DATABASE SETUP
DROP DATABASE IF EXISTS hotel;
CREATE DATABASE hotel;
USE hotel;

-- 2. CORE TABLES WITH INDEXES


-- Guest information
CREATE TABLE guest (
    guestId INT PRIMARY KEY AUTO_INCREMENT,
    firstName VARCHAR(40) NOT NULL,
    lastName VARCHAR(40) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    email VARCHAR(100),
    registrationDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_guest_name (lastName, firstName),
    INDEX idx_guest_phone (phone),
    INDEX idx_guest_email (email),
    INDEX idx_guest_regdate (registrationDate)
) ;

-- Room inventory
CREATE TABLE rooms (
    roomid INT PRIMARY KEY AUTO_INCREMENT,
    roomNumber VARCHAR(10) NOT NULL UNIQUE,
    capacity TINYINT CHECK (capacity BETWEEN 1 AND 5),
    floorNumber TINYINT NOT NULL,
    roomType ENUM('standard', 'deluxe', 'suite') NOT NULL DEFAULT 'standard',
    availablityStatus ENUM('available', 'occupied', 'maintenance', 'reserved') DEFAULT 'available',
    lastMaintenanceDate DATE,
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),
    INDEX idx_room_number (roomNumber),
    INDEX idx_room_availability (availablityStatus, floorNumber),
    INDEX idx_room_type_price (roomType, price),
    INDEX idx_room_floor (floorNumber)
) ;






-- Reservation system
CREATE TABLE reservation (
    reservationid INT PRIMARY KEY AUTO_INCREMENT,
    guestId INT NOT NULL,
    room_id INT NOT NULL,
    checkInDate DATE NOT NULL,
    checkOutDate DATE NOT NULL,
    adults TINYINT DEFAULT 1,
    children TINYINT DEFAULT 0,
    reservationStatus ENUM('confirmed', 'checked-in', 'checked-out', 'cancelled', 'no-show') DEFAULT 'confirmed',
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (room_id) REFERENCES rooms(roomid) ON UPDATE CASCADE,
    FOREIGN KEY (guestId) REFERENCES guest(guestId) ON DELETE CASCADE,
    CONSTRAINT valid_dates CHECK (checkOutDate > checkInDate),
    INDEX idx_reservation_guest (guestId),
    INDEX idx_reservation_room (room_id),
    INDEX idx_reservation_dates (checkInDate, checkOutDate),
    INDEX idx_reservation_status (reservationStatus),
    INDEX idx_reservation_created (createdAt)
) ;

-- Payment processing




create table payment (
    paymentId int PRIMARY KEY AUTO_INCREMENT,
    reservationsId int NOT NULL,
    paymentDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    paymentMethod ENUM('cash', 'credit card', 'debit card', 'bank transfer', 'online payment') NOT NULL,
    paymentStatus ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    transactionReference VARCHAR(100),
    FOREIGN KEY (reservationsId) REFERENCES reservation(reservationid) ON DELETE CASCADE,
    INDEX idx_payment_reservation (reservationsId),
    INDEX idx_payment_date (paymentDate),
    INDEX idx_payment_status (paymentStatus),
    INDEX idx_payment_method (paymentMethod)
) ;


-- Staff records





create table staff (
    staffId int PRIMARY KEY AUTO_INCREMENT,
    firstName VARCHAR(50) NOT NULL,
    lastName VARCHAR(50) NOT NULL,
    position VARCHAR(50) NOT NULL,
    department ENUM('front desk', 'housekeeping', 'maintenance', 'management', 'food service') NOT NULL,
    phoneNumber VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    hireDate DATE NOT NULL,
    salary DECIMAL(10,2) CHECK (salary > 0),
    status ENUM('active', 'on leave', 'terminated') DEFAULT 'active',
    INDEX idx_staff_name (lastName, firstName),
    INDEX idx_staff_department (department),
    INDEX idx_staff_phone (phoneNumber)
);



-- Inventory management
CREATE TABLE inventory (
    inventoryId INT PRIMARY KEY AUTO_INCREMENT,
    itemName VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    quantityInStock INT NOT NULL DEFAULT 0 CHECK (quantityInStock >= 0),
    unitOfMeasure VARCHAR(10) NOT NULL,
    reorderLevel INT DEFAULT 5,
    supplierInfo TEXT,
    lastRestocked DATE,
    INDEX idx_inventory_name (itemName),
    INDEX idx_inventory_category (category),
    INDEX idx_inventory_stock (quantityInStock)
) ;


-- Hotel services
CREATE TABLE services (
    serviceId INT PRIMARY KEY AUTO_INCREMENT,
    serviceName VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    durationMinutes INT,
    availability ENUM('24/7', 'daytime', 'on-request') NOT NULL,
    requiresInventory BOOLEAN DEFAULT FALSE,
    INDEX idx_service_name (serviceName),
    INDEX idx_service_price (price)
) ;


-- Guest service requests
CREATE TABLE guestServices (
    guestServiceId INT PRIMARY KEY AUTO_INCREMENT,
    reservationId INT NOT NULL,
    serviceId INT NOT NULL,
    requestDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    quantity INT DEFAULT 1 CHECK (quantity > 0),
    scheduledTime DATETIME,
    status ENUM('requested', 'in-progress', 'completed', 'cancelled') DEFAULT 'requested',
    notes TEXT,
    FOREIGN KEY (reservationId) REFERENCES reservation(reservationId) ON DELETE CASCADE,
    FOREIGN KEY (serviceId) REFERENCES services(serviceId) ON UPDATE CASCADE,
    INDEX idx_guestservice_reservation (reservationId),
    INDEX idx_guestservice_service (serviceId),
    INDEX idx_guestservice_status (status)
) ;

-- Maintenance tracking
CREATE TABLE maintenance (
    maintenanceId INT PRIMARY KEY AUTO_INCREMENT,
    room_id INT NOT NULL,
    staffId INT NOT NULL,
    issueType VARCHAR(100) NOT NULL,
    priority ENUM('low', 'medium', 'high', 'emergency') DEFAULT 'medium',
    reportDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    startDate DATETIME,
    completionDate DATETIME,
    status ENUM('reported', 'assigned', 'in-progress', 'completed') DEFAULT 'reported',
    description TEXT,
    cost DECIMAL(10,2) DEFAULT 0,
    FOREIGN KEY (room_id) REFERENCES rooms(roomid) ON UPDATE CASCADE,
    FOREIGN KEY (staffId) REFERENCES staff(staffId) ON UPDATE CASCADE,
    INDEX idx_maintenance_room (room_id),
    INDEX idx_maintenance_staff (staffId),
    INDEX idx_maintenance_status (status)
) ;
-- drop table maintenance;

-- =============================================
-- BACKUP & RECOVERY SYSTEM
-- =============================================

-- Backup log table
CREATE TABLE backup_log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    backup_type ENUM('full', 'incremental', 'transaction') NOT NULL,
    backup_file VARCHAR(255) NOT NULL,
    status ENUM('scheduled', 'in-progress', 'completed', 'failed') NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    file_size_mb DECIMAL(10,2),
    notes TEXT,
    INDEX idx_backup_dates (created_at)
) ENGINE=InnoDB;

-- Recovery log table
CREATE TABLE recovery_log (
    recovery_id INT PRIMARY KEY AUTO_INCREMENT,
    backup_used VARCHAR(255) NOT NULL,
    restore_point DATETIME NOT NULL,
    status ENUM('initiated', 'in-progress', 'completed', 'failed') NOT NULL,
    started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    affected_tables INT,
    recovered_rows INT,
    INDEX idx_recovery_dates (started_at)
) ENGINE=InnoDB;

-- Transaction audit log
CREATE TABLE transaction_log (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    old_values JSON,
    new_values JSON,
    changed_by VARCHAR(50),
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_transaction_table (table_name, record_id),
    INDEX idx_transaction_date (changed_at)
) ENGINE=InnoDB;

-- =============================================
-- TRIGGERS for some response (before after insted)
-- =============================================



DELIMITER //
-- Update room status when reservation is made
CREATE TRIGGER tr_reservation_room_status
AFTER INSERT ON reservation
FOR EACH ROW
BEGIN
    UPDATE rooms 
    SET availablityStatus = 'occupied' 
    WHERE roomid = NEW.room_id;
    
    INSERT INTO transaction_log (table_name, record_id, action_type, new_values, changed_at)
    VALUES ('rooms', NEW.room_id, 'UPDATE', 
            JSON_OBJECT('availablityStatus', 'occupied'), 
            NOW());
END //
DELIMITER ;
-- Update room status when guest checks out
DELIMITER //

CREATE TRIGGER tr_checkout_room_status
AFTER UPDATE ON reservation
FOR EACH ROW
BEGIN
    IF NEW.reservationStatus = 'checked-out' AND OLD.reservationStatus != 'checked-out' THEN
        UPDATE rooms 
        SET availablityStatus = 'available' 
        WHERE roomid = NEW.room_id;
        
        INSERT INTO transaction_log (table_name, record_id, action_type, new_values, changed_at)
        VALUES ('rooms', NEW.room_id, 'UPDATE', 
                JSON_OBJECT('availablityStatus', 'available'), 
                NOW());
    END IF;
END//

DELIMITER ;
-- Log payment transactions



DELIMITER //
CREATE TRIGGER tr_payment_audit
AFTER INSERT ON payment
FOR EACH ROW
BEGIN
    INSERT INTO transaction_log (table_name, record_id, action_type, new_values, changed_at)
    VALUES ('payment', NEW.paymentId, 'INSERT',
            JSON_OBJECT('amount', NEW.amount, 'paymentMethod', NEW.paymentMethod),
            NOW());
END //
DELIMITER ;
-- Calculate service charges automatically
DELIMITER //
CREATE TRIGGER tr_calculate_service_charge
BEFORE INSERT ON guestServices
FOR EACH ROW
BEGIN
    DECLARE service_price DECIMAL(10,2);
    
    SELECT price INTO service_price 
    FROM services 
    WHERE serviceId = NEW.serviceId;
    
    SET @total_charge = service_price * NEW.quantity;
    
    -- Store in notes for demonstration (would normally be a separate column)
    SET NEW.notes = CONCAT(IFNULL(NEW.notes, ''), ' | Calculated charge: $', @total_charge);
END //
DELIMITER ;


-- Staff salary bonus after maintenance completion





DELIMITER //
CREATE TRIGGER tr_maintenance_completion_bonus
AFTER UPDATE ON maintenance
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' AND NEW.cost > 0 THEN
        -- Just update salary without logging
        UPDATE staff 
        SET salary = salary + (NEW.cost * 0.05)
        WHERE staffId = NEW.staffId;
    END IF;
END //
DELIMITER ;






desc  maintenance_bonus_log;



DELIMITER //
CREATE TRIGGER tr_maintenance_completion_room_status
AFTER UPDATE ON maintenance
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        UPDATE rooms 
        SET availablityStatus = 'available',  -- Note the spelling here
            lastMaintenanceDate = CURDATE()
        WHERE roomid = NEW.room_id;
    END IF;
END //
DELIMITER ;





DELIMITER //

CREATE TRIGGER update_room_availability_on_maintenance
AFTER INSERT ON maintenance
FOR EACH ROW
BEGIN
    IF NEW.status IN ('reported', 'assigned', 'in-progress') THEN
        UPDATE rooms 
        SET availablityStatus = 'maintenance'
        WHERE roomid = NEW.room_id;
    END IF;
END//
DELIMITER ;



DELIMITER //
CREATE TRIGGER update_room_availability_on_maintenance_update
AFTER UPDATE ON maintenance
FOR EACH ROW
BEGIN
    -- If status is changing to one of the maintenance states
    IF NEW.status IN ('reported', 'assigned', 'in-progress') AND 
       (OLD.status IS NULL OR OLD.status NOT IN ('reported', 'assigned', 'in-progress')) THEN
        UPDATE rooms 
        SET availablityStatus = 'maintenance'
        WHERE roomid = NEW.room_id;
    
    -- If maintenance is completed and room was in maintenance
    ELSEIF NEW.status = 'completed' AND OLD.status IN ('reported', 'assigned', 'in-progress') THEN
        UPDATE rooms 
        SET availablityStatus = 'available',
            lastMaintenanceDate = CURDATE()
        WHERE roomid = NEW.room_id AND availablityStatus = 'maintenance';
    END IF;
END//

DELIMITER ;



-- =============================================
-- STORED PROCEDURES
-- =============================================

DELIMITER //

CREATE PROCEDURE sp_add_guest(
    IN p_firstName VARCHAR(40),
    IN p_lastName VARCHAR(40),
    IN p_phone VARCHAR(30),
    IN p_email VARCHAR(100),
    IN p_registerDate VARCHAR(200)
)
BEGIN
    DECLARE phone_exists INT;
    
    -- Check if phone already exists
    SELECT COUNT(*) INTO phone_exists FROM guest WHERE phone = p_phone;
    
    IF phone_exists > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Phone number already exists in system';
    ELSE
        INSERT INTO guest (firstName, lastName, phone, email, registrationDate)
        VALUES (p_firstName, p_lastName, p_phone, p_email, p_registerDate);
        
        SELECT LAST_INSERT_ID() AS guestId;
    END IF;
END //

DELIMITER ;
-- Make reservation with availability check



DELIMITER //

CREATE PROCEDURE sp_make_reservation(
    IN p_guestId INT,
    IN p_roomId INT,
    IN p_checkIn DATE,
    IN p_checkOut DATE,
    IN p_adults TINYINT,
    IN p_children TINYINT
)
BEGIN
    DECLARE room_available INT;
    DECLARE room_status VARCHAR(20);
    
    -- First check the room's current availability status
    SELECT availablityStatus INTO room_status  -- Corrected column name
    FROM rooms 
    WHERE roomid = p_roomId;
    
    -- If room is not available, return error immediately
    IF room_status != 'available' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Room is not currently available for reservation';
    ELSE
        -- Check date availability conflicts
        SELECT COUNT(*) INTO room_available
        FROM reservation
        WHERE room_id = p_roomId
        AND reservationStatus IN ('confirmed', 'checked-in')
        AND (
            (p_checkIn BETWEEN checkInDate AND checkOutDate) OR
            (p_checkOut BETWEEN checkInDate AND checkOutDate) OR
            (checkInDate BETWEEN p_checkIn AND p_checkOut)
        );
        
        IF room_available > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Room is not available for the selected dates';
        ELSE
            -- Make the reservation
            INSERT INTO reservation (guestId, room_id, checkInDate, checkOutDate, adults, children)
            VALUES (p_guestId, p_roomId, p_checkIn, p_checkOut, p_adults, p_children);
            
            -- Update room status to 'reserved' (using correct column name)
            UPDATE rooms SET availablityStatus = 'reserved' WHERE roomid = p_roomId;
            
            SELECT LAST_INSERT_ID() AS reservationId;
        END IF;
    END IF;
END //

DELIMITER ;


-- Check-in guest procedure
DELIMITER //
CREATE PROCEDURE sp_check_in(IN p_reservationId INT)
BEGIN
    DECLARE v_roomId INT;
    DECLARE v_status VARCHAR(20);
    
    -- Get current status
    SELECT reservationStatus, room_id INTO v_status, v_roomId
    FROM reservation
    WHERE reservationId = p_reservationId;
    
    IF v_status = 'confirmed' THEN
        UPDATE reservation
        SET reservationStatus = 'checked-in'
        WHERE reservationId = p_reservationId;
        
        SELECT CONCAT('Guest checked in successfully. Room: ', v_roomId) AS message;
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot check in - reservation is not in confirmed status';
    END IF;
END //
DELIMITER ;


-- Check-out guest procedure
DELIMITER //
CREATE PROCEDURE sp_check_out(IN p_reservationId INT)
BEGIN
    DECLARE v_roomId INT;
    DECLARE v_status VARCHAR(20);
    
    -- Get current status
    SELECT reservationStatus, room_id INTO v_status, v_roomId
    FROM reservation
    WHERE reservationId = p_reservationId;
    
    IF v_status = 'checked-in' THEN
        -- Update reservation status
        UPDATE reservation
        SET reservationStatus = 'checked-out'
        WHERE reservationId = p_reservationId;
        
        -- Room status updated automatically by trigger
        
        SELECT CONCAT('Guest checked out successfully. Room: ', v_roomId, ' now available') AS message;
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot check out - guest is not checked in';
    END IF;
END //
DELIMITER ;

-- Database backup procedure
DELIMITER //
CREATE PROCEDURE sp_backup_database(IN p_backup_type VARCHAR(20))
BEGIN
    DECLARE v_backup_file VARCHAR(255);
    DECLARE v_log_id INT;
    
    -- Set backup filename
    SET v_backup_file = CONCAT('/backups/hotel_', p_backup_type, '_', DATE_FORMAT(NOW(), '%Y%m%d_%H%i%s'), '.sql');
    
    -- Log backup start
    INSERT INTO backup_log (backup_type, backup_file, status, notes)
    VALUES (p_backup_type, v_backup_file, 'in-progress', 'Backup initiated');
    
    SET v_log_id = LAST_INSERT_ID();
    
    -- In production, this would execute mysqldump command via system call
    -- SET @cmd = CONCAT('mysqldump -u backup_user -p[password] hotel > ', v_backup_file);
    -- SYSTEM @cmd;
    
    -- Simulate backup completion
    UPDATE backup_log 
    SET status = 'completed', 
        completed_at = NOW(),
        file_size_mb = ROUND(RAND() * 100, 2),
        notes = 'Backup completed successfully'
    WHERE log_id = v_log_id;
    
    SELECT CONCAT('Backup created: ', v_backup_file) AS result;
END //
DELIMITER ;


-- Database restore procedure
DELIMITER //
CREATE PROCEDURE sp_restore_database(IN p_backup_file VARCHAR(255))
BEGIN
    -- Log restore start
    INSERT INTO recovery_log (backup_used, restore_point, status)
    VALUES (p_backup_file, NOW(), 'in-progress');
    
    SET @log_id = LAST_INSERT_ID();
    
    -- In production, this would execute mysql command via system call
    -- SET @cmd = CONCAT('mysql -u restore_user -p[password] hotel < ', p_backup_file);
    -- SYSTEM @cmd;
    
    -- Simulate restore completion
    UPDATE recovery_log 
    SET status = 'completed',
        completed_at = NOW(),
        affected_tables = (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'hotel'),
        recovered_rows = FLOOR(RAND() * 10000)
    WHERE recovery_id = @log_id;
    
    SELECT CONCAT('Database restored from: ', p_backup_file) AS result;
END //

DELIMITER ;

-- =============================================
-- FUNCTIONS
-- =============================================

DELIMITER //

-- Calculate total revenue between dates
CREATE FUNCTION fn_calculate_revenue(p_start_date DATE, p_end_date DATE) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(10,2);
    
    SELECT COALESCE(SUM(amount), 0) INTO v_total
    FROM payment
    WHERE paymentDate BETWEEN p_start_date AND p_end_date
    AND paymentStatus = 'completed';
    
    RETURN v_total;
END //
DELIMITER ;

-- Check room availability
DELIMITER //
CREATE FUNCTION fn_is_room_available(
    p_room_id INT, 
    p_check_in DATE, 
    p_check_out DATE
) RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE v_conflict_count INT;
    
    SELECT COUNT(*) INTO v_conflict_count
    FROM reservation
    WHERE room_id = p_room_id
    AND reservationStatus IN ('confirmed', 'checked-in')
    AND (
        (p_check_in BETWEEN checkInDate AND checkOutDate) OR
        (p_check_out BETWEEN checkInDate AND checkOutDate) OR
        (checkInDate BETWEEN p_check_in AND p_check_out)
    );
    
    RETURN v_conflict_count = 0;
END //
DELIMITER ;





-- =============================================
-- VIEWS
-- =============================================



CREATE VIEW staff_bonus_view AS
SELECT 
    s.staffId AS id,
    CONCAT(s.firstName, ' ', s.lastName) AS full_name,
    s.salary AS base_salary,
    COALESCE(SUM(m.cost * 0.05), 0) AS bonus,
    s.salary + COALESCE(SUM(m.cost * 0.05), 0) AS total_salary,
    s.department,
    s.position
FROM 
    staff s
LEFT JOIN 
    maintenance m ON s.staffId = m.staffId AND m.status = 'completed'
GROUP BY 
    s.staffId, s.firstName, s.lastName, s.salary, s.department, s.position;




-- Current guests view
CREATE VIEW vw_current_guests AS
SELECT 
    g.guestId,
    CONCAT(g.firstName, ' ', g.lastName) AS guestName,
    r.roomNumber,
    r.roomType,
    res.checkInDate,
    res.checkOutDate,
    DATEDIFF(res.checkOutDate, res.checkInDate) AS nights,
    res.reservationStatus
FROM guest g
JOIN reservation res ON g.guestId = res.guestId
JOIN rooms r ON res.room_id = r.roomid
WHERE res.reservationStatus IN ('confirmed', 'checked-in');

-- Available rooms view
CREATE VIEW vw_available_rooms AS
SELECT 
    r.roomid,
    r.roomNumber,
    r.floorNumber,
    r.roomType,
    r.capacity,
    r.price
FROM rooms r
WHERE r.availablityStatus = 'available'
AND NOT EXISTS (
    SELECT 1 FROM reservation res
    WHERE res.room_id = r.roomid
    AND res.reservationStatus IN ('confirmed', 'checked-in')
);

-- Revenue summary view
CREATE VIEW vw_revenue_summary AS
SELECT 
    DATE(paymentDate) AS paymentDay,
    paymentMethod,
    COUNT(*) AS transactionCount,
    SUM(amount) AS totalAmount
FROM payment
WHERE paymentStatus = 'completed'
GROUP BY DATE(paymentDate), paymentMethod;



-- Maintenance requests view
CREATE VIEW vw_maintenance_requests AS
SELECT 
    m.maintenanceId,
    r.roomNumber,
    CONCAT(s.firstName, ' ', s.lastName) AS assignedStaff,
    m.issueType,
    m.priority,
    m.reportDate,
    m.status,
    DATEDIFF(NOW(), m.reportDate) AS daysOpen
FROM maintenance m
JOIN rooms r ON m.room_id = r.roomid
JOIN staff s ON m.staffId = s.staffId
WHERE m.status != 'completed';

-- Guest service requests view
CREATE VIEW vw_guest_service_requests AS
SELECT 
    gs.guestServiceId,
    CONCAT(g.firstName, ' ', g.lastName) AS guestName,
    r.roomNumber,
    s.serviceName,
    gs.requestDate,
    gs.status,
    gs.notes
FROM guestServices gs
JOIN reservation res ON gs.reservationId = res.reservationId
JOIN guest g ON res.guestId = g.guestId
JOIN rooms r ON res.room_id = r.roomid
JOIN services s ON gs.serviceId = s.serviceId;

-- =============================================
-- SCHEDULED EVENTS
-- =============================================

DELIMITER //

-- Daily room status check
CREATE EVENT ev_daily_room_check
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
DO
BEGIN
    -- Mark no-show reservations
    UPDATE reservation
    SET reservationStatus = 'no-show'
    WHERE reservationStatus = 'confirmed'
    AND checkInDate < CURDATE();
    
    -- Update rooms for checked-out guests
    UPDATE rooms r
    JOIN reservation res ON r.roomid = res.room_id
    SET r.availablityStatus = 'available'
    WHERE res.reservationStatus = 'checked-out'
    AND r.availablityStatus = 'occupied';
END //
DELIMITER ;

-- Weekly backup
DELIMITER //
CREATE EVENT ev_weekly_backup
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
DO
BEGIN
    CALL sp_backup_database('weekly');
END //
DELIMITER ;
-- Monthly index maintenance
DELIMITER //
CREATE EVENT ev_monthly_index_maintenance
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP + INTERVAL 1 WEEK
DO
BEGIN
    ANALYZE TABLE guest, rooms, reservation, payment, staff, services, guestServices, maintenance;
    OPTIMIZE TABLE guest, rooms, reservation;
END //

DELIMITER ;



-- =============================================
-- SAMPLE DATA INSERTION (FOR TESTING)
-- =============================================

-- Insert sample rooms
INSERT INTO rooms (roomNumber, capacity, floorNumber, roomType, price) VALUES
-- Floor 1 (Standard Rooms)
('101', 2, 1, 'standard', 120.00),
('102', 2, 1, 'standard', 120.00),
('103', 2, 1, 'standard', 120.00),
('104', 2, 1, 'standard', 120.00),
('105', 3, 1, 'standard', 140.00),
('106', 3, 1, 'standard', 140.00),
('107', 1, 1, 'standard', 100.00),  -- Single room
('108', 1, 1, 'standard', 100.00),  -- Single room
('109', 2, 1, 'standard', 120.00),
('110', 2, 1, 'standard', 120.00),

-- Floor 2 (Deluxe Rooms)
('201', 2, 2, 'deluxe', 180.00),
('202', 2, 2, 'deluxe', 180.00),
('203', 2, 2, 'deluxe', 180.00),
('204', 2, 2, 'deluxe', 180.00),
('205', 3, 2, 'deluxe', 220.00),
('206', 3, 2, 'deluxe', 220.00),
('207', 2, 2, 'deluxe', 180.00),
('208', 2, 2, 'deluxe', 180.00),
('209', 2, 2, 'deluxe', 180.00),
('210', 2, 2, 'deluxe', 180.00),

-- Floor 3 (Suites)
('301', 4, 3, 'suite', 300.00),
('302', 4, 3, 'suite', 300.00),
('303', 4, 3, 'suite', 300.00),
('304', 2, 3, 'suite', 280.00),  -- Junior suite
('305', 2, 3, 'suite', 280.00),  -- Junior suite
('306', 5, 3, 'suite', 350.00),  -- Family suite
('307', 5, 3, 'suite', 350.00),  -- Family suite
('308', 4, 3, 'suite', 300.00),
('309', 4, 3, 'suite', 300.00),
('310', 4, 3, 'suite', 300.00);
select * from rooms;
-- Floor 4 (Penthouse - if you want to extend further)
-- ('401', 2, 4, 'suite', 500.00),
-- ('402', 2, 4, 'suite', 500.00);
-- Insert sample staff



-- Ethiopian Guests (10)
CALL sp_add_guest('Abebe', 'Kebede', '+251911112233', 'abebe.k@example.com', '2025-03-01 09:15:00');
CALL sp_add_guest('Selam', 'Tesfaye', '+251922334455', 'selam.t@example.com', '2025-03-03 10:30:00');
CALL sp_add_guest('Dawit', 'Mekonnen', '+251933445566', 'dawit.m@example.com', '2025-03-05 11:45:00');
CALL sp_add_guest('Eyerusalem', 'Assefa', '+251944556677', 'eyerusalem.a@example.com', '2025-03-07 14:20:00');
CALL sp_add_guest('Tewodros', 'Girma', '+251955667788', 'tewodros.g@example.com', '2025-03-09 16:10:00');
CALL sp_add_guest('Mekdes', 'Yohannes', '+251966778899', 'mekdes.y@example.com', '2025-03-12 08:45:00');
CALL sp_add_guest('Yonas', 'Berhane', '+251977889900', 'yonas.b@example.com', '2025-03-15 13:30:00');
CALL sp_add_guest('Alem', 'Hailu', '+251988990011', 'alem.h@example.com', '2025-03-20 15:20:00');
CALL sp_add_guest('Kaleb', 'Demissie', '+251900112233', 'kaleb.d@example.com', '2025-03-25 10:10:00');
CALL sp_add_guest('Zewditu', 'Getachew', '+251911223344', 'zewditu.g@example.com', '2025-04-01 12:00:00');

-- International Guests (20)
-- European
CALL sp_add_guest('John', 'Smith', '+441234567890', 'john.smith@example.com', '2025-03-02 08:30:00');
CALL sp_add_guest('Maria', 'Garcia', '+349876543210', 'maria.g@example.com', '2025-03-04 14:15:00');
CALL sp_add_guest('Hans', 'Müller', '+491723456789', 'hans.m@example.com', '2025-03-06 16:45:00');
CALL sp_add_guest('Sophie', 'Dubois', '+33123456789', 'sophie.d@example.com', '2025-03-08 09:20:00');

-- Asian
CALL sp_add_guest('Wei', 'Chen', '+8613812345678', 'wei.chen@example.com', '2025-03-10 11:10:00');
CALL sp_add_guest('Yuki', 'Tanaka', '+81345678901', 'yuki.t@example.com', '2025-03-11 13:40:00');
CALL sp_add_guest('Raj', 'Patel', '+919876543210', 'raj.p@example.com', '2025-03-13 17:30:00');
CALL sp_add_guest('Min', 'Park', '+82212345678', 'min.p@example.com', '2025-03-14 10:50:00');

-- American
CALL sp_add_guest('Michael', 'Johnson', '+12025551234', 'michael.j@example.com', '2025-03-16 08:15:00');
CALL sp_add_guest('Jessica', 'Williams', '+12125556789', 'jessica.w@example.com', '2025-03-17 14:25:00');
CALL sp_add_guest('Carlos', 'Rodriguez', '+525512345678', 'carlos.r@example.com', '2025-03-18 16:35:00');
CALL sp_add_guest('Emily', 'Brown', '+16135551234', 'emily.b@example.com', '2025-03-19 09:45:00');

-- African (non-Ethiopian)
CALL sp_add_guest('Mohamed', 'Ahmed', '+201012345678', 'mohamed.a@example.com', '2025-03-21 11:55:00');
CALL sp_add_guest('Amina', 'Diallo', '+221781234567', 'amina.d@example.com', '2025-03-22 13:05:00');
CALL sp_add_guest('Kwame', 'Osei', '+233241234567', 'kwame.o@example.com', '2025-03-23 15:15:00');

-- Oceanian
CALL sp_add_guest('James', 'Wilson', '+61212345678', 'james.w@example.com', '2025-03-24 10:25:00');
CALL sp_add_guest('Olivia', 'Taylor', '+64211234567', 'olivia.t@example.com', '2025-03-26 12:35:00');

-- Additional International
CALL sp_add_guest('Luca', 'Rossi', '+393331234567', 'luca.r@example.com', '2025-03-27 14:45:00');
CALL sp_add_guest('Elena', 'Popa', '+40723123456', 'elena.p@example.com', '2025-03-28 16:55:00');
CALL sp_add_guest('Ivan', 'Petrov', '+79161234567', 'ivan.p@example.com', '2025-04-05 09:05:00');
CALL sp_add_guest('Fatima', 'Al-Mansoor', '+971501234567', 'fatima.a@example.com', '2025-04-12 11:15:00');

select * from guest;
select *from vw_current_guests;



INSERT INTO staff (firstName, lastName, position, department, phoneNumber, hireDate, salary) VALUES
-- Management (3)
('Dawit', 'Tesfaye', 'General Manager', 'management', '+251911112233', '2019-05-12', 5500.00),
('Selam', 'Gebre', 'Assistant Manager', 'management', '+251922223344', '2020-08-20', 4500.00),
('Tewodros', 'Assefa', 'Operations Manager', 'management', '+251933334455', '2021-02-15', 4800.00),

-- Front Desk (4)
('Mekdes', 'Kebede', 'Front Desk Supervisor', 'front desk', '+251944445566', '2020-06-18', 3500.00),
('Yonas', 'Hailu', 'Front Desk Agent', 'front desk', '+251955556677', '2021-04-05', 3200.00),
('Alem', 'Demissie', 'Night Auditor', 'front desk', '+251966667788', '2021-07-22', 3400.00),
('Eyerusalem', 'Getachew', 'Guest Service Agent', 'front desk', '+251977778899', '2022-03-14', 3100.00),

-- Housekeeping (5)
('Kaleb', 'Mekonnen', 'Head Housekeeper', 'housekeeping', '+251988889900', '2020-09-10', 3000.00),
('Zewditu', 'Berhane', 'Housekeeping Supervisor', 'housekeeping', '+251900001111', '2021-01-25', 2900.00),
('Abebe', 'Yohannes', 'Room Attendant', 'housekeeping', '+251911122233', '2021-05-12', 2800.00),
('Birtukan', 'Girma', 'Laundry Attendant', 'housekeeping', '+251922233344', '2022-02-18', 2700.00),
('Samuel', 'Tadesse', 'Public Area Cleaner', 'housekeeping', '+251933344455', '2022-09-05', 2700.00),

-- Maintenance (5)
('Daniel', 'Worku', 'Chief Engineer', 'maintenance', '+251944455566', '2018-11-15', 3800.00),
('Ruth', 'Gebru', 'HVAC Technician', 'maintenance', '+251955566677', '2020-07-12', 3400.00),
('Joseph', 'Alemayehu', 'Plumber', 'maintenance', '+251966677788', '2021-01-30', 3300.00),
('Hanna', 'Teshome', 'Electrician', 'maintenance', '+251977788899', '2021-06-18', 3500.00),
('Nathan', 'Solomon', 'Maintenance Technician', 'maintenance', '+251988899900', '2022-03-05', 3100.00),

-- Food Service (3)
('Martha', 'Daniel', 'Restaurant Manager', 'food service', '+251900011122', '2020-04-15', 4000.00),
('Simon', 'Michael', 'Head Chef', 'food service', '+251911122233', '2020-10-22', 3800.00),
('Rachel', 'Paul', 'Server', 'food service', '+251922233344', '2022-01-18', 2800.00);



select*from staff;


-- Insert sample services




INSERT INTO services (serviceName, description, price, durationMinutes, availability, requiresInventory) VALUES
-- Food & Beverage Services
('Breakfast Buffet', 'Full breakfast buffet with hot and cold options', 25.00, 120, 'daytime', TRUE),
('Room Service', '24-hour in-room dining service', 10.00, 45, '24/7', TRUE),
('Minibar Restock', 'Daily restocking of minibar items', 0.00, 15, '24/7', TRUE),
('Afternoon Tea', 'Traditional afternoon tea service', 18.00, 90, 'daytime', TRUE),
('Dinner Package', 'Three-course dinner in hotel restaurant', 45.00, 180, 'daytime', TRUE),

-- Transportation Services
('Airport Shuttle', 'Scheduled airport transfers', 30.00, 60, '24/7', FALSE),
('Private Car Service', 'Chauffeured private vehicle', 75.00, NULL, '24/7', FALSE),
('City Tour', 'Guided city tour with driver', 120.00, 240, 'daytime', FALSE),
('Car Rental', 'Daily car rental arrangement', 65.00, 15, 'daytime', FALSE),

-- Room & Housekeeping Services
('Late Checkout', 'Extended checkout until 2PM', 35.00, NULL, 'daytime', FALSE),
('Early Checkin', 'Guaranteed room availability from 9AM', 35.00, NULL, 'daytime', FALSE),
('Express Laundry', '2-hour laundry service', 40.00, 120, '24/7', TRUE),
('Dry Cleaning', 'Next-day dry cleaning service', 15.00, NULL, 'daytime', TRUE),
('Pressing Service', 'Immediate clothes pressing', 12.00, 60, '24/7', FALSE),

-- Business Services
('Meeting Room', 'Per hour conference room rental', 50.00, 60, 'daytime', FALSE),
('Business Center', 'Computer and printing access', 10.00, NULL, 'daytime', FALSE),
('Secretarial Services', 'Typing/administrative support', 25.00, 60, 'daytime', FALSE),
('Video Conferencing', 'AV-equipped meeting space', 75.00, 60, 'daytime', TRUE),

-- Wellness Services
('Spa Treatment', '60-minute massage or facial', 85.00, 60, 'daytime', TRUE),
('Gym Access', 'Daily fitness center pass', 15.00, 1440, '24/7', FALSE),
('Pool Access', 'Day pass to pool area', 20.00, 1440, 'daytime', FALSE),
('Yoga Class', 'Morning yoga session', 20.00, 60, 'daytime', FALSE),

-- Special Services
('Romantic Package', 'Champagne, flowers, and chocolates', 95.00, NULL, '24/7', TRUE),
('Babysitting', 'Childcare services', 30.00, 240, '24/7', FALSE),
('Pet Care', 'Pet sitting and walking', 25.00, NULL, '24/7', FALSE),
('Flower Arrangement', 'Custom floral arrangements', 45.00, NULL, 'daytime', TRUE),
('Gift Basket', 'Custom welcome gift basket', 55.00, NULL, '24/7', TRUE),

-- Technical Services
('Mobile Charger', 'Loaner phone charger', 5.00, NULL, '24/7', TRUE),
('SIM Card', 'Local SIM card with data', 15.00, 15, 'daytime', TRUE),
('Device Repair', 'Basic electronics troubleshooting', 20.00, 30, 'daytime', FALSE);
select *from services;



select*from rooms;


INSERT INTO maintenance (room_id, staffId, issueType, priority, reportDate, startDate, completionDate, status, description, cost) VALUES
-- Reported (2 records)
(1, 14, 'AC not cooling', 'high', '2025-03-03 09:15:00', NULL, NULL, 'reported', 'Guest reports AC not cooling room sufficiently', 330.00),
(6, 14, 'Stuck window', 'low', '2025-03-05 10:00:00', '2025-03-05 14:00:00', '2025-03-05 15:30:00', 'completed', 'Window track cleaned and lubricated', 150.00),
(3, 16, 'Leaky faucet', 'medium', '2025-03-10 14:30:00', NULL, NULL, 'reported', 'Bathroom faucet dripping constantly', 440.00);



-- Completed (3 records)

(3, 16, 'Toilet clog', 'high', '2025-03-12 08:30:00', '2025-03-12 09:15:00', '2025-03-12 10:45:00', 'completed', 'Severe clog cleared with professional equipment', 75.00),
(23, 13, 'Minibar not cooling', 'medium', '2025-03-25 13:00:00', '2025-03-25 14:30:00', '2025-03-25 16:00:00', 'completed', 'Replaced thermostat and sealed cooling unit', 95.00);

select *from maintenance;
delete from maintenance;
select *from vw_maintenance_requests;
select*from staff_bonus_view ;


select*from maintenance;
INSERT INTO maintenance (room_id, staffId, issueType, priority, reportDate, startDate, completionDate, status, description, cost) VALUES
(1, 14, 'Minibar not cooling', 'medium', '2025-03-25 13:00:00', '2025-03-25 14:30:00', '2025-03-25 16:00:00', 'completed', 'Replaced thermostat and sealed cooling unit', 95.00),
(3, 13, 'TV not working', 'medium', '2025-03-15 11:20:00', '2025-03-16 08:00:00', NULL, 'assigned', 'No power to television, needs diagnostics', 0.00);




UPDATE maintenance 
SET status = 'completed', 
    completionDate = CURRENT_TIMESTAMP 
WHERE maintenanceId = 6;
--

select*from maintenance;

select *from rooms;
select *from vw_available_rooms;

select *from reservation;
CALL sp_make_reservation(23, 1, '2023-12-01', '2023-12-05', 2, 0);  -- John Doe, Room 101 (Standard)
CALL sp_make_reservation(2, 3, '2023-12-10', '2023-12-15', 2, 2);  -- Jane Smith, Room 301 (Suite)
CALL sp_make_reservation(3, 2, '2023-12-05', '2023-12-08', 1, 0);  -- Robert Johnson, Room 201 (Deluxe)
CALL sp_make_reservation(4, 4, '2023-12-15', '2023-12-17', 2, 1);  -- Emily Williams, Room 102 (Standard)
CALL sp_make_reservation(5, 8, '2023-12-20', '2024-01-05', 2, 0);  -- Michael Brown, Room 202 (Deluxe)

UPDATE reservation 
SET reservationStatus = 'checked-out' 
WHERE reservationid = 1;


-- =============================================
-- SYSTEM READY MESSAGE
-- =============================================






