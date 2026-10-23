-- Up Migration: Add Audit Logs Table, Function, and Trigger

-- 1. Create the audit logs table
CREATE TABLE audit_logs (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    action_type VARCHAR(10) NOT NULL,
    record_id INT NOT NULL,
    performed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Create the stored function that handles logging
CREATE OR REPLACE FUNCTION log_user_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_logs (table_name, action_type, record_id)
        VALUES (TG_TABLE_NAME, 'INSERT', NEW.user_id);
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_logs (table_name, action_type, record_id)
        VALUES (TG_TABLE_NAME, 'DELETE', OLD.user_id);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 3. Attach the trigger to the users table
CREATE TRIGGER user_audit_trigger
AFTER INSERT OR DELETE ON users
FOR EACH ROW 
EXECUTE FUNCTION log_user_changes();