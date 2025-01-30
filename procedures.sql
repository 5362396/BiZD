-- Procedura dodawania rekordu z obsługą błędów
create or replace PROCEDURE add_house (
    p_id NUMBER,
    p_sale_date DATE,
    p_price NUMBER,
    p_bedrooms NUMBER,
    p_bathrooms NUMBER,
    p_sqft_living NUMBER,
    p_sqft_lot NUMBER,
    p_floors NUMBER,
    p_waterfront NUMBER,
    p_house_view NUMBER,
    p_house_condition NUMBER,
    p_grade NUMBER,
    p_sqft_above NUMBER,
    p_sqft_basement NUMBER,
    p_yr_built NUMBER,
    p_yr_renovated NUMBER,
    p_zipcode VARCHAR2,
    p_latitude NUMBER,
    p_longitude NUMBER,
    p_sqft_living15 NUMBER,
    p_sqft_lot15 NUMBER
)
IS
    -- Własny wyjątek, jeśli rekord o danym ID już istnieje
    record_exist EXCEPTION;
BEGIN
    -- Sprawdzenie, czy rekord o podanym ID już istnieje
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM stramkoa.houses
        WHERE id = p_id;

        IF v_count > 0 THEN
            RAISE record_exist; -- Rzucenie wyjątku, jeśli rekord istnieje
        END IF;
    END;

    -- Wstawienie nowego rekordu jeśli nie istnieje
    INSERT INTO stramkoa.houses (
        id, sale_date, price, bedrooms, bathrooms, sqft_living, sqft_lot, floors,
        waterfront, house_view, house_condition, grade, sqft_above, sqft_basement,
        yr_built, yr_renovated, zipcode, latitude, longitude, sqft_living15, sqft_lot15
    ) VALUES (
        p_id, p_sale_date, p_price, p_bedrooms, p_bathrooms, p_sqft_living, p_sqft_lot,
        p_floors, p_waterfront, p_house_view, p_house_condition, p_grade, p_sqft_above,
        p_sqft_basement, p_yr_built, p_yr_renovated, p_zipcode, p_latitude,
        p_longitude, p_sqft_living15, p_sqft_lot15
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Rekord pomyślnie dodany.');

EXCEPTION
    -- Obsługa wyjątku, jeśli rekord istnieje
    WHEN record_exist THEN
--         RAISE_APPLICATION_ERROR(-20001, 'Rekord o podanym ID już istnieje w tabeli.');
        DBMS_OUTPUT.PUT_LINE('Rekord o podanym ID już istnieje w tabeli.');

    -- Obsługa innych potencjalnych błędów
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Wystąpił błąd: ' || SQLERRM);
END;
/
-- Procedura modyfikacji rekordu po wybranych parametrach, obsługa błędów
create or replace PROCEDURE update_house (
    p_id NUMBER,
    p_new_sale_date DATE DEFAULT NULL,
    p_new_price NUMBER DEFAULT NULL,
    p_new_bedrooms NUMBER DEFAULT NULL,
    p_new_bathrooms NUMBER DEFAULT NULL,
    p_new_sqft_living NUMBER DEFAULT NULL,
    p_new_sqft_lot NUMBER DEFAULT NULL,
    p_new_floors NUMBER DEFAULT NULL,
    p_new_waterfront NUMBER DEFAULT NULL,
    p_new_house_view NUMBER DEFAULT NULL,
    p_new_house_condition NUMBER DEFAULT NULL,
    p_new_grade NUMBER DEFAULT NULL,
    p_new_sqft_above NUMBER DEFAULT NULL,
    p_new_sqft_basement NUMBER DEFAULT NULL,
    p_new_yr_built NUMBER DEFAULT NULL,
    p_new_yr_renovated NUMBER DEFAULT NULL,
    p_new_zipcode VARCHAR2 DEFAULT NULL,
    p_new_latitude NUMBER DEFAULT NULL,
    p_new_longitude NUMBER DEFAULT NULL,
    p_new_sqft_living15 NUMBER DEFAULT NULL,
    p_new_sqft_lot15 NUMBER DEFAULT NULL
)
IS
    -- Własny wyjątek, jeśli rekord o danym ID nie istnieje
    record_not_exist EXCEPTION;
BEGIN
    UPDATE stramkoa.houses
    SET
        sale_date = NVL(p_new_sale_date, sale_date),
        price = NVL(p_new_price, price),
        bedrooms = NVL(p_new_bedrooms, bedrooms),
        bathrooms = NVL(p_new_bathrooms, bathrooms),
        sqft_living = NVL(p_new_sqft_living, sqft_living),
        sqft_lot = NVL(p_new_sqft_lot, sqft_lot),
        floors = NVL(p_new_floors, floors),
        waterfront = NVL(p_new_waterfront, waterfront),
        house_view = NVL(p_new_house_view, house_view),
        house_condition = NVL(p_new_house_condition, house_condition),
        grade = NVL(p_new_grade, grade),
        sqft_above = NVL(p_new_sqft_above, sqft_above),
        sqft_basement = NVL(p_new_sqft_basement, sqft_basement),
        yr_built = NVL(p_new_yr_built, yr_built),
        yr_renovated = NVL(p_new_yr_renovated, yr_renovated),
        zipcode = NVL(p_new_zipcode, zipcode),
        latitude = NVL(p_new_latitude, latitude),
        longitude = NVL(p_new_longitude, longitude),
        sqft_living15 = NVL(p_new_sqft_living15, sqft_living15),
        sqft_lot15 = NVL(p_new_sqft_lot15, sqft_lot15)
    WHERE id = p_id;

    -- Rzucenie wyjątku, jeśli rekord o padanym ID nie istnieje
    IF SQL%ROWCOUNT = 0 THEN
        RAISE record_not_exist;
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Rekord pomyślnie zmodyfikowany.');
EXCEPTION
    WHEN record_not_exist THEN
        DBMS_OUTPUT.PUT_LINE('Rekord o podanym ID nie istnieje w tabeli.');

    -- Obsługa innych potencjalnych błędów
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Wystąpił błąd: ' || SQLERRM);
END;
/
-- Procedura usuwania rekordu, obsługa błędów
create or replace PROCEDURE delete_house (
    p_id NUMBER
)
IS
    -- Własny wyjątek, jeśli rekord o danym ID nie istnieje
    record_not_exist EXCEPTION;
BEGIN
    DELETE FROM stramkoa.houses WHERE id = p_id;

    -- Sprawdzenie, czy rekord został usunięty
    IF SQL%ROWCOUNT = 0 THEN
        RAISE record_not_exist;
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Rekord pomyślnie usunięty.');

EXCEPTION
    WHEN record_not_exist THEN
        DBMS_OUTPUT.PUT_LINE('Rekord o podanym ID nie istnieje w tabeli.');

    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Wystąpił błąd: ' || SQLERRM);
END;

-- Procedura generujaca miesieczne podsumowanie wystawionych nieruchomosci
CREATE OR REPLACE PROCEDURE generate_monthly_summary (p_year IN NUMBER, p_month IN NUMBER) AS
BEGIN
    MERGE INTO monthly_summary t
    USING (
        SELECT
            EXTRACT(YEAR FROM sale_date) AS year,
            EXTRACT(MONTH FROM sale_date) AS month,
            COUNT(*) AS total_sales,
            SUM(price) AS total_revenue,
            AVG(price) AS average_price
        FROM houses
        WHERE EXTRACT(YEAR FROM sale_date) = p_year
          AND EXTRACT(MONTH FROM sale_date) = p_month
        GROUP BY EXTRACT(YEAR FROM sale_date), EXTRACT(MONTH FROM sale_date)
    ) s
    ON (t.year = s.year AND t.month = s.month)
    WHEN MATCHED THEN
        UPDATE SET
            t.total_sales = s.total_sales,
            t.total_revenue = s.total_revenue,
            t.average_price = s.average_price
    WHEN NOT MATCHED THEN
        INSERT (year, month, total_sales, total_revenue, average_price)
        VALUES (s.year, s.month, s.total_sales, s.total_revenue, s.average_price);
END;

-- Procedura generujaca kwartalne podsumowanie wystawionych nieruchomosci
CREATE OR REPLACE PROCEDURE generate_quarterly_summary (p_year IN NUMBER, p_quarter IN NUMBER) AS
BEGIN
    MERGE INTO quarterly_summary t
    USING (
        SELECT
            EXTRACT(YEAR FROM sale_date) AS year,
            CEIL(EXTRACT(MONTH FROM sale_date) / 3) AS quarter,
            COUNT(*) AS total_sales,
            SUM(price) AS total_revenue,
            AVG(price) AS average_price
        FROM houses
        WHERE EXTRACT(YEAR FROM sale_date) = p_year
          AND CEIL(EXTRACT(MONTH FROM sale_date) / 3) = p_quarter
        GROUP BY EXTRACT(YEAR FROM sale_date), CEIL(EXTRACT(MONTH FROM sale_date) / 3)
    ) s
    ON (t.year = s.year AND t.quarter = s.quarter)
    WHEN MATCHED THEN
        UPDATE SET
            t.total_sales = s.total_sales,
            t.total_revenue = s.total_revenue,
            t.average_price = s.average_price
    WHEN NOT MATCHED THEN
        INSERT (year, quarter, total_sales, total_revenue, average_price)
        VALUES (s.year, s.quarter, s.total_sales, s.total_revenue, s.average_price);
END;

-- Procedura generujaca roczne podsumowanie wystawionych nieruchomosci
CREATE OR REPLACE PROCEDURE generate_yearly_summary (p_year IN NUMBER) AS
BEGIN
	MERGE INTO yearly_summary t
    USING (
        SELECT
            EXTRACT(YEAR FROM sale_date) AS year,
            COUNT(*) AS total_sales,
            SUM(price) AS total_revenue,
            AVG(price) AS average_price
        FROM houses
        WHERE EXTRACT(YEAR FROM sale_date) = p_year
        GROUP BY EXTRACT(YEAR FROM sale_date)
    ) s
    ON (t.year = s.year)
    WHEN MATCHED THEN
        UPDATE SET
            t.total_sales = s.total_sales,
            t.total_revenue = s.total_revenue,
            t.average_price = s.average_price
    WHEN NOT MATCHED THEN
        INSERT (year, total_sales, total_revenue, average_price)
        VALUES (s.year, s.total_sales, s.total_revenue, s.average_price);
END;

-- Procedura uruchamiajaca generowanie wszystkich podsumowan wystawionych nieruchomosci
CREATE OR REPLACE PROCEDURE generate_all_summaries IS
BEGIN
    FOR r IN (
        SELECT DISTINCT EXTRACT(YEAR FROM sale_date) AS year, EXTRACT(MONTH FROM sale_date) AS month
        FROM houses
    ) LOOP
        generate_monthly_summary(r.year, r.month);
    END LOOP;

    FOR r IN (
        SELECT DISTINCT EXTRACT(YEAR FROM sale_date) AS year, CEIL(EXTRACT(MONTH FROM sale_date) / 3) AS quarter
        FROM houses
    ) LOOP
        generate_quarterly_summary(r.year, r.quarter);
    END LOOP;

    FOR r IN (
        SELECT DISTINCT EXTRACT(YEAR FROM sale_date) AS year
        FROM houses
    ) LOOP
        generate_yearly_summary(r.year);
    END LOOP;
END;
