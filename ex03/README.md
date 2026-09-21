# 🏗️ Ejercicio 03 – Highest Building (Edificio más alto)

<p align="center">
  <em>Module 2 – Data Viz · frequency & monetary (barras “edificios”)</em>
</p>

[← README Module 2](../README.md) · [← EX02](../ex02/README.md)

---

<a id="indice"></a>
## 📑 Índice

1. [¿Qué se pide?](#que)
2. [Archivos](#archivos)
3. [Prerrequisitos](#prereq)
4. [Los dos edificios](#edificios)
5. [SQL (idea)](#sql)
6. [Ejecutar](#ejecutar)
7. [Guía Python](#guia)
8. [Checklist](#checklist)
9. [Navegación](#navegacion)

---

<a id="que"></a>
## 🎯 ¿Qué se pide?

Subject **Highest Building**:

| Requisito | Detalle |
|-----------|---------|
| Directorio | `ex03/` |
| Entrega | **`Building.*`** |
| Análisis | **Frequency** (cuántas veces compra cada cliente) |
| Análisis | **Monetary** (cuánto gasta en total cada cliente) |
| Visual | Diagramas de barras (perfil de “skyline” / edificios) |
| Fuente | Warehouse Module 1 → `customers`, filas `purchase` |

[↑ Volver al índice](#indice)

---

<a id="archivos"></a>
## 📁 Archivos

| Archivo | Rol |
|---------|-----|
| [`Building.py`](./Building.py) | Frequency + monetary (entrega `Building.*`) |
| [`python.md`](./python.md) | Guía didáctica |
| [`start.sh`](./start.sh) | Menú opcional |

PNG al ejecutar: `building_frequency.png`, `building_monetary.png`.

[↑ Volver al índice](#indice)

---

<a id="prereq"></a>
## ⚙️ Prerrequisitos

- Module 0: PostgreSQL Up  
- Module 1: `customers` con `user_id`, `event_type`, `price`  
- Python: `psycopg2`, `matplotlib`

[↑ Volver al índice](#indice)

---

<a id="edificios"></a>
## 🏙️ Los dos edificios

| Gráfico | Eje X | Eje Y | Idea |
|---------|-------|-------|------|
| **Frequency** | Nº de compras del cliente (1…29, **30+**) | Nº de clientes | ¿Cuántos compran 1 vez, 2 veces…? |
| **Monetary** | Tramo de gasto total (0–50, …, **200+** ₳) | Nº de clientes | ¿Cuántos gastan poco / mucho? |

La agregación es **por usuario** (no por fila suelta): primero `GROUP BY user_id`, luego se cuenta cuántos usuarios caen en cada bin.

[↑ Volver al índice](#indice)

---

<a id="sql"></a>
## 🗄️ SQL (idea)

```sql
-- Frecuencia por usuario
SELECT user_id, COUNT(*) AS freq
FROM customers
WHERE event_type = 'purchase'
GROUP BY user_id;

-- Gasto total por usuario
SELECT user_id, SUM(price) AS total_spent
FROM customers
WHERE event_type = 'purchase'
GROUP BY user_id;
```

Luego se **binnea** (30+ en frequency; tramos de 50 ₳ en monetary) y se cuenta clientes por bin.

[↑ Volver al índice](#indice)

---

<a id="ejecutar"></a>
## ▶️ Ejecutar

```bash
cd data_science_2_data_viz/ex03
python3 Building.py
MPLBACKEND=Agg python3 Building.py
./start.sh
```

[↑ Volver al índice](#indice)

---

<a id="guia"></a>
## 📘 Guía Python

**[python.md](./python.md)** — frequency/monetary, bins, defensa.

[↑ Volver al índice](#indice)

---

<a id="checklist"></a>
## ✅ Checklist subject

| Ítem | ☐ |
|------|---|
| Entrega `ex03/Building.*` | ☐ |
| Gráfico de frequency | ☐ |
| Gráfico de monetary | ☐ |
| Solo `purchase` / por `user_id` | ☐ |

[↑ Volver al índice](#indice)

---

<a id="navegacion"></a>
## 🔗 Navegación

- [← EX02 mustache](../ex02/README.md)
- [← Module 2](../README.md)
- [Siguiente: EX04 Elbow →](../ex04/README.md)

---

*Module 2 – EX03 – sternero – 42 Málaga – 2026*
