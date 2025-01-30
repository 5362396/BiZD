-- Funkcja licząca srednia cene dla roku budowy lub zakresu metrow kwadratowych
create or replace FUNCTION get_average_price (
    p_yr_built VARCHAR2 DEFAULT NULL,
    p_min_sqft NUMBER DEFAULT NULL,
    p_max_sqft NUMBER DEFAULT NULL
)
RETURN NUMBER
IS
    avg_price NUMBER;
BEGIN
SELECT AVG(price)
INTO avg_price
FROM stramkoa.houses
WHERE yr_built = NVL(p_yr_built, yr_built)
    AND (p_min_sqft IS NULL OR sqft_living >= p_min_sqft)
    AND (p_max_sqft IS NULL OR sqft_living <= p_max_sqft);

RETURN ROUND(avg_price, 2);
END;
/

-- Funkcja zwracajaca rekordy dla przedzialu podanej ceny, przedzialu metrażu domu, ilość pokoi,  roku budowy (pola mogą być puste)
create or replace FUNCTION get_houses_in_ranges (
    p_min_price NUMBER DEFAULT NULL,
    p_max_price NUMBER DEFAULT NULL,
    p_min_sqft NUMBER DEFAULT NULL,
    p_max_sqft NUMBER DEFAULT NULL,
    p_min_bedrooms NUMBER DEFAULT NULL,
    p_max_bedrooms NUMBER DEFAULT NULL,
    p_min_year_built NUMBER DEFAULT NULL,
    p_max_year_built NUMBER DEFAULT NULL
)
RETURN SYS_REFCURSOR
IS
    result SYS_REFCURSOR;
BEGIN
    OPEN result FOR
        SELECT id, price, sqft_living, bedrooms, yr_built
        FROM stramkoa.houses
        WHERE
            (p_min_price IS NULL OR price >= p_min_price) AND
            (p_max_price IS NULL OR price <= p_max_price) AND
            (p_min_sqft IS NULL OR sqft_living >= p_min_sqft) AND
            (p_max_sqft IS NULL OR sqft_living <= p_max_sqft) AND
            (p_min_bedrooms IS NULL OR bedrooms >= p_min_bedrooms) AND
            (p_max_bedrooms IS NULL OR bedrooms <= p_max_bedrooms) AND
            (p_min_year_built IS NULL OR yr_built >= p_min_year_built) AND
            (p_max_year_built IS NULL OR yr_built <= p_max_year_built);

    RETURN result;
END;
/

-- Funkcja tworząca ranking top 20 domow z najnizsza cena za metr 2 w danym zakresie
create or replace FUNCTION get_houses_price_per_sqm_ranking (
    p_min_price NUMBER DEFAULT NULL,
    p_max_price NUMBER DEFAULT NULL,
    p_min_sqft NUMBER DEFAULT NULL,
    p_max_sqft NUMBER DEFAULT NULL,
    p_min_bedrooms NUMBER DEFAULT NULL,
    p_max_bedrooms NUMBER DEFAULT NULL,
    p_min_year_built NUMBER DEFAULT NULL,
    p_max_year_built NUMBER DEFAULT NULL
)
RETURN SYS_REFCURSOR
IS
    v_houses SYS_REFCURSOR;
BEGIN
    OPEN v_houses FOR
        SELECT id, price, sqft_living, bedrooms, yr_built,
               price / (sqft_living * 0.092903) AS price_per_m2,
               RANK() OVER (ORDER BY price / (sqft_living * 0.092903) ASC) AS price_per_m2_rank,
               LAG(price / (sqft_living * 0.092903), 1) OVER (ORDER BY price / (sqft_living * 0.092903) ASC) AS prev_price_per_m2,
               price / (sqft_living * 0.092903) - LAG(price / (sqft_living * 0.092903), 1) OVER (ORDER BY price / (sqft_living * 0.092903) ASC) AS price_per_m2_diff
        FROM stramkoa.houses
        WHERE
            (p_min_price IS NULL OR price >= p_min_price) AND
            (p_max_price IS NULL OR price <= p_max_price) AND
            (p_min_sqft IS NULL OR sqft_living >= p_min_sqft) AND
            (p_max_sqft IS NULL OR sqft_living <= p_max_sqft) AND
            (p_min_bedrooms IS NULL OR bedrooms >= p_min_bedrooms) AND
            (p_max_bedrooms IS NULL OR bedrooms <= p_max_bedrooms) AND
            (p_min_year_built IS NULL OR yr_built >= p_min_year_built) AND
            (p_max_year_built IS NULL OR yr_built <= p_max_year_built)
            AND ROWNUM <= 20;

    RETURN v_houses;
END;
/

-- Funkcja wyliczajaca cene za m2 dla danego id
create or replace FUNCTION get_price_per_sqm(p_id NUMBER)
RETURN NUMBER
IS
    price_per_sqm NUMBER;
    price NUMBER;
    sqft_living NUMBER;
BEGIN
    SELECT price, sqft_living
    INTO price, sqft_living
    FROM stramkoa.houses
    WHERE id = p_id;

    IF sqft_living > 0 THEN
        price_per_sqm := ROUND(price / (sqft_living * 0.092903), 2); -- 0.092903 to konwersja z sqft na m²
    ELSE
        price_per_sqm := NULL;
    END IF;

    RETURN price_per_sqm;
END;

-- Funkcja pobierajaca miesieczne zestawienia z wybranego roku
CREATE OR REPLACE FUNCTION get_monthly_summary(p_year IN NUMBER)
RETURN SYS_REFCURSOR AS
    result_cursor SYS_REFCURSOR;
BEGIN
    OPEN result_cursor FOR
    SELECT * FROM monthly_summary WHERE year = p_year;
    RETURN result_cursor;
END;

-- Funkcja pobierajaca kwartalne zestawienia z wybranego roku
CREATE OR REPLACE FUNCTION get_quarterly_summary(p_year IN NUMBER)
RETURN SYS_REFCURSOR AS
    result_cursor SYS_REFCURSOR;
BEGIN
    OPEN result_cursor FOR
    SELECT * FROM quarterly_summary WHERE year = p_year;
    RETURN result_cursor;
END;