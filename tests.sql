--TEST dodanie rekordu do tabeli i obs�uga duplikatu ID
BEGIN
    add_house(
        p_id => 1523300881,
        p_sale_date => TO_DATE('2025-01-01', 'YYYY-MM-DD'),
        p_price => -500000,
        p_bedrooms => 3,
        p_bathrooms => 2,
        p_sqft_living => 1500,
        p_sqft_lot => 6000,
        p_floors => 1,
        p_waterfront => 0,
        p_house_view => 0,
        p_house_condition => 5,
        p_grade => 7,
        p_sqft_above => 1500,
        p_sqft_basement => 0,
        p_yr_built => 2000,
        p_yr_renovated => 0,
        p_zipcode => '98178',
        p_latitude => 47.5112,
        p_longitude => -122.257,
        p_sqft_living15 => 1600,
        p_sqft_lot15 => 7000
    );
END;
/

--TEST modyfikacji kilku p�l rekordu i obs�uga nieistniej�cego ID
BEGIN
    update_house(
        p_id => 1523300889,
        p_new_price => 550000,
        p_new_bedrooms => 4,
        p_new_floors => 2
    );
END;
/
BEGIN
    update_house(
        p_id => 1, -- ID nie istnieje
        p_new_price => 300000
    );
END;
/

-- TEST usuwanie rekordu istniej�cego i nieistniej�cego rekordu, archiwizacja
BEGIN
    delete_house(p_id => 1523300889);
END;
/
BEGIN
    delete_house(p_id => 1);
END;

-- TEST srednich cen dla roku budowy 
SELECT get_average_price('2000') FROM dual;
SELECT get_average_price('2000', 1000, NULL) FROM dual;
SELECT get_average_price('2000', 600, 2000) FROM dual;

-- TEST ceny za m2 dla danego ID
SELECT get_price_per_sqm(5460500040) FROM dual;


-- TEST funkcji zwracajacej rekordy dla przedzialu podanej ceny, przedzialu metra�u domu, ilo�� pokoi, roku budowy (pola mog� by� puste)
SET SERVEROUTPUT ON;

DECLARE
    v_houses SYS_REFCURSOR;
    v_id NUMBER;
    v_price NUMBER;
    v_sqft_living NUMBER;
    v_bedrooms NUMBER;
    v_yr_built NUMBER;
BEGIN
    v_houses := get_houses_in_ranges(100000, 200000, NULL, 1700, 2, 4, 1990, 2000);

    IF v_houses%ISOPEN THEN
        LOOP
            FETCH v_houses INTO v_id, v_price, v_sqft_living, v_bedrooms, v_yr_built;
            EXIT WHEN v_houses%NOTFOUND;
            
            DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ', Price: ' || v_price || ', Sqft: ' || v_sqft_living || ', Bedrooms: ' || v_bedrooms || ', Year Built: ' || v_yr_built);
        END LOOP;

        CLOSE v_houses;
    ELSE
        DBMS_OUTPUT.PUT_LINE('Brak wynik�w w kursorze.');
    END IF;
END;
/

-- TEST rankingu domow za m2
SET SERVEROUTPUT ON;

DECLARE
    v_houses SYS_REFCURSOR;
    v_id NUMBER;
    v_price NUMBER;
    v_sqft_living NUMBER;
    v_bedrooms NUMBER;
    v_yr_built NUMBER;
    v_price_per_m2 NUMBER;
    v_price_per_m2_rank NUMBER;
    v_prev_price_per_m2 NUMBER;
    v_price_per_m2_diff NUMBER;
BEGIN
    v_houses := get_houses_price_per_sqm_ranking(100000, 500000, 1500, 3000);

    LOOP
        FETCH v_houses INTO v_id, v_price, v_sqft_living, v_bedrooms, v_yr_built, v_price_per_m2, v_price_per_m2_rank, v_prev_price_per_m2, v_price_per_m2_diff;
        EXIT WHEN v_houses%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ', Price: ' || v_price || ', Sqft: ' || v_sqft_living || 
                             ', Bedrooms: ' || v_bedrooms || ', Year Built: ' || v_yr_built || 
                             ', Price per m2: ' || ROUND(v_price_per_m2,2) || ', Rank: ' || v_price_per_m2_rank || 
                             ', Prev Price per m2: ' || ROUND(v_prev_price_per_m2,2) || ', Price per m2 Diff: ' || ROUND(v_price_per_m2_diff,2));
    END LOOP;

    CLOSE v_houses;
END;

-- TEST miesiecznych zestawien
BEGIN
    generate_monthly_summary(2014, 7);
END;

-- TEST kwartalnych zestawien
BEGIN
    generate_quarterly_summary(2014, 3);
END;

-- TEST rocznych zestawien
BEGIN
    generate_yearly_summary(2014);
END;

-- TEST uruchomienia wszyskich zestawien
BEGIN
    generate_all_summaries;
END;
