SELECT id, age, thalch, dataset,
       CAST(thalch AS REAL) - (220 - CAST(age AS REAL)) AS excedente
FROM heart
WHERE CAST(thalch AS REAL) > (220 - CAST(age AS REAL))
ORDER BY excedente DESC
LIMIT 20;
