SELECT id, age, oldpeak, dataset
FROM heart
WHERE CAST(oldpeak AS REAL) < 0
ORDER BY CAST(oldpeak AS REAL) ASC;
