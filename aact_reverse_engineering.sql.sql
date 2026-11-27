/*
===============================================================================
FIT5137 Assignment 4 — Reverse Engineering Project
AACT Oracle Validation Queries
===============================================================================

Project Tags:
[REVERSE ENGINEERING] [SCHEMA DISCOVERY] [DATA VALIDATION]
[LOGICAL KEYS] [RELATIONSHIP VALIDATION] [BASELINE ERD]

Purpose:
- Reverse engineer the supplied AACT Oracle teaching schema.
- Validate AI-generated recommendations against database evidence.
- Inspect table structure, row grain, uniqueness and logical relationships.
- Support final table classification, core-table selection and baseline ERD design.

Notes:
- These are read-only validation queries.
- Quoted identifiers such as "nct_id" and "id" are preserved because the
  supplied AACT teaching schema uses case-sensitive quoted column names.
- The supplied schema has no declared physical PK/FK constraints, therefore
  logical keys and relationships are validated using data evidence and joins.
- Query numbering is retained to make evidence easy to reference in the report
  and video presentation.
===============================================================================
*/


-- =============================================================================
-- 1. [REVERSE ENGINEERING | SCHEMA DISCOVERY]
-- =============================================================================

-- Query 01
-- List all tables available in the AACT schema.
SELECT table_name
FROM all_tables
WHERE owner = 'AACT'
ORDER BY table_name;


-- Query 02
-- Check whether Oracle declares any physical primary-key or foreign-key
-- constraints in the supplied AACT teaching schema.
SELECT
    c.table_name,
    CASE
        WHEN c.constraint_type = 'P' THEN 'PRIMARY KEY'
        WHEN c.constraint_type = 'R' THEN 'FOREIGN KEY'
    END AS constraint_type,
    c.constraint_name,
    cc.column_name,
    r.table_name AS referenced_table,
    rcc.column_name AS referenced_column
FROM all_constraints c
JOIN all_cons_columns cc
    ON c.owner = cc.owner
   AND c.constraint_name = cc.constraint_name
LEFT JOIN all_constraints r
    ON c.r_owner = r.owner
   AND c.r_constraint_name = r.constraint_name
LEFT JOIN all_cons_columns rcc
    ON r.owner = rcc.owner
   AND r.constraint_name = rcc.constraint_name
   AND cc.position = rcc.position
WHERE c.owner = 'AACT'
  AND c.constraint_type IN ('P', 'R')
ORDER BY c.table_name, c.constraint_type, cc.position;


-- Query 03
-- Inspect every column and data type in the AACT schema.
SELECT
    table_name,
    column_id,
    column_name,
    data_type
FROM all_tab_columns
WHERE owner = 'AACT'
ORDER BY table_name, column_id;


-- Query 04
-- Produce a compact column summary for tables after MESH_TERMS alphabetically.
SELECT
    table_name,
    LISTAGG(column_name || ' (' || data_type || ')', ', ')
        WITHIN GROUP (ORDER BY column_id) AS columns
FROM all_tab_columns
WHERE owner = 'AACT'
  AND table_name > 'MESH_TERMS'
GROUP BY table_name
ORDER BY table_name;


-- =============================================================================
-- 2. [REVERSE ENGINEERING | CENTRAL ENTITY VALIDATION]
-- =============================================================================

-- Query 05
-- Test whether STUDIES.nct_id behaves as a logical primary key.
SELECT
    COUNT(*) AS total_rows,
    COUNT("nct_id") AS non_null_nct_id,
    COUNT(DISTINCT "nct_id") AS distinct_nct_id,
    COUNT(*) - COUNT("nct_id") AS null_nct_id
FROM AACT.STUDIES;


-- Query 06
-- Explicitly search for duplicate study identifiers.
-- No returned rows means nct_id is unique.
SELECT
    "nct_id",
    COUNT(*) AS row_count
FROM AACT.STUDIES
GROUP BY "nct_id"
HAVING COUNT(*) > 1;


-- Query 07
-- Compare row counts and study coverage of major operational tables.
SELECT
    'CONDITIONS' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT "nct_id") AS distinct_studies
FROM AACT.CONDITIONS

UNION ALL

SELECT
    'INTERVENTIONS',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.INTERVENTIONS

UNION ALL

SELECT
    'FACILITIES',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.FACILITIES

UNION ALL

SELECT
    'SPONSORS',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.SPONSORS

UNION ALL

SELECT
    'DESIGNS',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.DESIGNS

UNION ALL

SELECT
    'ELIGIBILITIES',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.ELIGIBILITIES

UNION ALL

SELECT
    'DESIGN_GROUPS',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.DESIGN_GROUPS

UNION ALL

SELECT
    'DESIGN_OUTCOMES',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.DESIGN_OUTCOMES

UNION ALL

SELECT
    'RESULT_GROUPS',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.RESULT_GROUPS

UNION ALL

SELECT
    'OUTCOMES',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.OUTCOMES;


-- Query 08
-- Check whether major child tables contain nct_id values with no matching
-- STUDIES record. Zero orphan rows supports STUDIES as the central entity.
SELECT
    'CONDITIONS' AS table_name,
    COUNT(*) AS orphan_rows
FROM AACT.CONDITIONS c
LEFT JOIN AACT.STUDIES s
    ON c."nct_id" = s."nct_id"
WHERE s."nct_id" IS NULL

UNION ALL

SELECT
    'INTERVENTIONS',
    COUNT(*)
FROM AACT.INTERVENTIONS i
LEFT JOIN AACT.STUDIES s
    ON i."nct_id" = s."nct_id"
WHERE s."nct_id" IS NULL

UNION ALL

SELECT
    'FACILITIES',
    COUNT(*)
FROM AACT.FACILITIES f
LEFT JOIN AACT.STUDIES s
    ON f."nct_id" = s."nct_id"
WHERE s."nct_id" IS NULL

UNION ALL

SELECT
    'SPONSORS',
    COUNT(*)
FROM AACT.SPONSORS sp
LEFT JOIN AACT.STUDIES s
    ON sp."nct_id" = s."nct_id"
WHERE s."nct_id" IS NULL

UNION ALL

SELECT
    'DESIGNS',
    COUNT(*)
FROM AACT.DESIGNS d
LEFT JOIN AACT.STUDIES s
    ON d."nct_id" = s."nct_id"
WHERE s."nct_id" IS NULL

UNION ALL

SELECT
    'ELIGIBILITIES',
    COUNT(*)
FROM AACT.ELIGIBILITIES e
LEFT JOIN AACT.STUDIES s
    ON e."nct_id" = s."nct_id"
WHERE s."nct_id" IS NULL

UNION ALL

SELECT
    'DESIGN_GROUPS',
    COUNT(*)
FROM AACT.DESIGN_GROUPS dg
LEFT JOIN AACT.STUDIES s
    ON dg."nct_id" = s."nct_id"
WHERE s."nct_id" IS NULL

UNION ALL

SELECT
    'DESIGN_OUTCOMES',
    COUNT(*)
FROM AACT.DESIGN_OUTCOMES do_
LEFT JOIN AACT.STUDIES s
    ON do_."nct_id" = s."nct_id"
WHERE s."nct_id" IS NULL

UNION ALL

SELECT
    'RESULT_GROUPS',
    COUNT(*)
FROM AACT.RESULT_GROUPS rg
LEFT JOIN AACT.STUDIES s
    ON rg."nct_id" = s."nct_id"
WHERE s."nct_id" IS NULL

UNION ALL

SELECT
    'OUTCOMES',
    COUNT(*)
FROM AACT.OUTCOMES o
LEFT JOIN AACT.STUDIES s
    ON o."nct_id" = s."nct_id"
WHERE s."nct_id" IS NULL;


-- =============================================================================
-- 3. [REVERSE ENGINEERING | LOGICAL KEY & RELATIONSHIP VALIDATION]
-- =============================================================================

-- Query 09
-- Test whether RESULT_GROUPS.id behaves as a logical primary key.
SELECT
    COUNT(*) AS total_rows,
    COUNT("id") AS non_null_id,
    COUNT(DISTINCT "id") AS distinct_id,
    COUNT(*) - COUNT("id") AS null_id
FROM AACT.RESULT_GROUPS;


-- Query 10
-- Explicitly search for duplicate RESULT_GROUPS.id values.
SELECT
    "id",
    COUNT(*) AS row_count
FROM AACT.RESULT_GROUPS
GROUP BY "id"
HAVING COUNT(*) > 1;


-- Query 11
-- Test whether result_group_id in several result tables directly references
-- RESULT_GROUPS.id.
SELECT
    'BASELINE_COUNTS' AS table_name,
    COUNT(*) AS orphan_rows
FROM AACT.BASELINE_COUNTS b
LEFT JOIN AACT.RESULT_GROUPS rg
    ON b."result_group_id" = rg."id"
WHERE b."result_group_id" IS NOT NULL
  AND rg."id" IS NULL

UNION ALL

SELECT
    'BASELINE_MEASUREMENTS',
    COUNT(*)
FROM AACT.BASELINE_MEASUREMENTS b
LEFT JOIN AACT.RESULT_GROUPS rg
    ON b."result_group_id" = rg."id"
WHERE b."result_group_id" IS NOT NULL
  AND rg."id" IS NULL

UNION ALL

SELECT
    'DROP_WITHDRAWALS',
    COUNT(*)
FROM AACT.DROP_WITHDRAWALS d
LEFT JOIN AACT.RESULT_GROUPS rg
    ON d."result_group_id" = rg."id"
WHERE d."result_group_id" IS NOT NULL
  AND rg."id" IS NULL

UNION ALL

SELECT
    'MILESTONES',
    COUNT(*)
FROM AACT.MILESTONES m
LEFT JOIN AACT.RESULT_GROUPS rg
    ON m."result_group_id" = rg."id"
WHERE m."result_group_id" IS NOT NULL
  AND rg."id" IS NULL

UNION ALL

SELECT
    'OUTCOME_ANALYSIS_GROUPS',
    COUNT(*)
FROM AACT.OUTCOME_ANALYSIS_GROUPS oag
LEFT JOIN AACT.RESULT_GROUPS rg
    ON oag."result_group_id" = rg."id"
WHERE oag."result_group_id" IS NOT NULL
  AND rg."id" IS NULL

UNION ALL

SELECT
    'OUTCOME_COUNTS',
    COUNT(*)
FROM AACT.OUTCOME_COUNTS oc
LEFT JOIN AACT.RESULT_GROUPS rg
    ON oc."result_group_id" = rg."id"
WHERE oc."result_group_id" IS NOT NULL
  AND rg."id" IS NULL

UNION ALL

SELECT
    'OUTCOME_MEASUREMENTS',
    COUNT(*)
FROM AACT.OUTCOME_MEASUREMENTS om
LEFT JOIN AACT.RESULT_GROUPS rg
    ON om."result_group_id" = rg."id"
WHERE om."result_group_id" IS NOT NULL
  AND rg."id" IS NULL

UNION ALL

SELECT
    'REPORTED_EVENTS',
    COUNT(*)
FROM AACT.REPORTED_EVENTS re
LEFT JOIN AACT.RESULT_GROUPS rg
    ON re."result_group_id" = rg."id"
WHERE re."result_group_id" IS NOT NULL
  AND rg."id" IS NULL;


-- Query 12
-- Investigate BASELINE_COUNTS rows whose numeric result_group_id does not match.
-- Test whether nct_id + ctgov_group_code provides the appropriate group link.
SELECT
    b."nct_id",
    b."result_group_id",
    b."ctgov_group_code",
    rg2."id" AS id_matched_by_group_code,
    rg2."result_type"
FROM AACT.BASELINE_COUNTS b
LEFT JOIN AACT.RESULT_GROUPS rg1
    ON b."result_group_id" = rg1."id"
LEFT JOIN AACT.RESULT_GROUPS rg2
    ON b."nct_id" = rg2."nct_id"
   AND b."ctgov_group_code" = rg2."ctgov_group_code"
WHERE b."result_group_id" IS NOT NULL
  AND rg1."id" IS NULL
  AND ROWNUM <= 20;


-- Query 13
-- Examine the different kinds of result groups.
SELECT
    "result_type",
    COUNT(*) AS row_count
FROM AACT.RESULT_GROUPS
GROUP BY "result_type"
ORDER BY "result_type";


-- Query 14
-- Check whether nct_id + ctgov_group_code is globally unique.
SELECT
    COUNT(*) AS duplicate_group_pairs
FROM (
    SELECT
        "nct_id",
        "ctgov_group_code"
    FROM AACT.RESULT_GROUPS
    WHERE "nct_id" IS NOT NULL
      AND "ctgov_group_code" IS NOT NULL
    GROUP BY
        "nct_id",
        "ctgov_group_code"
    HAVING COUNT(*) > 1
);


-- Query 15
-- Check whether adding result_type makes the group combination unique.
SELECT
    COUNT(*) AS duplicate_triplets
FROM (
    SELECT
        "nct_id",
        "ctgov_group_code",
        "result_type"
    FROM AACT.RESULT_GROUPS
    WHERE "nct_id" IS NOT NULL
      AND "ctgov_group_code" IS NOT NULL
      AND "result_type" IS NOT NULL
    GROUP BY
        "nct_id",
        "ctgov_group_code",
        "result_type"
    HAVING COUNT(*) > 1
);


-- Query 16
-- Identify which result types contain duplicate study/group-code combinations.
SELECT
    "result_type",
    COUNT(*) AS duplicate_groups
FROM (
    SELECT
        "result_type",
        "nct_id",
        "ctgov_group_code"
    FROM AACT.RESULT_GROUPS
    WHERE "nct_id" IS NOT NULL
      AND "ctgov_group_code" IS NOT NULL
      AND "result_type" IS NOT NULL
    GROUP BY
        "result_type",
        "nct_id",
        "ctgov_group_code"
    HAVING COUNT(*) > 1
)
GROUP BY "result_type"
ORDER BY "result_type";


-- Query 17
-- For Outcome result groups, test whether adding outcome_id creates a
-- unique logical group identifier.
SELECT
    COUNT(*) AS duplicate_outcome_group_keys
FROM (
    SELECT
        "nct_id",
        "ctgov_group_code",
        "outcome_id"
    FROM AACT.RESULT_GROUPS
    WHERE "result_type" = 'Outcome'
      AND "nct_id" IS NOT NULL
      AND "ctgov_group_code" IS NOT NULL
      AND "outcome_id" IS NOT NULL
    GROUP BY
        "nct_id",
        "ctgov_group_code",
        "outcome_id"
    HAVING COUNT(*) > 1
);


-- Query 18
-- Check whether Outcome result groups consistently contain outcome_id.
SELECT
    COUNT(*) AS total_outcome_groups,
    COUNT("outcome_id") AS non_null_outcome_id,
    COUNT(*) - COUNT("outcome_id") AS null_outcome_id
FROM AACT.RESULT_GROUPS
WHERE "result_type" = 'Outcome';


-- =============================================================================
-- 4. [TASK 1 | MASTER & TRANSACTION CANDIDATE VALIDATION]
-- =============================================================================

-- Query 19
-- Compare AI-proposed master/entity candidates by row count, study coverage
-- and number of distinct names.
SELECT
    'FACILITIES' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT "nct_id") AS distinct_studies,
    COUNT(DISTINCT "name") AS distinct_names
FROM AACT.FACILITIES

UNION ALL

SELECT
    'SPONSORS',
    COUNT(*),
    COUNT(DISTINCT "nct_id"),
    COUNT(DISTINCT "name")
FROM AACT.SPONSORS

UNION ALL

SELECT
    'RESPONSIBLE_PARTIES',
    COUNT(*),
    COUNT(DISTINCT "nct_id"),
    COUNT(DISTINCT "name")
FROM AACT.RESPONSIBLE_PARTIES

UNION ALL

SELECT
    'OVERALL_OFFICIALS',
    COUNT(*),
    COUNT(DISTINCT "nct_id"),
    COUNT(DISTINCT "name")
FROM AACT.OVERALL_OFFICIALS;


-- Query 20
-- Compare AI-suggested transaction/event candidates.
SELECT
    'MILESTONES' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT "nct_id") AS distinct_studies
FROM AACT.MILESTONES

UNION ALL

SELECT
    'DROP_WITHDRAWALS',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.DROP_WITHDRAWALS

UNION ALL

SELECT
    'REPORTED_EVENTS',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.REPORTED_EVENTS

UNION ALL

SELECT
    'SEARCH_RESULTS',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.SEARCH_RESULTS

UNION ALL

SELECT
    'SEARCH_TERM_RESULTS',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.SEARCH_TERM_RESULTS;


-- Query 21
-- Profile PENDING_RESULTS to determine whether it represents operational
-- events occurring on dates.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT "nct_id") AS distinct_studies,
    COUNT("event_date") AS rows_with_event_date,
    COUNT(DISTINCT "event") AS distinct_event_types
FROM AACT.PENDING_RESULTS;


-- Query 22
-- Count each event type found in PENDING_RESULTS.
SELECT
    "event",
    COUNT(*) AS row_count
FROM AACT.PENDING_RESULTS
GROUP BY "event"
ORDER BY row_count DESC;


-- Query 23
-- Inspect sample PENDING_RESULTS events and their dates.
SELECT
    "nct_id",
    "event",
    "event_date_description",
    "event_date"
FROM AACT.PENDING_RESULTS
WHERE ROWNUM <= 20;


-- =============================================================================
-- 5. [TASK 1 | LOOKUP CANDIDATE VALIDATION]
-- =============================================================================

-- Query 24
-- Compare the sizes of the candidate lookup tables.
SELECT
    'MESH_TERMS' AS table_name,
    COUNT(*) AS total_rows
FROM AACT.MESH_TERMS

UNION ALL

SELECT
    'MESH_HEADINGS',
    COUNT(*)
FROM AACT.MESH_HEADINGS

UNION ALL

SELECT
    'COUNTRIES',
    COUNT(*)
FROM AACT.COUNTRIES

UNION ALL

SELECT
    'IPD_INFORMATION_TYPES',
    COUNT(*)
FROM AACT.IPD_INFORMATION_TYPES;


-- Query 25
-- Test whether COUNTRIES behaves as a small independent lookup or as
-- study-specific data.
SELECT
    COUNT(*) AS countries_rows,
    COUNT(DISTINCT "nct_id") AS countries_studies,
    COUNT(DISTINCT "name") AS distinct_country_names
FROM AACT.COUNTRIES;


-- Query 26
-- Test whether IPD_INFORMATION_TYPES behaves as a lookup or study-linked table.
SELECT
    COUNT(*) AS ipd_rows,
    COUNT(DISTINCT "nct_id") AS ipd_studies,
    COUNT(DISTINCT "name") AS distinct_ipd_names
FROM AACT.IPD_INFORMATION_TYPES;


-- =============================================================================
-- 6. [TASK 1 | TIME-SERIES & OUTCOME INVESTIGATION]
-- =============================================================================

-- Query 27
-- Check whether OUTCOMES contains time-frame information that could indicate
-- repeated measurements over time.
SELECT
    COUNT(*) AS outcome_rows,
    COUNT(DISTINCT "time_frame") AS distinct_time_frames,
    COUNT("time_frame") AS non_null_time_frames
FROM AACT.OUTCOMES;


-- Query 28
-- Inspect the most common outcome time-frame descriptions.
SELECT
    "time_frame",
    COUNT(*) AS row_count
FROM AACT.OUTCOMES
WHERE "time_frame" IS NOT NULL
GROUP BY "time_frame"
ORDER BY row_count DESC
FETCH FIRST 20 ROWS ONLY;


-- Query 29
-- Profile OUTCOME_MEASUREMENTS and the number of distinct outcome identifiers.
SELECT
    COUNT(*) AS total_measurements,
    COUNT(DISTINCT "outcome_id") AS distinct_outcomes
FROM AACT.OUTCOME_MEASUREMENTS;


-- Query 30
-- Count study/outcome-title combinations appearing at multiple time frames.
SELECT
    COUNT(*) AS repeated_measure_sets
FROM (
    SELECT
        "nct_id",
        DBMS_LOB.SUBSTR("title", 4000, 1) AS outcome_title
    FROM AACT.OUTCOMES
    WHERE "title" IS NOT NULL
      AND "time_frame" IS NOT NULL
    GROUP BY
        "nct_id",
        DBMS_LOB.SUBSTR("title", 4000, 1)
    HAVING COUNT(DISTINCT "time_frame") > 1
);


-- Query 31
-- Inspect examples of outcomes repeated across the greatest number of
-- different time frames.
SELECT *
FROM (
    SELECT
        "nct_id",
        DBMS_LOB.SUBSTR("title", 4000, 1) AS outcome_title,
        COUNT(DISTINCT "time_frame") AS time_frame_count
    FROM AACT.OUTCOMES
    WHERE "title" IS NOT NULL
      AND "time_frame" IS NOT NULL
    GROUP BY
        "nct_id",
        DBMS_LOB.SUBSTR("title", 4000, 1)
    HAVING COUNT(DISTINCT "time_frame") > 1
    ORDER BY time_frame_count DESC
)
WHERE ROWNUM <= 20;


-- Query 32
-- Test the assumed relationship:
-- OUTCOME_MEASUREMENTS.outcome_id -> OUTCOMES.id.
SELECT
    COUNT(*) AS total_measurement_rows,
    COUNT(o."id") AS matched_outcome_rows,
    COUNT(
        CASE
            WHEN o."time_frame" IS NOT NULL THEN 1
        END
    ) AS matched_with_time_frame
FROM AACT.OUTCOME_MEASUREMENTS om
LEFT JOIN AACT.OUTCOMES o
    ON om."outcome_id" = o."id";


-- Query 33
-- Count measurement rows whose outcome_id has no matching OUTCOMES.id.
SELECT
    COUNT(*) AS orphan_measurements
FROM AACT.OUTCOME_MEASUREMENTS om
LEFT JOIN AACT.OUTCOMES o
    ON om."outcome_id" = o."id"
WHERE om."outcome_id" IS NOT NULL
  AND o."id" IS NULL;


-- Query 34
-- Test whether measurements can reach OUTCOMES indirectly through
-- RESULT_GROUPS.
SELECT
    COUNT(*) AS total_measurements,
    COUNT(rg."id") AS matched_result_groups,
    COUNT(o."id") AS matched_outcomes_via_group,
    COUNT(
        CASE
            WHEN o."time_frame" IS NOT NULL THEN 1
        END
    ) AS matched_with_time_frame
FROM AACT.OUTCOME_MEASUREMENTS om
LEFT JOIN AACT.RESULT_GROUPS rg
    ON om."result_group_id" = rg."id"
LEFT JOIN AACT.OUTCOMES o
    ON rg."outcome_id" = o."id";


-- Query 35
-- Inspect sample rows from the attempted indirect outcome relationship.
SELECT *
FROM (
    SELECT
        om."nct_id",
        om."outcome_id" AS measurement_outcome_id,
        om."result_group_id",
        rg."outcome_id" AS result_group_outcome_id,
        DBMS_LOB.SUBSTR(o."title", 200, 1) AS outcome_title,
        o."time_frame"
    FROM AACT.OUTCOME_MEASUREMENTS om
    LEFT JOIN AACT.RESULT_GROUPS rg
        ON om."result_group_id" = rg."id"
    LEFT JOIN AACT.OUTCOMES o
        ON rg."outcome_id" = o."id"
    WHERE o."id" IS NOT NULL
)
WHERE ROWNUM <= 20;


-- Query 36
-- Verify whether OUTCOME_MEASUREMENTS.outcome_id and the corresponding
-- RESULT_GROUPS.outcome_id contain the same values.
SELECT
    COUNT(*) AS matched_result_group_rows,

    SUM(
        CASE
            WHEN om."outcome_id" = rg."outcome_id" THEN 1
            ELSE 0
        END
    ) AS same_outcome_id,

    SUM(
        CASE
            WHEN om."outcome_id" <> rg."outcome_id" THEN 1
            ELSE 0
        END
    ) AS different_outcome_id,

    SUM(
        CASE
            WHEN om."outcome_id" IS NULL THEN 1
            ELSE 0
        END
    ) AS measurement_null_outcome_id,

    SUM(
        CASE
            WHEN rg."outcome_id" IS NULL THEN 1
            ELSE 0
        END
    ) AS group_null_outcome_id

FROM AACT.OUTCOME_MEASUREMENTS om
JOIN AACT.RESULT_GROUPS rg
    ON om."result_group_id" = rg."id";


-- Query 37
-- Inspect sample measurement and result-group outcome identifiers.
SELECT *
FROM (
    SELECT
        om."nct_id",
        om."outcome_id" AS measurement_outcome_id,
        om."result_group_id",
        rg."outcome_id" AS group_outcome_id,
        rg."ctgov_group_code",
        rg."result_type"
    FROM AACT.OUTCOME_MEASUREMENTS om
    JOIN AACT.RESULT_GROUPS rg
        ON om."result_group_id" = rg."id"
)
WHERE ROWNUM <= 20;


-- =============================================================================
-- 7. [TASK 1 | VERSIONING INVESTIGATION]
-- =============================================================================

-- Query 38
-- Profile RETRACTIONS to determine whether it represents historical versions
-- or a different type of record.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT "nct_id") AS distinct_studies,
    COUNT(DISTINCT "reference_id") AS distinct_references
FROM AACT.RETRACTIONS;


-- Query 39
-- Search the entire AACT schema for columns that suggest version,
-- amendment, history or revision tracking.
SELECT
    table_name,
    column_name
FROM all_tab_columns
WHERE owner = 'AACT'
  AND (
       LOWER(column_name) LIKE '%version%'
    OR LOWER(column_name) LIKE '%amend%'
    OR LOWER(column_name) LIKE '%history%'
    OR LOWER(column_name) LIKE '%revision%'
  )
ORDER BY table_name, column_id;


-- =============================================================================
-- 8. [TASK 1 | PARTITIONED TABLE VALIDATION]
-- =============================================================================

-- Query 40
-- Compare candidate vertical-partition tables by rows and study coverage.
SELECT
    'BRIEF_SUMMARIES' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT "nct_id") AS distinct_studies
FROM AACT.BRIEF_SUMMARIES

UNION ALL

SELECT
    'DETAILED_DESCRIPTIONS',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.DETAILED_DESCRIPTIONS

UNION ALL

SELECT
    'CALCULATED_VALUES',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.CALCULATED_VALUES;


-- Query 41
-- Test whether each candidate has more than one row for the same study.
SELECT
    'BRIEF_SUMMARIES' AS table_name,
    COUNT(*) AS duplicate_nct_ids
FROM (
    SELECT "nct_id"
    FROM AACT.BRIEF_SUMMARIES
    GROUP BY "nct_id"
    HAVING COUNT(*) > 1
)

UNION ALL

SELECT
    'DETAILED_DESCRIPTIONS',
    COUNT(*)
FROM (
    SELECT "nct_id"
    FROM AACT.DETAILED_DESCRIPTIONS
    GROUP BY "nct_id"
    HAVING COUNT(*) > 1
)

UNION ALL

SELECT
    'CALCULATED_VALUES',
    COUNT(*)
FROM (
    SELECT "nct_id"
    FROM AACT.CALCULATED_VALUES
    GROUP BY "nct_id"
    HAVING COUNT(*) > 1
);


-- =============================================================================
-- 9. [TASK 1 | TEMPORARY AGGREGATE VALIDATION]
-- =============================================================================

-- Query 42
-- Compare candidate precomputed aggregate/reporting tables.
SELECT
    'REPORTED_EVENT_TOTALS' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT "nct_id") AS distinct_studies
FROM AACT.REPORTED_EVENT_TOTALS

UNION ALL

SELECT
    'OUTCOME_COUNTS',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.OUTCOME_COUNTS

UNION ALL

SELECT
    'BASELINE_COUNTS',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.BASELINE_COUNTS

UNION ALL

SELECT
    'CALCULATED_VALUES',
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.CALCULATED_VALUES;


-- Query 43
-- Inspect the aggregation scope stored in OUTCOME_COUNTS.
SELECT
    "scope",
    COUNT(*) AS row_count
FROM AACT.OUTCOME_COUNTS
GROUP BY "scope"
ORDER BY row_count DESC;


-- Query 44
-- Inspect the aggregation scope stored in BASELINE_COUNTS.
SELECT
    "scope",
    COUNT(*) AS row_count
FROM AACT.BASELINE_COUNTS
GROUP BY "scope"
ORDER BY row_count DESC;


-- Query 45
-- Inspect categories represented in REPORTED_EVENT_TOTALS.
SELECT
    "event_type",
    "classification",
    COUNT(*) AS row_count
FROM AACT.REPORTED_EVENT_TOTALS
GROUP BY
    "event_type",
    "classification"
ORDER BY row_count DESC;


-- =============================================================================
-- 10. [TASK 2 | OUTCOME & RESULTS RELATIONSHIP VALIDATION]
-- =============================================================================

-- Query 46
-- Test whether OUTCOME_MEASUREMENTS.outcome_id references DESIGN_OUTCOMES.id.
SELECT
    COUNT(*) AS total_measurements,
    COUNT(do_."id") AS matched_design_outcomes,
    SUM(
        CASE
            WHEN do_."nct_id" = om."nct_id" THEN 1
            ELSE 0
        END
    ) AS matching_nct_id
FROM AACT.OUTCOME_MEASUREMENTS om
LEFT JOIN AACT.DESIGN_OUTCOMES do_
    ON om."outcome_id" = do_."id";


-- Query 47
-- Count outcome_id values from OUTCOME_MEASUREMENTS that do not match
-- DESIGN_OUTCOMES.id.
SELECT
    COUNT(*) AS orphan_measurements
FROM AACT.OUTCOME_MEASUREMENTS om
LEFT JOIN AACT.DESIGN_OUTCOMES do_
    ON om."outcome_id" = do_."id"
WHERE om."outcome_id" IS NOT NULL
  AND do_."id" IS NULL;


-- Query 48
-- Compare the number of distinct outcome identifiers stored across
-- different result-side tables.
SELECT
    'RESULT_GROUPS' AS table_name,
    COUNT(DISTINCT "outcome_id") AS distinct_outcome_ids
FROM AACT.RESULT_GROUPS
WHERE "outcome_id" IS NOT NULL

UNION ALL

SELECT
    'OUTCOME_MEASUREMENTS',
    COUNT(DISTINCT "outcome_id")
FROM AACT.OUTCOME_MEASUREMENTS
WHERE "outcome_id" IS NOT NULL

UNION ALL

SELECT
    'OUTCOME_COUNTS',
    COUNT(DISTINCT "outcome_id")
FROM AACT.OUTCOME_COUNTS
WHERE "outcome_id" IS NOT NULL

UNION ALL

SELECT
    'OUTCOME_ANALYSES',
    COUNT(DISTINCT "outcome_id")
FROM AACT.OUTCOME_ANALYSES
WHERE "outcome_id" IS NOT NULL;


-- Query 49
-- Test whether measurement outcome IDs overlap with the identifiers used by
-- OUTCOME_COUNTS or OUTCOME_ANALYSES.
SELECT
    COUNT(DISTINCT om."outcome_id") AS measurement_ids,

    COUNT(
        DISTINCT CASE
            WHEN oc."outcome_id" IS NOT NULL
            THEN om."outcome_id"
        END
    ) AS also_in_outcome_counts,

    COUNT(
        DISTINCT CASE
            WHEN oa."outcome_id" IS NOT NULL
            THEN om."outcome_id"
        END
    ) AS also_in_outcome_analyses

FROM AACT.OUTCOME_MEASUREMENTS om

LEFT JOIN AACT.OUTCOME_COUNTS oc
    ON om."outcome_id" = oc."outcome_id"

LEFT JOIN AACT.OUTCOME_ANALYSES oa
    ON om."outcome_id" = oa."outcome_id";


-- Query 50
-- Compare the numeric ranges of outcome identifiers across related tables.
-- Different ID ranges can reveal separate identifier domains.
SELECT
    'RESULT_GROUPS' AS table_name,
    MIN("outcome_id") AS min_outcome_id,
    MAX("outcome_id") AS max_outcome_id,
    COUNT(DISTINCT "outcome_id") AS distinct_ids
FROM AACT.RESULT_GROUPS
WHERE "outcome_id" IS NOT NULL

UNION ALL

SELECT
    'OUTCOME_MEASUREMENTS',
    MIN("outcome_id"),
    MAX("outcome_id"),
    COUNT(DISTINCT "outcome_id")
FROM AACT.OUTCOME_MEASUREMENTS
WHERE "outcome_id" IS NOT NULL

UNION ALL

SELECT
    'OUTCOME_COUNTS',
    MIN("outcome_id"),
    MAX("outcome_id"),
    COUNT(DISTINCT "outcome_id")
FROM AACT.OUTCOME_COUNTS
WHERE "outcome_id" IS NOT NULL

UNION ALL

SELECT
    'OUTCOME_ANALYSES',
    MIN("outcome_id"),
    MAX("outcome_id"),
    COUNT(DISTINCT "outcome_id")
FROM AACT.OUTCOME_ANALYSES
WHERE "outcome_id" IS NOT NULL

UNION ALL

SELECT
    'OUTCOMES',
    MIN("id"),
    MAX("id"),
    COUNT(DISTINCT "id")
FROM AACT.OUTCOMES

UNION ALL

SELECT
    'DESIGN_OUTCOMES',
    MIN("id"),
    MAX("id"),
    COUNT(DISTINCT "id")
FROM AACT.DESIGN_OUTCOMES;


-- Query 51
-- Validate the relationship from OUTCOME_COUNTS and OUTCOME_ANALYSES
-- to OUTCOMES.id.
SELECT
    'OUTCOME_COUNTS' AS child_table,
    COUNT(*) AS total_rows,
    COUNT(o."id") AS matched_rows
FROM AACT.OUTCOME_COUNTS oc
LEFT JOIN AACT.OUTCOMES o
    ON oc."outcome_id" = o."id"

UNION ALL

SELECT
    'OUTCOME_ANALYSES',
    COUNT(*),
    COUNT(o."id")
FROM AACT.OUTCOME_ANALYSES oa
LEFT JOIN AACT.OUTCOMES o
    ON oa."outcome_id" = o."id";


-- Query 52
-- Explicitly count orphan outcome IDs in OUTCOME_COUNTS and
-- OUTCOME_ANALYSES.
SELECT
    'OUTCOME_COUNTS' AS child_table,
    COUNT(*) AS orphan_rows
FROM AACT.OUTCOME_COUNTS oc
LEFT JOIN AACT.OUTCOMES o
    ON oc."outcome_id" = o."id"
WHERE oc."outcome_id" IS NOT NULL
  AND o."id" IS NULL

UNION ALL

SELECT
    'OUTCOME_ANALYSES',
    COUNT(*)
FROM AACT.OUTCOME_ANALYSES oa
LEFT JOIN AACT.OUTCOMES o
    ON oa."outcome_id" = o."id"
WHERE oa."outcome_id" IS NOT NULL
  AND o."id" IS NULL;


-- Query 53
-- Validate the REPORTED_EVENTS logical relationship using study ID and
-- ClinicalTrials.gov group code rather than the unreliable numeric
-- result_group_id.
SELECT
    COUNT(*) AS total_reported_events,
    COUNT(rg."id") AS matched_by_study_and_group,
    COUNT(*) - COUNT(rg."id") AS unmatched_rows
FROM AACT.REPORTED_EVENTS re
LEFT JOIN AACT.RESULT_GROUPS rg
    ON re."nct_id" = rg."nct_id"
   AND re."ctgov_group_code" = rg."ctgov_group_code"
   AND rg."result_type" = 'Reported Event';


-- Query 54
-- Confirm that Reported Event result groups are unique for each
-- nct_id + ctgov_group_code pair.
SELECT
    COUNT(*) AS duplicate_reported_event_groups
FROM (
    SELECT
        "nct_id",
        "ctgov_group_code"
    FROM AACT.RESULT_GROUPS
    WHERE "result_type" = 'Reported Event'
    GROUP BY
        "nct_id",
        "ctgov_group_code"
    HAVING COUNT(*) > 1
);


-- Query 55
-- Compare planned protocol outcomes with reported results outcomes.
SELECT
    'DESIGN_OUTCOMES' AS table_name,
    "outcome_type",
    COUNT(*) AS row_count,
    COUNT(DISTINCT "nct_id") AS distinct_studies
FROM AACT.DESIGN_OUTCOMES
GROUP BY "outcome_type"

UNION ALL

SELECT
    'OUTCOMES',
    "outcome_type",
    COUNT(*),
    COUNT(DISTINCT "nct_id")
FROM AACT.OUTCOMES
GROUP BY "outcome_type"

ORDER BY table_name, "outcome_type";


-- =============================================================================
-- 11. FINAL BASELINE ERD VALIDATION
-- =============================================================================

-- Query 56
-- Verify that selected protocol/results tables link to valid STUDIES records.
SELECT
    'OUTCOME_MEASUREMENTS' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(s."nct_id") AS matched_to_studies,
    COUNT(*) - COUNT(s."nct_id") AS unmatched_rows
FROM AACT.OUTCOME_MEASUREMENTS om
LEFT JOIN AACT.STUDIES s
    ON om."nct_id" = s."nct_id"

UNION ALL

SELECT
    'REPORTED_EVENTS',
    COUNT(*),
    COUNT(s."nct_id"),
    COUNT(*) - COUNT(s."nct_id")
FROM AACT.REPORTED_EVENTS re
LEFT JOIN AACT.STUDIES s
    ON re."nct_id" = s."nct_id"

UNION ALL

SELECT
    'DESIGN_OUTCOMES',
    COUNT(*),
    COUNT(s."nct_id"),
    COUNT(*) - COUNT(s."nct_id")
FROM AACT.DESIGN_OUTCOMES d
LEFT JOIN AACT.STUDIES s
    ON d."nct_id" = s."nct_id";


-- Query 57
-- Test whether id behaves as a unique logical identifier in the selected
-- baseline tables.
SELECT
    'ELIGIBILITIES' AS table_name,
    COUNT(*) AS total_rows,
    COUNT("id") AS non_null_ids,
    COUNT(DISTINCT "id") AS distinct_ids
FROM AACT.ELIGIBILITIES

UNION ALL

SELECT
    'DESIGNS',
    COUNT(*),
    COUNT("id"),
    COUNT(DISTINCT "id")
FROM AACT.DESIGNS

UNION ALL

SELECT
    'CONDITIONS',
    COUNT(*),
    COUNT("id"),
    COUNT(DISTINCT "id")
FROM AACT.CONDITIONS

UNION ALL

SELECT
    'INTERVENTIONS',
    COUNT(*),
    COUNT("id"),
    COUNT(DISTINCT "id")
FROM AACT.INTERVENTIONS

UNION ALL

SELECT
    'SPONSORS',
    COUNT(*),
    COUNT("id"),
    COUNT(DISTINCT "id")
FROM AACT.SPONSORS

UNION ALL

SELECT
    'FACILITIES',
    COUNT(*),
    COUNT("id"),
    COUNT(DISTINCT "id")
FROM AACT.FACILITIES

UNION ALL

SELECT
    'DESIGN_OUTCOMES',
    COUNT(*),
    COUNT("id"),
    COUNT(DISTINCT "id")
FROM AACT.DESIGN_OUTCOMES

UNION ALL

SELECT
    'OUTCOMES',
    COUNT(*),
    COUNT("id"),
    COUNT(DISTINCT "id")
FROM AACT.OUTCOMES

UNION ALL

SELECT
    'RESULT_GROUPS',
    COUNT(*),
    COUNT("id"),
    COUNT(DISTINCT "id")
FROM AACT.RESULT_GROUPS

UNION ALL

SELECT
    'OUTCOME_MEASUREMENTS',
    COUNT(*),
    COUNT("id"),
    COUNT(DISTINCT "id")
FROM AACT.OUTCOME_MEASUREMENTS

UNION ALL

SELECT
    'REPORTED_EVENTS',
    COUNT(*),
    COUNT("id"),
    COUNT(DISTINCT "id")
FROM AACT.REPORTED_EVENTS;


-- Query 58
-- Count groups of duplicated DESIGNS.id values.
SELECT
    COUNT(*) AS duplicate_id_groups
FROM (
    SELECT
        "id"
    FROM AACT.DESIGNS
    GROUP BY "id"
    HAVING COUNT(*) > 1
);


-- Query 59
-- Check whether DESIGNS duplicates remain even when both id and nct_id
-- are considered together.
SELECT
    COUNT(*) AS duplicate_id_nct_pairs
FROM (
    SELECT
        "id",
        "nct_id"
    FROM AACT.DESIGNS
    GROUP BY
        "id",
        "nct_id"
    HAVING COUNT(*) > 1
);


-- Query 60
-- Validate DESIGN_GROUPS.id uniqueness and measure study coverage.
SELECT
    COUNT(*) AS total_rows,
    COUNT("id") AS non_null_ids,
    COUNT(DISTINCT "id") AS distinct_ids,
    COUNT(DISTINCT "nct_id") AS distinct_studies
FROM AACT.DESIGN_GROUPS;