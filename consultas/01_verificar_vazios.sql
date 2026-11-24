SELECT SUM(CASE WHEN thal IS NULL THEN 1 ELSE 0 END) AS null_verdadeiro,
       SUM(CASE WHEN thal = '' THEN 1 ELSE 0 END) AS string_vazia,
       SUM(CASE WHEN TRIM(thal) = '' AND thal <> '' THEN 1 ELSE 0 END) AS so_espacos
FROM heart;
