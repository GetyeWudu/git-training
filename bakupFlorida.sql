
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
