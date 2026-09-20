# 🐍 Guía Python – EX01 initial data exploration

<p align="center">
  <img src="./imgs/python_banner.jpg" alt="Piscine Data Science – Module 2 – Data Viz · ex01 · Python Banner width="100%">
</p>

[← README EX01](./README.md) · [← Module 2](../README.md)

---

<a id="indice"></a>
## 📑 Índice

1. [Objetivo del subject](#subject)
2. [Filtro `purchase` y fechas](#filtro)
3. [Por qué agregar en SQL](#sql)
4. [Los 3 gráficos en código](#plots)
5. [Altairian Dollars](#money)
6. [Ejecutar y comprobar](#ejecutar)
7. [Errores frecuentes](#errores)
8. [Glosario](#glosario)

---

<a id="subject"></a>
## 🎯 Objetivo del subject

Tres visualizaciones de **compras** entre **octubre 2022** y **febrero 2023**, usando el warehouse Module 1 (`customers`).

Entrega: **`chart.*`**.

[↑ Volver al índice](#indice)

---

<a id="filtro"></a>
## 🔍 Filtro `purchase` y fechas

```sql
WHERE event_type = 'purchase'
  AND event_time >= TIMESTAMP '2022-10-01'
  AND event_time <  TIMESTAMP '2023-03-01'
```

- El límite superior **exclusivo** `2023-03-01` incluye todo febrero.
- El subject avisa que los gráficos del PDF se hicieron **sin** febrero: hay que **rehacerlos con febrero**.

[↑ Volver al índice](#indice)

---

<a id="sql"></a>
## 🗄️ Por qué agregar en SQL

Hay ~1,2 M de `purchase` (y muchos más eventos totales).  
`GROUP BY` día/mes en PostgreSQL devuelve cientos de filas, no millones.

| Consulta | Agrupa | Métrica |
|----------|--------|---------|
| Clientes/día | `event_time::date` | `COUNT(*)` |
| Ventas/mes | `date_trunc('month', …)` | `SUM(price)` |
| Gasto medio/día | día | `SUM(price)/COUNT(*)` |

[↑ Volver al índice](#indice)

---

<a id="plots"></a>
## 📈 Los 3 gráficos en código

```python
# 1) Línea
ax.plot(days, counts)

# 2) Barras (millones)
ax.bar(month_labels, [s / 1_000_000 for s in sales])

# 3) Área
ax.fill_between(days, avgs, alpha=0.45)
ax.plot(days, avgs)
```

`matplotlib.dates` formatea el eje X (`%b` = Oct, Nov, …).

[↑ Volver al índice](#indice)

---

<a id="money"></a>
## ₳ Altairian Dollars

El subject dice que los precios están en **Altairian Dollars**.  
En los ejes usamos “million of ₳” y “spend … in ₳” como en el PDF (no hace falta convertir a euros).

[↑ Volver al índice](#indice)

---

<a id="ejecutar"></a>
## ▶️ Ejecutar y comprobar

```bash
python3 chart.py
```

Comprueba:

1. Aparecen **5 meses** (Oct–Feb) en barras si hay datos de febrero.  
2. Solo se usó `purchase` (el total de puntos no debe ser el de todos los event_type).  
3. Los PNG se escriben en `ex01/`.

[↑ Volver al índice](#indice)

---

<a id="errores"></a>
## ⚠️ Errores frecuentes

| Síntoma | Causa | Qué hacer |
|---------|-------|-----------|
| Sin filas | Sin purchase / mal rango | Revisa `event_type` y fechas |
| Falta febrero en barras | Warehouse sin feb | Module 0+1 con `data_2023_feb` |
| NumPy / matplotlib | Conflicto de versiones | Mismo arreglo que EX00 (`.venv`) |
| No hay ventana | Sin `DISPLAY` | Normal en SSH; mira los PNG |

[↑ Volver al índice](#indice)

---

<a id="glosario"></a>
## 📖 Glosario

| Término | Significado |
|---------|-------------|
| **purchase** | Evento de compra |
| **date_trunc('month', …)** | Primer día del mes de una timestamp |
| **fill_between** | Área bajo la curva (chart 3) |
| **₳** | Altairian Dollar (subject) |

[↑ Volver al índice](#indice)

---

*Module 2 – EX01 – Guía Python · sternero – 42 Málaga – Octubre 2026*
