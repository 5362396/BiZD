CREATE OR REPLACE TRIGGER archive_before_delete
BEFORE DELETE
ON houses
FOR EACH ROW
BEGIN
    INSERT INTO houses_archive(id, sale_date, price, bedrooms, bathrooms, sqft_living, sqft_lot,
                               floors, waterfront, house_view, house_condition, grade, sqft_above,
                               sqft_basement, yr_built, yr_renovated, zipcode, latitude, longitude,
                               sqft_living15, sqft_lot15, deleted_by, deleted_at)
    VALUES (:OLD.id, :OLD.sale_date, :OLD.price, :OLD.bedrooms, :OLD.bathrooms, :OLD.sqft_living,
            :OLD.sqft_lot, :OLD.floors, :OLD.waterfront, :OLD.house_view, :OLD.house_condition, :OLD.grade, :OLD.sqft_above,
            :OLD.sqft_basement, :OLD.yr_built, :OLD.yr_renovated, :OLD.zipcode, :OLD.latitude, :OLD.longitude,
            :OLD.sqft_living15, :OLD.sqft_lot15, USER, SYSTIMESTAMP);
END;

CREATE OR REPLACE TRIGGER log_house_operations
AFTER INSERT OR UPDATE OR DELETE
ON houses
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO houses_log (operation_type, record_id, user_name, old_values, new_values)
        VALUES ('INSERT', :NEW.id, USER, NULL,
                'Sale Date: ' || :NEW.sale_date ||
                ', Price: ' || :NEW.price ||
                ', Bedrooms: ' || :NEW.bedrooms ||
                ', Bathrooms: ' || :NEW.bathrooms ||
                ', Sqft Living: ' || :NEW.sqft_living ||
                ', Sqft Lot: ' || :NEW.sqft_lot ||
                ', Floors: ' || :NEW.floors ||
                ', Waterfront: ' || :NEW.waterfront ||
                ', House View: ' || :NEW.house_view ||
                ', House Condition: ' || :NEW.house_condition ||
                ', Grade: ' || :NEW.grade ||
                ', Sqft Above: ' || :NEW.sqft_above ||
                ', Sqft Basement: ' || :NEW.sqft_basement ||
                ', Year Built: ' || :NEW.yr_built ||
                ', Year Renovated: ' || :NEW.yr_renovated ||
                ', Zipcode: ' || :NEW.zipcode ||
                ', Latitude: ' || :NEW.latitude ||
                ', Longitude: ' || :NEW.longitude ||
                ', Sqft Living 15: ' || :NEW.sqft_living15 ||
                ', Sqft Lot 15: ' || :NEW.sqft_lot15);
    END IF;

    IF UPDATING THEN
        INSERT INTO houses_log (operation_type, record_id, user_name, old_values, new_values)
        VALUES ('UPDATE', :NEW.id, USER,
                'Sale Date: ' || :OLD.sale_date ||
                ', Price: ' || :OLD.price ||
                ', Bedrooms: ' || :OLD.bedrooms ||
                ', Bathrooms: ' || :OLD.bathrooms ||
                ', Sqft Living: ' || :OLD.sqft_living ||
                ', Sqft Lot: ' || :OLD.sqft_lot ||
                ', Floors: ' || :OLD.floors ||
                ', Waterfront: ' || :OLD.waterfront ||
                ', House View: ' || :OLD.house_view ||
                ', House Condition: ' || :OLD.house_condition ||
                ', Grade: ' || :OLD.grade ||
                ', Sqft Above: ' || :OLD.sqft_above ||
                ', Sqft Basement: ' || :OLD.sqft_basement ||
                ', Year Built: ' || :OLD.yr_built ||
                ', Year Renovated: ' || :OLD.yr_renovated ||
                ', Zipcode: ' || :OLD.zipcode ||
                ', Latitude: ' || :OLD.latitude ||
                ', Longitude: ' || :OLD.longitude ||
                ', Sqft Living 15: ' || :OLD.sqft_living15 ||
                ', Sqft Lot 15: ' || :OLD.sqft_lot15,
                'Sale Date: ' || :NEW.sale_date ||
                ', Price: ' || :NEW.price ||
                ', Bedrooms: ' || :NEW.bedrooms ||
                ', Bathrooms: ' || :NEW.bathrooms ||
                ', Sqft Living: ' || :NEW.sqft_living ||
                ', Sqft Lot: ' || :NEW.sqft_lot ||
                ', Floors: ' || :NEW.floors ||
                ', Waterfront: ' || :NEW.waterfront ||
                ', House View: ' || :NEW.house_view ||
                ', House Condition: ' || :NEW.house_condition ||
                ', Grade: ' || :NEW.grade ||
                ', Sqft Above: ' || :NEW.sqft_above ||
                ', Sqft Basement: ' || :NEW.sqft_basement ||
                ', Year Built: ' || :NEW.yr_built ||
                ', Year Renovated: ' || :NEW.yr_renovated ||
                ', Zipcode: ' || :NEW.zipcode ||
                ', Latitude: ' || :NEW.latitude ||
                ', Longitude: ' || :NEW.longitude ||
                ', Sqft Living 15: ' || :NEW.sqft_living15 ||
                ', Sqft Lot 15: ' || :NEW.sqft_lot15);
    END IF;

    IF DELETING THEN
        INSERT INTO houses_log (operation_type, record_id, user_name, old_values, new_values)
        VALUES ('DELETE', :OLD.id, USER,
                'Sale Date: ' || :OLD.sale_date ||
                ', Price: ' || :OLD.price ||
                ', Bedrooms: ' || :OLD.bedrooms ||
                ', Bathrooms: ' || :OLD.bathrooms ||
                ', Sqft Living: ' || :OLD.sqft_living ||
                ', Sqft Lot: ' || :OLD.sqft_lot ||
                ', Floors: ' || :OLD.floors ||
                ', Waterfront: ' || :OLD.waterfront ||
                ', House View: ' || :OLD.house_view ||
                ', House Condition: ' || :OLD.house_condition ||
                ', Grade: ' || :OLD.grade ||
                ', Sqft Above: ' || :OLD.sqft_above ||
                ', Sqft Basement: ' || :OLD.sqft_basement ||
                ', Year Built: ' || :OLD.yr_built ||
                ', Year Renovated: ' || :OLD.yr_renovated ||
                ', Zipcode: ' || :OLD.zipcode ||
                ', Latitude: ' || :OLD.latitude ||
                ', Longitude: ' || :OLD.longitude ||
                ', Sqft Living 15: ' || :OLD.sqft_living15 ||
                ', Sqft Lot 15: ' || :OLD.sqft_lot15, NULL);
    END IF;
END;

CREATE OR REPLACE TRIGGER validate_price
BEFORE INSERT OR UPDATE ON houses
FOR EACH ROW
DECLARE
    price_error EXCEPTION;
BEGIN
    IF (INSERTING AND :NEW.price <= 0) OR (UPDATING AND :NEW.price <= 0 AND :NEW.price IS NOT NULL) THEN
        RAISE price_error;
    END IF;
EXCEPTION
    WHEN price_error THEN
        RAISE_APPLICATION_ERROR(-20001, 'Cena musi być wartością dodatnią. Operacja została anulowana.');
	WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Wystąpił błąd: ' || SQLERRM);
END;
