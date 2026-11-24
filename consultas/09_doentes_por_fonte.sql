SELECT dataset,
       SUM(CASE WHEN num = '0' THEN 1 ELSE 0 END) AS sem_doenca,
       SUM(CASE WHEN num IN ('1','2','3','4') THEN 1 ELSE 0 END) AS com_doenca,
       COUNT(*) AS total
FROM heart
GROUP BY dataset
ORDER BY total DESC;
