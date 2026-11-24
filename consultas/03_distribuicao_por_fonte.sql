SELECT dataset, COUNT(*) AS total,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM heart), 1) AS percentual
FROM heart
GROUP BY dataset
ORDER BY total DESC;
