SELECT 'colesterol = 0' AS inconsistencia, dataset, COUNT(*) AS total
FROM heart WHERE CAST(chol AS REAL) = 0 GROUP BY dataset
UNION ALL
SELECT 'pressao = 0', dataset, COUNT(*)
FROM heart WHERE CAST(trestbps AS REAL) = 0 GROUP BY dataset
UNION ALL
SELECT 'fc_max = 0', dataset, COUNT(*)
FROM heart WHERE CAST(thalch AS REAL) = 0 GROUP BY dataset;
