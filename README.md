# Sprint3
### Data Analytics Pipeline: Sprint 3 (ERP & Transactions)
Este proyecto implementa un pipeline de datos en Google BigQuery utilizando una arquitectura de medallas (Bronze, Silver, Gold) para procesar datos provenientes de un ERP y sistemas de transacciones, transformándolos en información estratégica de negocio.

### 🏗️ Arquitectura de Datos
El proyecto se divide en tres capas lógicas para garantizar la trazabilidad y calidad de los datos:

### 1. Capa Bronze (Raw Data)
Contiene los datos en su formato original, cargados directamente desde archivos CSV alojados en Google Cloud Storage (gs://bootcamp-data-analytics-public/ERP/).

Tablas Externas: companies_raw, products_raw, american_users_raw, european_users_raw.
Tablas Nativas: transactions_raw, credit_cards_raw.
Configuración: Esquemas definidos manualmente para manejar formatos de texto y limpieza de cabeceras.

### 2. Capa Silver (Clean Data)
En esta capa se realiza la limpieza, tipado de datos y unión de fuentes geográficas.
users_combined: Unión de usuarios americanos y europeos en una única fuente de verdad.
transactions_clean: Datos con formatos de fecha correctos y limpieza de nulos.
products_clean, companies_clean, credit_cards_clean: Tablas con esquemas normalizados y tipos de datos optimizados.

### 3. Capa Gold (Business Logic)
Datos agregados y KPIs listos para ser consumidos por herramientas de BI (como Looker Studio) o analistas de negocio.
product_sales_ranking: Ranking de ventas por producto. Utiliza técnicas de UNNEST para desglosar transacciones con múltiples productos y ordena los resultados por volumen de ventas.

### v_marketing_kpis: 
Vista con indicadores clave de rendimiento para el departamento de marketing.

### 🚀 Consultas Destacadas Ranking de Ventas (Capa Gold)
Esta consulta utiliza UNNEST para aplanar arrays de productos y calcula el total vendido por cada ítem del catálogo:

CREATE OR REPLACE TABLE `sprint3-analytics-reneb.sprint3_gold.product_sales_ranking` AS
WITH flattened_transactions AS (
  SELECT product_id_sold
  FROM `sprint3-analytics-reneb.sprint3_silver.transactions_clean`,
  UNNEST(product_ids) AS product_id_sold
)
SELECT p.product_id, p.name, p.price, p.colour AS color, COUNT(t.product_id_sold) AS total_sold
FROM `sprint3-analytics-reneb.sprint3_silver.products_clean` AS p
LEFT JOIN flattened_transactions AS t ON p.product_id = t.product_id_sold
GROUP BY 1, 2, 3, 4
ORDER BY total_sold DESC;


### 🛠️ Tecnologías utilizadas
Google BigQuery: Motor de almacenamiento y procesamiento SQL.
Google Cloud Storage: Almacenamiento de archivos fuente (CSV).
GoogleSQL: Dialecto para transformaciones y modelado.

### Cómo usar este repositorio
Los scripts SQL de creación se encuentran en la carpeta Sprint3.pdf
El esquema de datos completo se puede consultar mediante INFORMATION_SCHEMA en el proyecto sprint3-analytics-reneb
así como en el archivo sprint3.sql.
