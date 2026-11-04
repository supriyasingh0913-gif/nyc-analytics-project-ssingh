-- Clean and standardize DOB job filing data

WITH source AS (
    SELECT *
    FROM {{ source('raw', 'source_nyc_dob_job_apps') }}
),

cleaned AS (
    SELECT
        * REPLACE (
            TRIM(job_filing_number) AS job_filing_number,

            UPPER(TRIM(filing_status)) AS filing_status,

            CASE
                WHEN UPPER(TRIM(borough)) IN
                    ('MANHATTAN', 'NEW YORK COUNTY', '1')
                    THEN 'Manhattan'
                WHEN UPPER(TRIM(borough)) IN
                    ('BRONX', 'THE BRONX', '2')
                    THEN 'Bronx'
                WHEN UPPER(TRIM(borough)) IN
                    ('BROOKLYN', 'KINGS COUNTY', '3')
                    THEN 'Brooklyn'
                WHEN UPPER(TRIM(borough)) IN
                    ('QUEENS', 'QUEEN', 'QUEENS COUNTY', '4')
                    THEN 'Queens'
                WHEN UPPER(TRIM(borough)) IN
                    ('STATEN ISLAND', 'RICHMOND COUNTY', '5')
                    THEN 'Staten Island'
                ELSE 'UNKNOWN or CITYWIDE'
            END AS borough,

            CASE
                WHEN REGEXP_CONTAINS(
                    TRIM(zip), r'^\d{5}(-\d{4})?$'
                ) THEN TRIM(zip)
                WHEN REGEXP_CONTAINS(
                    TRIM(postcode), r'^\d{5}(-\d{4})?$'
                ) THEN TRIM(postcode)
                ELSE NULL
            END AS zip,

            NULLIF(TRIM(council_district), '') AS council_district,

            SAFE_CAST(latitude AS NUMERIC) AS latitude,
            SAFE_CAST(longitude AS NUMERIC) AS longitude,

            SAFE_CAST(
                REPLACE(REPLACE(initial_cost, '$', ''), ',', '')
                AS NUMERIC
            ) AS initial_cost,

            CAST(filing_date AS DATE) AS filing_date,
            CAST(current_status_date AS DATE) AS current_status_date,
            CAST(first_permit_date AS DATE) AS first_permit_date,
            CAST(approved_date AS DATE) AS approved_date,
            CAST(signoff_date AS DATE) AS signoff_date
        ),

        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    WHERE NULLIF(TRIM(job_filing_number), '') IS NOT NULL
)

SELECT * FROM cleaned