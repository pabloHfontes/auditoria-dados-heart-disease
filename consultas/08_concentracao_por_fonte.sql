SELECT dataset,
       COUNT(*) AS total,
       ROUND(SUM(CASE WHEN CAST(chol AS REAL) = 0 THEN 1.0 ELSE 0 END) * 100 / COUNT(*), 1) AS pct_chol_zero,
       ROUND(SUM(CASE WHEN CAST(oldpeak AS REAL) < 0 THEN 1.0 ELSE 0 END) * 100 / COUNT(*), 1) AS pct_oldpeak_neg,
       ROUND(SUM(CASE WHEN ca IS NULL THEN 1.0 ELSE 0 END) * 100 / COUNT(*), 1) AS pct_ca_nulo,
       ROUND(SUM(CASE WHEN thal IS NULL THEN 1.0 ELSE 0 END) * 100 / COUNT(*), 1) AS pct_thal_nulo,
       ROUND(SUM(CASE WHEN trestbps IS NULL THEN 1.0 ELSE 0 END) * 100 / COUNT(*), 1) AS pct_pressao_nula
FROM heart
GROUP BY dataset
ORDER BY pct_chol_zero DESC;
