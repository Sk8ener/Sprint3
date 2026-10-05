-- creación dataset silver:
CREATE SCHEMA IF NOT EXISTS sprint3_silver
OPTIONS (location = 'europe-southwest1');

-- Ejercicio 2 creación de tabla transactions_raw:
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-reneb.sprint3_bronze.transactions_raw`
OPTIONS (
  format = 'CSV',
  field_delimiter = ';',
  uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv']
);

-- Creación de companies_raw:
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-reneb.sprint3_bronze.companies_raw`(
company_id STRING, company_name STRING, phone STRING, email STRING, country STRING, website STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
  skip_leading_rows = 1
);

-- creación del resto de tablas 
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-reneb.sprint3_bronze.american_users_raw`
OPTIONS (
  format = 'CSV',
  field_delimiter = ', ',
  uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv']
);

CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-reneb.sprint3_bronze.european_users_raw`
OPTIONS (
  format = 'CSV',
  field_delimiter = ', ',
  uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv']
);

CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-reneb.sprint3_bronze.credit_cards_raw`
OPTIONS (
  format = 'CSV',
  field_delimiter = ', ',
  uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv']
);

-- Materialización de datos (Asistido por AI)
/*"Write a SQL query to create a new table called transactions_raw_native in the sprint3_bronze dataset. It should contain all data from the transactions_raw table. Please use CREATE OR REPLACE TABLE so I don't get errors if I run it more than once."*/

CREATE OR REPLACE TABLE `sprint3-analytics-reneb.sprint3_bronze.transactions_raw_native` AS
SELECT
  id,
  card_id,
  business_id,
  timestamp,
  amount,
  declined,
  product_ids,
  user_id,
  lat,
  longitude
FROM
  `sprint3-analytics-reneb.sprint3_bronze.transactions_raw`;

-- Auditoría de costos
-- Tabla nativa
SELECT id
FROM `sprint3-analytics-reneb.sprint3_bronze.transactions_raw_native`
LIMIT 10;

-- Tabla nativa
SELECT id
FROM `sprint3-analytics-reneb.sprint3_bronze.transactions_raw_native`
;
-- Tabla externa
SELECT id
FROM `sprint3-analytics-reneb.sprint3_bronze.transactions_raw`
LIMIT 10;

-- Tabla externa
SELECT id
FROM `sprint3-analytics-reneb.sprint3_bronze.transactions_raw`;

-- Ejercicio 5 
SELECT EXTRACT(DATE FROM timestamp) AS dia, ROUND(SUM(amount),2) AS ingresos_totales
FROM `sprint3-analytics-reneb.sprint3_bronze.transactions_raw_native`
WHERE EXTRACT(YEAR FROM timestamp) = 2021 AND declined = 0
GROUP BY dia
ORDER BY ingresos_totales DESC
LIMIT 5;

-- Ejercicio 6
SELECT 
    c.company_name AS nombre, 
    c.country AS pais, 
    DATE(t.timestamp) AS fecha
FROM `sprint3-analytics-reneb.sprint3_bronze.transactions_raw_native` AS t
JOIN `sprint3-analytics-reneb.sprint3_bronze.companies_raw` AS c
  ON t.business_id = c.company_id
WHERE t.amount BETWEEN 100 AND 200
  AND DATE(t.timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13')
  ORDER BY fecha;

-- Nivel 2, Ejercicio 1: 
CREATE OR REPLACE TABLE `sprint3-analytics-reneb.sprint3_silver.products_clean` AS
SELECT
  id AS product_id,
  product_name AS name,
  SAFE_CAST(REPLACE(warehouse_id, 'WH-', '') AS INT64) AS warehouse_id,
  SAFE_CAST(price AS FLOAT64) AS price,
  colour,
  weight,
  category,
  brand,
  cost,
  launch_date
  
FROM
  `sprint3-analytics-reneb.sprint3_bronze.products_raw`;

-- Ejercicio 2
CREATE OR REPLACE TABLE `sprint3-analytics-reneb.sprint3_silver.transactions_clean` AS
SELECT
  id AS transaction_id,
  IFNULL(SAFE_CAST(amount AS FLOAT64), 0.0) AS amount,
  timestamp, 
  SAFE_CAST(lat AS FLOAT64) AS lat,
  SAFE_CAST(longitude AS FLOAT64) AS longitude,
  card_id,
  business_id AS company_id,
  declined,
  user_id,
  
  ARRAY(
    SELECT SAFE_CAST(TRIM(item) AS INT64)
    FROM UNNEST(SPLIT(product_ids, ',')) AS item
    WHERE TRIM(item) != ''
  ) AS product_ids,
  
FROM
  `sprint3-analytics-reneb.sprint3_bronze.transactions_raw`;

-- Ejercicio 3
CREATE OR REPLACE TABLE `sprint3-analytics-reneb.sprint3_silver.users_combined`
AS
SELECT
  id AS user_id,
  name,
  surname,
  phone,
  email,
  birth_date,
  country,
  city,
  postal_code,
  address,
  'North_America' AS origin
FROM `sprint3-analytics-reneb.sprint3_bronze.american_users_raw`
UNION ALL
SELECT
  id AS user_id,
  name,
  surname,
  phone,
  email,
  birth_date,
  country,
  city,
  postal_code,
  address,
  'Europe' AS origin
FROM `sprint3-analytics-reneb.sprint3_bronze.european_users_raw`;

-- Ejercicio 4
-- 1. Crear tabla nativa de Compañías (companies_clean)
CREATE OR REPLACE TABLE `sprint3-analytics-reneb.sprint3_silver.companies_clean` AS
SELECT
  company_id,
  company_name,
  phone,
  email,
  country,
  website
FROM `sprint3-analytics-reneb.sprint3_bronze.companies_raw`;

-- 2. Crear tabla nativa de Tarjetas de Crédito (credit_cards_clean)
CREATE OR REPLACE TABLE `sprint3-analytics-reneb.sprint3_silver.credit_cards_clean` AS
SELECT
  id AS card_id,
  user_id,
  iban,
  pan,
  pin,
  cvv,
  track1,
  track2,
  expiring_date
FROM`sprint3-analytics-reneb.sprint3_bronze.credit_cards_raw`;

-- Nivel 3
CREATE OR REPLACE VIEW `sprint3-analytics-reneb.sprint3_gold.v_marketing_kpis` AS
SELECT
    c.company_name, c.phone,  c.country,      
    ROUND(AVG(t.amount), 2) AS average_purchase, 
    
    CASE 
        WHEN AVG(t.amount) > 260 THEN 'Premium'
        ELSE 'Standard'
    END AS client_tier

FROM 
    `sprint3-analytics-reneb.sprint3_silver.companies_clean` AS c
INNER JOIN 
    `sprint3-analytics-reneb.sprint3_silver.transactions_clean` AS t
    ON c.company_id = t.company_id
    WHERE t.declined = 0
GROUP BY 
    c.company_name, 
    c.phone, 
    c.country;

-- Consulta de vista

SELECT *
FROM `sprint3-analytics-reneb.sprint3_gold.v_marketing_kpis`
ORDER BY
  client_tier ASC,  
  average_purchase DESC;  

-- Ejercicio 2 Ranking de productos
-- Creación de la tabla de ranking de productos en la capa Gold
CREATE OR REPLACE TABLE `sprint3-analytics-reneb.sprint3_gold.product_sales_ranking` AS
WITH flattened_transactions AS (
  -- Aplanamos el array de product_ids para tener una fila por cada producto vendido
  SELECT
    product_id_sold
  FROM
    `sprint3-analytics-reneb.sprint3_silver.transactions_clean`,
    UNNEST(product_ids) AS product_id_sold
)
SELECT p.product_id,p.name,p.price, p.colour AS color,
  COUNT(t.product_id_sold) AS total_sold
FROM
  `sprint3-analytics-reneb.sprint3_silver.products_clean` AS p
LEFT JOIN
  flattened_transactions AS t
ON
  p.product_id = t.product_id_sold
GROUP BY p.product_id, p.name, p.price, p.colour
ORDER BY total_sold DESC;


