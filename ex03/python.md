# 🐍 Guía Python – EX03 Highest Building

<p align="center">
  <img src="./imgs/python_banner.jpg" alt="Piscine Data Science – Module 2 – Guía Python EX03" width="100%">
</p>

[← README EX03](./README.md) · [← Building.py](./Building.py) · [← Module 2](../README.md)

---

<a id="indice"></a>
## 📑 Índice

### Parte A – Conceptos
1. [¿Para quién?](#para-quien)
2. [Qué pide el subject](#subject)
3. [La figura del PDF](#pdf)
4. [Frequency vs Monetary](#fm)
5. [Error a evitar: una barra por entero](#error)

### Parte B – El script
6. [Diagrama de flujo](#flujo)
7. [Bins de frequency (ancho 10)](#bins-f)
8. [Bins de monetary (ancho 50 ₳)](#bins-m)
9. [SQL](#sql)
10. [Cómo se dibujan las barras](#plot)
11. [Ejecutar y comprobar](#ejecutar)
12. [Defensa](#defensa)
13. [Errores frecuentes](#errores)
14. [Glosario](#glosario)

---

<a id="para-quien"></a>
## 👋 ¿Para quién?

Para entender **Highest Building**: dos histogramas de clientes (frequency y monetary) con la **misma forma de bins** que el PDF del subject.

En defensa:

> “Por cada user_id cuento compras y sumo precios. Agrupo en tramos de 10 órdenes y de 50 ₳, y dibujo el skyline de clientes.”

[↑ Volver al índice](#indice)

---

<a id="subject"></a>
## 🎯 Qué pide el subject

```text
• bar chart: number of orders according to the frequency
• bar chart: Altairian Dollars spent on the site by customers
Turn-in: Building.*
```

[↑ Volver al índice](#indice)

---

<a id="pdf"></a>
## 🖼️ La figura del PDF

<p align="center">
  <img src="./imgs/customers_by_purchase_frecuency.png" alt="Frequency – bins de 10" width="100%">
</p>

<p align="center">
  <img src="./imgs/customers_by_total_spend.png" alt="Monetary – bins de 50 A" width="100%">
</p>

| Lado | Eje X | Forma esperada |
|------|-------|----------------|
| Frequency | 0 · 10 · 20 · 30 | ~4 barras **anchas** |
| Monetary | 0 · 50 · 100 · 150 · 200 | ~5 barras por tramos de 50 ₳ |

Los **números** del PDF no son ley (faltaba febrero). La **estructura de bins** sí.

[↑ Volver al índice](#indice)

---

<a id="fm"></a>
## 📊 Frequency vs Monetary

| | Frequency | Monetary |
|--|-----------|----------|
| Por usuario | `COUNT(*)` purchase | `SUM(price)` purchase |
| Bins | Paso **10** | Paso **50 ₳** |
| Eje Y | customers | customers |

[↑ Volver al índice](#indice)

---

<a id="error"></a>
## ⚠️ Error a evitar

**Incorrecto:** una barra por cada 1, 2, 3, …, 29 + `30+` → peine de ~30 barras.

**Correcto (PDF):** cuatro tramos 0–10 / 10–20 / 20–30 / 30+.

[↑ Volver al índice](#indice)

---

<a id="flujo"></a>
## 🔄 Diagrama de flujo

<p align="center">
  <img src="./imgs/python_diagrama_flujo.jpg" alt="Diagrama de flujo Building.py" width="100%">
</p>

```text
.env → connect → SQL frequency (bins×10) → SQL monetary (bins×50)
     → tablas resumen → PNG frequency + PNG monetary → show
```

<p align="center">
  <img src="./imgs/building_py.png" alt="Ejecución Building.py" width="100%">
</p>

[↑ Volver al índice](#indice)

---

<a id="bins-f"></a>
## 📦 Bins de frequency

```sql
CASE
  WHEN freq < 10 THEN 0   -- 1…9
  WHEN freq < 20 THEN 1
  WHEN freq < 30 THEN 2
  ELSE 3                  -- ≥ 30
END
```

Barras centradas en 5, 15, 25, 35 (eje estilo PDF).

[↑ Volver al índice](#indice)

---

<a id="bins-m"></a>
## 💰 Bins de monetary

```sql
CASE
  WHEN total_spent < 50  THEN 0
  WHEN total_spent < 100 THEN 1
  WHEN total_spent < 150 THEN 2
  WHEN total_spent < 200 THEN 3
  ELSE 4
END
```

[↑ Volver al índice](#indice)

---

<a id="sql"></a>
## 🗄️ SQL

```sql
SELECT user_id, COUNT(*) AS freq
FROM customers
WHERE event_type = 'purchase'
GROUP BY user_id;

SELECT user_id, SUM(price) AS total_spent
FROM customers
WHERE event_type = 'purchase' AND price IS NOT NULL
GROUP BY user_id;
```

[↑ Volver al índice](#indice)

---

<a id="plot"></a>
## 🎨 Barras

```python
ax.bar([5, 15, 25, 35], counts, width=9)
ax.set_xticks([0, 10, 20, 30])
ax.set_xlabel("frequency")
ax.set_ylabel("customers")
```

[↑ Volver al índice](#indice)

---

<a id="ejecutar"></a>
## ▶️ Ejecutar

```bash
python3 Building.py
```

Actualiza `imgs/customers_by_purchase_frecuency.png` y `imgs/customers_by_total_spend.png` (enlaces del README).

Comprueba: `TOTAL` frequency = `TOTAL` monetary = `COUNT(DISTINCT user_id)` con purchase.

[↑ Volver al índice](#indice)

---

<a id="defensa"></a>
## 🎤 Defensa

1. Solo **purchase** en **customers**.  
2. Frequency: bins de **10**.  
3. Monetary: bins de **50 ₳**.  
4. Eje Y = **clientes**.  
5. Cifras ≠ PDF por **febrero** (subject).

[↑ Volver al índice](#indice)

---

<a id="errores"></a>
## ⚠️ Errores frecuentes

| Síntoma | Causa | Qué hacer |
|---------|-------|-----------|
| ~30 barras finas | Bin por entero | Paso 10 |
| Suma ≠ compradores | Filtro / doble conteo | `COUNT(DISTINCT user_id)` |
| README sin imagen nueva | No re-ejecutaste | `python3 Building.py` |

[↑ Volver al índice](#indice)

---

<a id="glosario"></a>
## 📖 Glosario

| Término | Significado |
|---------|-------------|
| **Frequency** | Nº de compras del cliente |
| **Monetary** | Gasto total (₳) |
| **Bin** | Intervalo del histograma |
| **Highest Building** | Barras altas = muchos clientes |

[↑ Volver al índice](#indice)

---


---

<a id="verificar"></a>
## ✅ Verificación automática (tablas = gráficos = BD)

No basta con “que salga un histograma”: los números de las barras deben coincidir con SQL independiente.

| Opción en `./start.sh` | Acción |
|------------------------|--------|
| **7** | `verify_ex03.sql` — informe SQL completo |
| **8** | `Building.py --self-check` — **recomendado** |
| **9** | `--check-only` — rápido, **sin PNG** |

```bash
python3 Building.py --self-check
python3 Building.py --check-only
docker exec -i postgres_piscineds   psql -U "$(whoami)" -d piscineds < verify_ex03.sql
```

El self-check comprueba, entre otras cosas:

1. Suma de bins frequency = `COUNT(DISTINCT user_id)` con `purchase`
2. Barra **30+** = `HAVING COUNT(*) >= 30`
3. Suma monetary = usuarios con `price IS NOT NULL`
4. Barra **200+** = `HAVING SUM(price) >= 200`

Si los cuatro puntos pasan, **tablas, gráficos y warehouse están alineados**.

[↑ Volver al índice](#indice)

*Module 2 – EX03 – Guía Python · sternero – 42 Málaga – 2026*
