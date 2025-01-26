import os
import oracledb
import pandas as pd
import time
from datetime import datetime


# Konfiguracja połączenia z bazą danych
DB_USERNAME = 'xxx'
DB_PASSWORD = 'yyy'
DB_HOST = 'zzz'
DB_PORT = 1521
DB_SID = 'orcl'

CSV_FILE_PATH = './kc_house_data.csv'  # Ścieżka do pliku CSV z danymi sprzedaży domów na podstawie https://www.kaggle.com/datasets/harlfoxem/housesalesprediction
CHECK_INTERVAL = 60  # Interwał w sekundach, co ile dogrywamy do bazy nowe rekordy z pliku
ARCHIVE_DIR = './archive'  # Ścieżka do folderu z archiwami przetworzonych danych do bazy


def load_csv_to_db():
    """Funkcja do załadowania danych z CSV do bazy danych."""

    if not os.path.exists(CSV_FILE_PATH):
        print(f'Plik {CSV_FILE_PATH} nie istnieje.')
        return

    try:
        data = pd.read_csv(CSV_FILE_PATH)
        data = validate_data(data)

        # Nawiązanie połączenia z bazą danych
        dsn = oracledb.makedsn(host=DB_HOST, port=DB_PORT, sid=DB_SID)
        connection = oracledb.connect(user=DB_USERNAME, password=DB_PASSWORD, dsn=dsn)
        cursor = connection.cursor()

        # Iteracja po wierszach DataFrame i wstawianie danych
        for _, row in data.iterrows():
            cursor.execute(
                """
                MERGE INTO houses t
                USING (
                    SELECT :id AS id FROM dual
                ) s
                ON (t.id = s.id)
                WHEN NOT MATCHED THEN
                INSERT (
                    id, sale_date, price, bedrooms, bathrooms, sqft_living, sqft_lot,
                    floors, waterfront, house_view, house_condition, grade, sqft_above,
                    sqft_basement, yr_built, yr_renovated, zipcode, latitude, longitude,
                    sqft_living15, sqft_lot15
                )
                VALUES (
                    :id, TO_DATE(:sale_date, 'YYYYMMDDHH24MISS'), :price, :bedrooms, :bathrooms, :sqft_living,
                    :sqft_lot, :floors, :waterfront, :house_view, :house_condition, :grade, :sqft_above,
                    :sqft_basement, :yr_built, :yr_renovated, :zipcode, :latitude, :longitude,
                    :sqft_living15, :sqft_lot15
                )
                """,
                {
                    'id': row['id'],
                    'sale_date': row['sale_date'],
                    'price': row['price'],
                    'bedrooms': row['bedrooms'],
                    'bathrooms': row['bathrooms'],
                    'sqft_living': row['sqft_living'],
                    'sqft_lot': row['sqft_lot'],
                    'floors': row['floors'],
                    'waterfront': row['waterfront'],
                    'house_view': row['house_view'],
                    'house_condition': row['house_condition'],
                    'grade': row['grade'],
                    'sqft_above': row['sqft_above'],
                    'sqft_basement': row['sqft_basement'],
                    'yr_built': row['yr_built'],
                    'yr_renovated': row['yr_renovated'],
                    'zipcode': row['zipcode'],
                    'latitude': row['latitude'],
                    'longitude': row['longitude'],
                    'sqft_living15': row['sqft_living15'],
                    'sqft_lot15': row['sqft_lot15']
                }
            )

        # Zatwierdzenie transakcji
        connection.commit()
        print('Dane zostały załadowane do bazy danych.')
        archive_data(data)
        os.remove(CSV_FILE_PATH)
        print(f'Plik {CSV_FILE_PATH} został usunięty po przetworzeniu.')

    except Exception as e:  # Wyświetlanie błędów po stronie bazy danych
        print(f'Wystąpił błąd podczas ładowania danych: {e}')

    finally:  # Zakończenie połączenia z bazą danych
        if 'cursor' in locals():
            cursor.close()
        if 'connection' in locals():
            connection.close()


def validate_data(data):
    """Funkcja sprawdzająca poprawność danych."""

    column_mapping = {  # Mapowanie nazw kolumn, żeby nie trafić na słowa kluczowe w SQL
        'date': 'sale_date',
        'view': 'house_view',
        'condition': 'house_condition',
        'lat': 'latitude',
        'long': 'longitude'
    }
    data.rename(columns=column_mapping, inplace=True)
    data = data.replace(r'"', '', regex=True)  # Usunięcie z niektórych wartości niepotrzebnych cudzysłowów
    data = data.drop_duplicates(subset='id')  # Usunięcie duplikatów o tym samym ID
    data['sale_date'] = data['sale_date'].str.replace('T', '')  # Naprawa formatu daty

    return data


def archive_data(data):
    """Funkcja do archiwizacji danych."""
    if not os.path.exists(ARCHIVE_DIR):  # Tworzenie katalogu archiwalnego, jeśli nie istnieje
        os.makedirs(ARCHIVE_DIR)

    # Zapis danych do pliku CSV z timestampem
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    archive_path = os.path.join(ARCHIVE_DIR, f'processed_{timestamp}.csv')
    data.to_csv(archive_path, index=False)
    print(f'Dane zostały zarchiwizowane w {archive_path}')


# Główna pętla programu
if __name__ == '__main__':
    while True:
        print('Sprawdzanie pliku CSV...')
        load_csv_to_db()
        print(f'Ponowne sprawdzenie za {CHECK_INTERVAL} sekund...')
        time.sleep(CHECK_INTERVAL)
