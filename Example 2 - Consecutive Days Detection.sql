/*
Method 1: Using LAG and CASE Statements

This method involves calculating the difference in days between each installation date for the same installer, 
marking the start of new sequences, and then grouping these sequences to identify periods of at least four consecutive days.
*/

WITH DateDiffs AS (
    SELECT
        installer_id,
        install_date,
        install_date - LAG(install_date) OVER (PARTITION BY installer_id ORDER BY install_date) AS diff
    FROM
        installs
),
MarkStart AS (
    SELECT
        installer_id,
        install_date,
        CASE WHEN diff = 1 THEN 0 ELSE 1 END AS isNewStart
    FROM DateDiffs
),
CumulativeSum AS (
    SELECT
        installer_id,
        install_date,
        SUM(isNewStart) OVER (PARTITION BY installer_id ORDER BY install_date) AS grp
    FROM MarkStart
),
Grouped AS (
    SELECT
        installer_id,
        MIN(install_date) AS start_date,
        MAX(install_date) AS end_date,
        COUNT(*) AS duration,
        grp
    FROM CumulativeSum
    GROUP BY installer_id, grp
    HAVING COUNT(*) >= 4
)
SELECT installer_id, start_date, end_date FROM Grouped ORDER BY installer_id, start_date;



/*Method 2: Identifying New Sequences with CASE Statement

This method refines the identification of new sequences by directly using the difference between installation dates. 
It then groups these by a cumulative sum acting as a sequence identifier to find sequences of four or more consecutive days.
*/

WITH InstallationDiffs AS (
    SELECT
        installer_id,
        install_date,
        install_date - LAG(install_date) OVER (PARTITION BY installer_id ORDER BY install_date) AS diff,
        CASE 
            WHEN install_date - LAG(install_date) OVER (PARTITION BY installer_id ORDER BY install_date) = 1 THEN 0
            ELSE 1
        END AS isNewSequence
    FROM
        installs
),
CumulativeSequences AS (
    SELECT
        installer_id,
        install_date,
        SUM(isNewSequence) OVER (PARTITION BY installer_id ORDER BY install_date) AS sequence_id
    FROM InstallationDiffs
),
GroupedSequences AS (
    SELECT
        installer_id,
        sequence_id,
        COUNT(*) AS sequence_length,
        MIN(install_date) AS sequence_start,
        MAX(install_date) AS sequence_end
    FROM CumulativeSequences
    GROUP BY installer_id, sequence_id
),
FilteredSequences AS (
    SELECT
        installer_id,
        sequence_start AS consecutive_start,
        sequence_end AS consecutive_end
    FROM GroupedSequences
    WHERE sequence_length >= 4
)
SELECT * FROM FilteredSequences ORDER BY installer_id, consecutive_start;

/* Method 3: Using ROW_NUMBER() to Find Consecutive Pairs

This method utilizes the ROW_NUMBER() window function to assign a unique number to each installation date within each installer. 
It then finds consecutive pairs that span four days.
*/

WITH RankedInstallations AS (
    SELECT
        installer_id,
        install_date,
        ROW_NUMBER() OVER (PARTITION BY installer_id ORDER BY install_date) AS rn
    FROM
        installs
),
ConsecutivePairs AS (
    SELECT
        a.installer_id,
        a.install_date AS start_date,
        b.install_date AS end_date,
        b.rn - a.rn AS diff
    FROM
        RankedInstallations a
    JOIN
        RankedInstallations b ON a.installer_id = b.installer_id AND a.rn = b.rn - 3
)
SELECT
    installer_id,
    start_date,
    end_date
FROM
    ConsecutivePairs
WHERE
    end_date - start_date = 3
ORDER BY
    installer_id, start_date;

/* Method 4: RECURSIVE CTE for Finding Consecutive Days

This method employs a recursive CTE to iteratively build sequences of consecutive installation dates, 
starting from dates with no previous installation the day before. It filters for sequences of at least four days.
*/
WITH RECURSIVE DateSeq AS (
    SELECT 
        installer_id, 
        install_date AS consecutive_start, 
        install_date AS consecutive_end,
        1 AS days_count
    FROM installs
    WHERE NOT EXISTS (
        SELECT 1
        FROM installs i2
        WHERE i2.installer_id = installs.installer_id
          AND i2.install_date = installs.install_date - INTERVAL '1 day'
    )
    UNION ALL
    SELECT 
        ds.installer_id, 
        ds.consecutive_start, 
        i.install_date AS consecutive_end,
        ds.days_count + 1
    FROM DateSeq ds
    JOIN installs i ON ds.installer_id = i.installer_id 
                   AND i.install_date = ds.consecutive_end + INTERVAL '1 day'
)
SELECT DISTINCT installer_id, consecutive_start, consecutive_end, days_count
FROM DateSeq
WHERE days_count >= 4
ORDER BY installer_id, consecutive_start;
```
