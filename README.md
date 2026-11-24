# Auditoria de Qualidade de Dados - Heart Disease UCI

## Sobre o projeto

Esse projeto é uma auditoria de qualidade de dados feita sobre o dataset público Heart Disease, do repositório UCI. O arquivo tem 920 registros de quatro instituições diferentes (Cleveland, Hungary, VA Long Beach e Switzerland). A ideia foi simular o que uma área de auditoria contínua faz: antes de tirar qualquer conclusão sobre risco, é preciso saber se os dados são confiáveis, se têm valores impossíveis e se as fontes são comparáveis entre si.

Usei SQLite (pelo DB Browser for SQLite) e SQL puro. Importei o CSV com todas as colunas como TEXT e fui fazendo CAST quando precisava comparar número, porque assim eu primeiro enxergo o dado como ele veio antes de tipar.

## Metodologia

Fiz três etapas:

1. Perfilamento de completude (quantos nulos por coluna)
2. Detecção de valores clinicamente impossíveis (zero onde não pode ser zero, negativo onde não pode ser negativo)
3. Cruzamento por fonte de origem, para ver se algum problema estava concentrado em um dataset específico

Todos os comandos estão na pasta `consultas/`, na ordem numérica. O resultado de cada um está documentado logo abaixo.

## Anotações e resultados por comando

### Primeiro comando: como os vazios foram importados

```sql
SELECT SUM(CASE WHEN thal IS NULL THEN 1 ELSE 0 END) AS null_verdadeiro,
       SUM(CASE WHEN thal = '' THEN 1 ELSE 0 END) AS string_vazia,
       SUM(CASE WHEN TRIM(thal) = '' AND thal <> '' THEN 1 ELSE 0 END) AS so_espacos
FROM heart;
```

Antes de procurar vazios nas outras colunas, precisei saber como o DB Browser tinha gravado os campos em branco. O comando usa SUM (soma), CASE (caso), WHEN (quando), IS NULL (está vazio), THEN (então), END (fim) e AS (como) para dar nome à variável que guarda o resultado. O TRIM() remove espaços do início e do fim, caso alguém tenha digitado um espaço por engano no lugar do vazio.

Resultado: null_verdadeiro = 486, string_vazia = 0, so_espacos = 0. Ou seja, tudo que estava em branco virou NULL de verdade. Isso simplifica os próximos comandos, porque não preciso testar `= ''` nem `TRIM()` em cada coluna.

### Segundo comando: completude por coluna

```sql
SELECT 'idade' AS coluna, SUM(CASE WHEN age IS NULL OR age = '' THEN 1 ELSE 0 END) AS faltantes FROM heart
UNION ALL SELECT 'sexo', SUM(CASE WHEN sex IS NULL OR sex = '' THEN 1 ELSE 0 END) FROM heart
UNION ALL SELECT 'tipo_dor', SUM(CASE WHEN cp IS NULL OR cp = '' THEN 1 ELSE 0 END) FROM heart
UNION ALL SELECT 'pressao', SUM(CASE WHEN trestbps IS NULL OR trestbps = '' THEN 1 ELSE 0 END) FROM heart
UNION ALL SELECT 'colesterol', SUM(CASE WHEN chol IS NULL OR chol = '' THEN 1 ELSE 0 END) FROM heart
UNION ALL SELECT 'acucar_jejum', SUM(CASE WHEN fbs IS NULL OR fbs = '' THEN 1 ELSE 0 END) FROM heart
UNION ALL SELECT 'ecg_repouso', SUM(CASE WHEN restecg IS NULL OR restecg = '' THEN 1 ELSE 0 END) FROM heart
UNION ALL SELECT 'fc_max', SUM(CASE WHEN thalch IS NULL OR thalch = '' THEN 1 ELSE 0 END) FROM heart
UNION ALL SELECT 'angina_exercicio', SUM(CASE WHEN exang IS NULL OR exang = '' THEN 1 ELSE 0 END) FROM heart
UNION ALL SELECT 'oldpeak', SUM(CASE WHEN oldpeak IS NULL OR oldpeak = '' THEN 1 ELSE 0 END) FROM heart
UNION ALL SELECT 'slope', SUM(CASE WHEN slope IS NULL OR slope = '' THEN 1 ELSE 0 END) FROM heart
UNION ALL SELECT 'ca', SUM(CASE WHEN ca IS NULL OR ca = '' THEN 1 ELSE 0 END) FROM heart
UNION ALL SELECT 'thal', SUM(CASE WHEN thal IS NULL OR thal = '' THEN 1 ELSE 0 END) FROM heart
UNION ALL SELECT 'num', SUM(CASE WHEN num IS NULL OR num = '' THEN 1 ELSE 0 END) FROM heart;
```

Aqui eu declaro a coluna e o campo "faltantes", e o UNION ALL combina as 14 contagens dentro desses dois campos. É consulta de visualização, não altera nada no banco.

| Coluna | Faltantes |
|---|---|
| idade | 0 |
| sexo | 0 |
| tipo_dor | 0 |
| pressao | 59 |
| colesterol | 30 |
| acucar_jejum | 90 |
| ecg_repouso | 2 |
| fc_max | 55 |
| angina_exercicio | 55 |
| oldpeak | 62 |
| slope | 309 |
| ca | 611 |
| thal | 486 |
| num | 0 |

Os campos `ca`, `thal` e `slope` chamam atenção de imediato. `ca` está nulo em 611 dos 920 registros (66,4%), `thal` em 486 (52,8%) e `slope` em 309 (33,6%). Qualquer análise de risco que dependa dessas variáveis vai perder mais da metade da base.

### Terceiro comando: distribuição por fonte

```sql
SELECT dataset, COUNT(*) AS total,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM heart), 1) AS percentual
FROM heart
GROUP BY dataset
ORDER BY total DESC;
```

Esse comando conta quantos registros cada instituição tem e qual a fatia dela no total. Também é só visualização.

| Dataset | Total | Percentual |
|---|---|---|
| Cleveland | 304 | 33,0 |
| Hungary | 293 | 31,8 |
| VA Long Beach | 200 | 21,7 |
| Switzerland | 123 | 13,4 |

### Quarto comando: zeros impossíveis

```sql
SELECT 'colesterol = 0' AS inconsistencia, dataset, COUNT(*) AS total
FROM heart WHERE CAST(chol AS REAL) = 0 GROUP BY dataset
UNION ALL
SELECT 'pressao = 0', dataset, COUNT(*)
FROM heart WHERE CAST(trestbps AS REAL) = 0 GROUP BY dataset
UNION ALL
SELECT 'fc_max = 0', dataset, COUNT(*)
FROM heart WHERE CAST(thalch AS REAL) = 0 GROUP BY dataset;
```

Estou procurando zero onde zero não pode existir: colesterol não pode ser zero em paciente vivo, pressão arterial zero é incompatível com vida, e frequência cardíaca máxima zero só aconteceria em óbito, não em exame ergométrico.

| Inconsistência | Dataset | Total |
|---|---|---|
| colesterol = 0 | Switzerland | 123 |
| colesterol = 0 | VA Long Beach | 49 |
| pressao = 0 | VA Long Beach | 1 |

Aqui já aparece o padrão principal: Switzerland tem 123 registros e todos os 123 estão com colesterol zero.

### Quinto comando: valores negativos em oldpeak

```sql
SELECT id, age, oldpeak, dataset
FROM heart
WHERE CAST(oldpeak AS REAL) < 0
ORDER BY CAST(oldpeak AS REAL) ASC;
```

Oldpeak mede a depressão do segmento ST, que é uma magnitude. Por definição não pode ser negativa. Valor negativo indica erro de sinal, de medição ou de digitação.

| ID | Idade | Oldpeak | Dataset |
|---|---|---|---|
| 616 | 46 | -2,6 | Switzerland |
| 654 | 56 | -2,0 | Switzerland |
| 610 | 42 | -1,5 | Switzerland |
| 604 | 38 | -1,1 | Switzerland |
| 656 | 56 | -1,0 | Switzerland |
| 657 | 56 | -1,0 | Switzerland |
| 697 | 63 | -0,9 | Switzerland |
| 692 | 62 | -0,8 | Switzerland |
| 630 | 51 | -0,7 | Switzerland |
| 695 | 62 | -0,5 | Switzerland |
| 726 | 66 | -0,5 | VA Long Beach |
| 615 | 45 | -0,1 | Switzerland |

São 12 no total, sendo 11 de Switzerland e 1 de VA Long Beach. O padrão continua apontando para a mesma fonte.

### Sexto comando: distribuição do diagnóstico

```sql
SELECT num, COUNT(*) AS total FROM heart GROUP BY num ORDER BY CAST(num AS INTEGER);
```

| Diagnóstico (num) | Total |
|---|---|
| 0 | 411 |
| 1 | 265 |
| 2 | 109 |
| 3 | 107 |
| 4 | 28 |

Nenhum valor fora do esperado (0 a 4). A distribuição é plausível, mas na consulta seguinte eu quebro por fonte e a coisa muda.

### Sétimo comando: FC máxima acima do previsto para a idade

```sql
SELECT id, age, thalch, dataset,
       CAST(thalch AS REAL) - (220 - CAST(age AS REAL)) AS excedente
FROM heart
WHERE CAST(thalch AS REAL) > (220 - CAST(age AS REAL))
ORDER BY excedente DESC
LIMIT 20;
```

A fórmula 220 menos a idade é uma aproximação da FC máxima teórica. Passar disso não é erro garantido (atleta pode passar), mas valores muito acima justificam investigação.

| ID | Idade | FC máx | Dataset | Excedente |
|---|---|---|---|---|
| 189 | 54 | 195 | Cleveland | 29,0 |
| 113 | 52 | 190 | Cleveland | 22,0 |
| 186 | 63 | 179 | Cleveland | 22,0 |
| 220 | 59 | 182 | Cleveland | 21,0 |
| 125 | 65 | 174 | Cleveland | 19,0 |
| 162 | 77 | 162 | Cleveland | 19,0 |
| 228 | 67 | 172 | Cleveland | 19,0 |
| 666 | 57 | 182 | Switzerland | 19,0 |
| 134 | 51 | 186 | Cleveland | 17,0 |
| 143 | 52 | 184 | Cleveland | 16,0 |
| 187 | 42 | 194 | Cleveland | 16,0 |
| 95 | 63 | 172 | Cleveland | 15,0 |
| 791 | 55 | 180 | VA Long Beach | 15,0 |
| 6 | 56 | 178 | Cleveland | 14,0 |
| 100 | 48 | 186 | Cleveland | 14,0 |
| 670 | 59 | 175 | Switzerland | 14,0 |
| 43 | 71 | 162 | Cleveland | 13,0 |
| 54 | 44 | 188 | Cleveland | 12,0 |
| 225 | 63 | 169 | Cleveland | 12,0 |
| 745 | 52 | 180 | VA Long Beach | 12,0 |

Esse foi o único achado em que Cleveland aparece com mais frequência que Switzerland. Mas ainda é a Suíça que chama atenção nos outros três problemas (colesterol zero, oldpeak negativo, ca nulo).

### Oitavo comando: concentração de problemas por fonte

```sql
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
```

Esse é o comando principal da auditoria. Em vez de olhar cada problema isolado, ele coloca as quatro fontes lado a lado e mostra o percentual de cada inconsistência dentro de cada fonte.

| Dataset | Total | % chol=0 | % oldpeak<0 | % ca nulo | % thal nulo | % pressão nula |
|---|---|---|---|---|---|---|
| Switzerland | 123 | 100,0 | 8,9 | 95,9 | 42,3 | 1,6 |
| VA Long Beach | 200 | 24,5 | 0,5 | 99,0 | 83,0 | 28,0 |
| Hungary | 293 | 0,0 | 0,0 | 99,0 | 90,4 | 0,3 |
| Cleveland | 304 | 0,0 | 0,0 | 1,6 | 1,0 | 0,0 |

A tabela conta a história. Switzerland tem colesterol zero em 100% dos registros. Se eu fizer uma média global de colesterol sem tratar isso, o resultado vai sair completamente errado. Cleveland não tem nenhum colesterol zero e nenhum oldpeak negativo, o que a coloca como a fonte mais confiável. VA Long Beach tem um problema intermediário, com 24,5% de zeros em colesterol.

### Nono comando: distribuição de doentes por fonte

```sql
SELECT dataset,
       SUM(CASE WHEN num = '0' THEN 1 ELSE 0 END) AS sem_doenca,
       SUM(CASE WHEN num IN ('1','2','3','4') THEN 1 ELSE 0 END) AS com_doenca,
       COUNT(*) AS total
FROM heart
GROUP BY dataset
ORDER BY total DESC;
```

| Dataset | Sem doença | Com doença | Total | % doentes |
|---|---|---|---|---|
| Cleveland | 165 | 139 | 304 | 45,7% |
| Hungary | 187 | 106 | 293 | 36,2% |
| VA Long Beach | 51 | 149 | 200 | 74,5% |
| Switzerland | 8 | 115 | 123 | 93,5% |

A Suíça tem 93,5% de pacientes doentes, contra 36,2% da Hungria. Essa diferença não é aleatória e reforça o que o oitavo comando já mostrava: as fontes não são amostras equivalentes, e qualquer análise agregada precisa levar isso em conta.

### Décimo comando: colesterol válido por fonte

```sql
SELECT dataset,
       MIN(CAST(chol AS REAL)) AS colesterol_min,
       ROUND(AVG(CAST(chol AS REAL)), 1) AS colesterol_media,
       MAX(CAST(chol AS REAL)) AS colesterol_max
FROM heart
WHERE CAST(chol AS REAL) > 0
GROUP BY dataset;
```

Esse comando filtra os zeros e olha só para os valores que podem ser colesterol de verdade.

| Dataset | Mínimo | Média | Máximo |
|---|---|---|---|
| Cleveland | 126,0 | 246,3 | 564,0 |
| Hungary | 85,0 | 251,3 | 603,0 |
| VA Long Beach | 100,0 | 239,6 | 458,0 |

Switzerland não aparece. Como todos os 123 registros têm colesterol zero, o filtro `> 0` elimina a fonte inteira. Isso confirma a hipótese: o zero não é medição real, é ausência de dado codificada como zero. As médias das outras três fontes ficam em torno de 240 a 250 mg/dl, o que é clinicamente plausível.

## Achados

### Achado 1: concentração sistemática de inconsistências em Switzerland

A fonte tem 100% dos registros com colesterol zero, 8,9% com oldpeak negativo (11 dos 12 casos do dataset inteiro), 95,9% de `ca` nulo e 93,5% dos pacientes classificados como doentes. Nenhuma outra fonte se comporta assim. O risco é que qualquer média global ou modelo treinado sem segmentação vai ficar enviesado por essa fonte.

### Achado 2: zeros usados como substituto de dado faltante

A VA Long Beach tem 49 registros com colesterol zero (24,5%) e 1 registro com pressão arterial zero. Zeros em variáveis contínuas normalmente significam "não medido" e não medição real. Se forem tratados como número, puxam médias e desvios-padrão para baixo.

### Achado 3: as fontes não são amostras equivalentes

A proporção de pacientes doentes varia de 36,2% (Hungary) a 93,5% (Switzerland). Isso pode refletir tanto critérios de inclusão diferentes quanto problemas de coleta. De qualquer forma, tratar os 920 registros como uma amostra única não é adequado.

### Achado 4: campos críticos com completude baixa

`ca` está nulo em 611 dos 920 registros (66,4%), `thal` em 486 (52,8%) e `slope` em 309 (33,6%). Qualquer modelo que dependa dessas variáveis perde a maior parte da base.

## Recomendações

1. Tratar `chol = 0` e `trestbps = 0` como NULL antes de qualquer análise.
2. Segmentar por `dataset` antes de tirar conclusões agregadas.
3. Investigar a origem dos oldpeak negativos junto ao fornecedor dos dados. Podem ser erro de sinal no registro.
4. Definir uma estratégia de imputação para `ca` e `thal` antes de usá-los em qualquer modelo.
5. Não comparar médias entre fontes sem antes verificar se os critérios de coleta eram os mesmos.

## Limitações

O dataset é público e histórico. Os achados mostram problemas de qualidade nos dados, não refletem a qualidade atual de nenhuma das instituições. O critério de "colesterol zero é impossível" assume paciente vivo, e a base não documenta casos de óbito. A fórmula 220 menos idade é uma aproximação, então os casos do sétimo comando são suspeitas e não erros confirmados.

## Como reproduzir

1. Baixar o arquivo `heart_disease_uci.csv` do Kaggle.
2. Abrir o DB Browser for SQLite, criar um banco chamado `heart_disease.db`.
3. Importar o CSV como tabela `heart`, marcando "First row contains column names" e deixando todas as colunas como TEXT (importar como INTEGER ou REAL causa erro de datatype mismatch por causa dos nulos).
4. Executar as consultas da pasta `consultas/` na ordem numérica.