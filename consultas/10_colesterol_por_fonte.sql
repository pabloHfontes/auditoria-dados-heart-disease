SELECT dataset,
       MIN(CAST(chol AS REAL)) AS colesterol_min,
       ROUND(AVG(CAST(chol AS REAL)), 1) AS colesterol_media,
       MAX(CAST(chol AS REAL)) AS colesterol_max
FROM heart
WHERE CAST(chol AS REAL) > 0
GROUP BY dataset;
