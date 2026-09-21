# 🐍 Guía Python – EX03 Highest Building

[← README EX03](./README.md) · [← Building.py](./Building.py) · [← Module 2](../README.md)

---

<a id="indice"></a>
## 📑 Índice

### Parte A – Conceptos
1. [¿Para quién?](#para-quien)
2. [Frequency vs Monetary](#fm)
3. [Agrupar por usuario, no por fila](#userid)
4. [Bins y la barra “30+” / “200+”](#bins)
5. [Barras como “edificios”](#bars)

### Parte B – El script
6. [Qué pide el subject](#subject)
7. [Flujo de `Building.py`](#flujo)
8. [SQL de frequency](#sql-f)
9. [SQL de monetary](#sql-m)
10. [Cómo se dibujan las barras](#plot)
11. [Ejecutar y comprobar](#ejecutar)
12. [Defensa](#defensa)
13. [Errores frecuentes](#errores)
14. [Mini ejercicios](#ejercicios)
15. [Glosario](#glosario)
16. [Puente EX02 → EX03 → EX04](#puente)

---

<a id="para-quien"></a>
## 👋 ¿Para quién?

Para entender por qué el ejercicio se llama **Highest Building**: las barras parecen un skyline — edificios más altos donde hay más clientes.

Al final, en defensa:

> “Cuento cuántas compras tiene cada user_id (frequency) y cuánto gasta en total (monetary). Agrupo en bins y dibujo dos histogramas de clientes.”

[↑ Volver al índice](#indice)

---

<a id="fm"></a>
## 📊 Frequency vs Monetary

| Dimensión | Pregunta | Cálculo por usuario |
|-----------|----------|---------------------|
| **Frequency** | ¿Cuántas veces ha comprado? | `COUNT(*)` de filas `purchase` |
| **Monetary** | ¿Cuánto ha gastado en total? | `SUM(price)` de esas filas |

Son dos caras del modelo **RFM** (Recency, Frequency, Monetary). Aquí aún no usamos Recency; EX04/EX05 lo retomarán para clustering.

[↑ Volver al índice](#indice)

---

<a id="userid"></a>
## 👤 Agrupar por usuario, no por fila

Mal (cuenta eventos, no clientes):

```sql
SELECT COUNT(*) FROM customers WHERE event_type = 'purchase';
```

Bien (un edificio por “altura” de hábito de compra):

```sql
SELECT user_id, COUNT(*) AS freq
FROM customers
WHERE event_type = 'purchase'
GROUP BY user_id;
```

Luego: “¿cuántos *usuarios* tienen freq = 1, freq = 2, …?”

[↑ Volver al índice](#indice)

---

<a id="bins"></a>
## 📦 Bins y la barra “30+” / “200+”

Sin techo, el eje X de frequency puede ir hasta cientos de compras (cola larga) y el gráfico se vuelve ilegible.

- **Frequency:** valores ≥ 30 se agrupan en la última barra **`30+`**.  
- **Monetary:** tramos `0–50`, `50–100`, `100–150`, `150–200`, **`200+`** (₳).

Es la misma idea que un histograma con el último intervalo abierto.

[↑ Volver al índice](#indice)

---

<a id="bars"></a>
## 🏗️ Barras como “edificios”

```python
ax.bar(labels, counts, color="#4C78A8", edgecolor="white")
ax.set_xlabel("frequency")
ax.set_ylabel("customers")
```

Cada barra = un “edificio” cuya altura es el número de clientes en ese bin.

[↑ Volver al índice](#indice)

---

<a id="subject"></a>
## 🎯 Qué pide el subject

| Ítem | Práctica |
|------|----------|
| Analizar frequency | Compras por `user_id` + histograma de clientes |
| Analizar monetary | `SUM(price)` por usuario + histograma por tramos |
| Entrega | `ex03/Building.*` |
| Fuente | Warehouse (`customers`) |

[↑ Volver al índice](#indice)

---

<a id="flujo"></a>
## 🔄 Flujo de `Building.py`

```text
.env → connect
  → SQL frequency (CTE + cap 30+)
  → SQL monetary (CTE + bins de gasto)
  → imprimir tablas resumen
  → bar chart frequency → PNG
  → bar chart monetary  → PNG
```

[↑ Volver al índice](#indice)

---

<a id="sql-f"></a>
## 1️⃣ SQL de frequency

```sql
WITH per_user AS (
    SELECT user_id, COUNT(*)::int AS freq
    FROM customers
    WHERE event_type = 'purchase'
    GROUP BY user_id
),
capped AS (
    SELECT CASE WHEN freq >= 30 THEN 30 ELSE freq END AS freq_bin
    FROM per_user
)
SELECT freq_bin, COUNT(*) AS n_customers
FROM capped
GROUP BY freq_bin
ORDER BY freq_bin;
```

[↑ Volver al índice](#indice)

---

<a id="sql-m"></a>
## 2️⃣ SQL de monetary

```sql
WITH per_user AS (
    SELECT user_id, SUM(price) AS total_spent
    FROM customers
    WHERE event_type = 'purchase' AND price IS NOT NULL
    GROUP BY user_id
)
-- CASE → bin_id 0..4 (0–50 … 200+)
```

Los `CASE` del script asignan cada gasto a un tramo.

[↑ Volver al índice](#indice)

---

<a id="plot"></a>
## 🎨 Cómo se dibujan las barras

```python
labels = [str(b) if b < 30 else "30+" for b in bins]
ax.bar(labels, counts)
ax.set_ylabel("customers")
```

Misma API `ax.bar` que en EX01 (ventas mensuales), distinta semántica (clientes por hábito, no millones de ₳ por mes).

[↑ Volver al índice](#indice)

---

<a id="ejecutar"></a>
## ▶️ Ejecutar y comprobar

```bash
python3 Building.py
```

Comprueba:

1. La suma de `n_customers` en frequency = `COUNT(DISTINCT user_id)` con purchase.  
2. Igual para monetary.  
3. La barra `1` (una sola compra) suele ser la más alta.  
4. Existen ambos PNG.

```sql
SELECT COUNT(DISTINCT user_id)
FROM customers
WHERE event_type = 'purchase';
```

[↑ Volver al índice](#indice)

---

<a id="defensa"></a>
## 🎤 Defensa (guion)

1. Solo **purchase** desde **customers**.  
2. **Frequency** = conteo de compras por usuario; bins hasta **30+**.  
3. **Monetary** = suma de precios por usuario; tramos de 50 ₳ hasta **200+**.  
4. Dos **bar charts** = “edificios” de clientes.  
5. Encaja con RFM previo al clustering (EX04/EX05).

[↑ Volver al índice](#indice)

---

<a id="errores"></a>
## ⚠️ Errores frecuentes

| Síntoma | Causa | Qué hacer |
|---------|-------|-----------|
| Un solo “edificio” enorme | Agrupaste eventos, no usuarios | `GROUP BY user_id` primero |
| Frequency sin 30+ | Cap distinto | Revisar `FREQ_CAP` |
| Monetary vacío | `price` NULL | Filtrar `price IS NOT NULL` |
| Suma de barras ≠ usuarios | Doble conteo | Un usuario → un solo bin |

[↑ Volver al índice](#indice)

---

<a id="ejercicios"></a>
## ✏️ Mini ejercicios

1. Un usuario con 45 compras: ¿en qué barra de frequency cae?  
2. Un usuario que gastó 175 ₳: ¿qué tramo monetary?  
3. ¿Por qué no usar `event_type = 'view'` aquí?

*(1: 30+. 2: 150–200. 3: frequency/monetary de compra, no de visita.)*

[↑ Volver al índice](#indice)

---

<a id="glosario"></a>
## 📖 Glosario

| Término | Significado |
|---------|-------------|
| **Frequency** | Nº de compras del cliente |
| **Monetary** | Gasto total del cliente |
| **Bin** | Intervalo que agrupa valores |
| **CTE (`WITH ...`)** | Subconsulta nombrada en SQL |
| **RFM** | Recency, Frequency, Monetary |

[↑ Volver al índice](#indice)

---

<a id="puente"></a>
## 🔗 Puente EX02 → EX03 → EX04

| EX02 | EX03 | EX04 |
|------|------|------|
| Distribución de **precios** (caja) | Distribución de **clientes** por F y M | **Elbow** sobre features de clientes |
| Un valor por ítem / cesta | Bins de hábitos | k óptimo para clustering |

[↑ Volver al índice](#indice)

---

*Module 2 – EX03 – Guía Python · sternero – 42 Málaga – 2026*
