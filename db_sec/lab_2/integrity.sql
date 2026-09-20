CREATE OR REPLACE FUNCTION check_is_used_transition()
RETURNS TRIGGER LANGUAGE plpgsql AS
$$
BEGIN
    IF OLD.is_used = true AND NEW.is_used = false THEN
        RAISE EXCEPTION 'Признак использования нельзя изменить обратно';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS check_is_used_transition ON prescription;
CREATE TRIGGER check_is_used_transition
BEFORE UPDATE OF is_used ON prescription
FOR EACH ROW EXECUTE FUNCTION check_is_used_transition();
