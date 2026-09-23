# 📐 Ejercicio 04 – Elbow (Método del codo)

<p align="center">
  <img src="../imgs/banner_23.jpg" alt="Piscine Data Science – Module 2 – Data Viz · Elbow Method" width="100%">
</p>

[← README Module 2](../README.md) · [← EX03 Highest Building](../ex03/README.md)

---

<a id="indice"></a>
## 📑 Índice

1. [¿Qué se pide?](#que)
2. [Analogía cotidiana](#analogia)
3. [Archivos](#archivos)
4. [Prerrequisitos](#prereq)
5. [De clientes a números (RFM)](#rfm)
6. [¿Qué es el “codo”?](#codo)
7. [Qué hace `elbow.py` (sin saber Python)](#flujo)
8. [Ejecutar](#ejecutar)
9. [Cómo defender el k elegido](#defensa)
10. [Guía Python](#guia)
11. [Checklist](#checklist)
12. [Navegación](#navegacion)

---

<a id="que"></a>
## 🎯 ¿Qué se pide?

Subject **Elbow** (Module 2 – Data Viz):

| Requisito | Detalle |
|-----------|---------|
| Directorio | `ex04/` |
| Entrega | **`elbow.*`** |
| Contexto | El jefe quiere **grupos de clientes** para campañas de e-mail |
| Técnica | **Método del codo (Elbow)** para intuir el nº de clusters |
| Defensa | Explicar **cuántos** clusters eliges y **por qué** |

> EX05 pedirá **al menos 4 grupos** (nuevos, inactivos, loyalty…). El Elbow de EX04 prepara esa decisión.

[↑ Volver al índice](#indice)

---

<a id="analogia"></a>
## 🏪 Analogía cotidiana

Imagina una tienda que quiere enviar correos distintos:

| Grupo | Mensaje típico |
|-------|----------------|
| Clientes **nuevos** | “Bienvenido, 10 % en tu segunda compra” |
| **Inactivos** | “Te echamos de menos, cupón de regreso” |
| **Fieles** | “Gold / Silver: acceso anticipado” |

Antes de inventar 20 segmentos (caro e inútil) o solo 2 (demasiado tosco), miras un gráfico: **¿a partir de cuántos grupos la mejora deja de compensar?**  
Eso es el **codo**.

[↑ Volver al índice](#indice)

---

<a id="archivos"></a>
## 📁 Archivos

| Archivo | Rol |
|---------|-----|
| [`elbow.py`](./elbow.py) | Entrega **`elbow.*`**: RFM + KMeans + curva |
| [`python.md`](./python.md) | Guía paso a paso (también si no programas) |
| [`start.sh`](./start.sh) | Menú asistente (Docker, SQL, ejecutar) |

Tras ejecutar `elbow.py` se generan (entre otros):

| PNG | Contenido |
|-----|-----------|
| [`imgs/elbow_method.png`](./imgs/elbow_method.png) | Curva del codo (referencia del README) |
| `elbow_method.png` | Copia en la raíz de `ex04/` |

<p align="center">
  <img src="./imgs/elbow_method.png" alt="The Elbow Method – inertia vs number of clusters" width="100%">
</p>

[↑ Volver al índice](#indice)

---

<a id="prereq"></a>
## ⚙️ Prerrequisitos

| Qué | Dónde |
|-----|--------|
| PostgreSQL Up | Module 0 · contenedor `postgres_piscineds` |
| Tabla `customers` | Module 1 (warehouse) |
| Python | `psycopg2`, `matplotlib`, `numpy`, **`scikit-learn`** |

[↑ Volver al índice](#indice)

---

<a id="rfm"></a>
## 📦 De clientes a números (RFM)

Cada cliente con al menos una **compra** se resume en **tres números**:

| Letra | Nombre | Pregunta humana | Cálculo |
|-------|--------|-----------------|---------|
| **R** | Recency | ¿Hace cuánto compró por última vez? | Días desde la última `purchase` |
| **F** | Frequency | ¿Cuántas veces ha comprado? | `COUNT(*)` de compras |
| **M** | Monetary | ¿Cuánto ha gastado en total? | `SUM(price)` en ₳ |

**Ejemplo de tres clientes:**

| Cliente | R (días) | F | M (₳) | Lectura rápida |
|---------|----------|---|-------|----------------|
| Ana | 3 | 20 | 400 | Muy activa y gasta |
| Bruno | 120 | 1 | 15 | Casi olvidado |
| Carla | 10 | 2 | 30 | Reciente pero poco volumen |

Esos tres ejes son la **entrada** del algoritmo de agrupación.

[↑ Volver al índice](#indice)

---

<a id="codo"></a>
## 🦴 ¿Qué es el “codo”?

1. Pruebas agrupar a los clientes en **1 grupo**, luego **2**, **3**, … hasta **10**.  
2. Mides un error interno llamado **inertia** (qué tan “apretados” están los puntos de cada grupo).  
3. Más grupos → inertia **siempre** baja.  
4. Al principio baja **mucho**; después la curva se **aplana**.  
5. El **codo** es la zona donde dejar de añadir grupos tiene sentido (beneficio marginal pequeño).

```text
inertia (error interno)
  │ *
  │   *
  │     *
  │       *  *  *  *  *   ← aplanamiento ≈ codo
  └──────────────────────►  k (nº de clusters)
        1  2  3  4  5 …
```

[↑ Volver al índice](#indice)

---

<a id="flujo"></a>
## 🔄 Qué hace `elbow.py` (sin saber Python)

```text
1. Conectar a PostgreSQL (mismo .env que Module 0)
2. SQL: un resumen RFM por cada user_id con purchase
3. Poner las tres medidas en la misma “escala” (StandardScaler)
4. Para k = 1, 2, …, 10:
      crear k grupos (KMeans) y guardar la inertia
5. Dibujar inertia frente a k  →  “The Elbow Method”
6. Proponer un k (heurística + recuerdo de que EX05 pide ≥ 4)
```

No hace falta memorizar el código: basta entender este flujo para la defensa.

[↑ Volver al índice](#indice)

---

<a id="ejecutar"></a>
## ▶️ Ejecutar

```bash
cd data_science_2_data_viz/ex04

# Recomendado en cluster / sin pantalla
MPLBACKEND=Agg python3 elbow.py

# Con ventana gráfica (si hay DISPLAY)
python3 elbow.py

# Menú asistente
chmod +x start.sh
./start.sh
```

[↑ Volver al índice](#indice)

---

<a id="defensa"></a>
## 🎤 Cómo defender el k elegido

Plantilla breve:

> “Resumo cada cliente en Recency, Frequency y Monetary a partir de `purchase`.  
> Escalo las variables y calculo la inertia de KMeans para k de 1 a 10.  
> En la curva se ve el codo hacia k = …  
> Elijo **k = …** porque a partir de ahí la inertia baja poco y EX05 pide **al menos 4** segmentos comerciales (nuevos, inactivos, loyalty…).”

[↑ Volver al índice](#indice)

---

<a id="guia"></a>
## 📘 Guía Python

**[python.md](./python.md)** — misma historia con más detalle, ejemplos y mapa del código.

[↑ Volver al índice](#indice)

---

<a id="checklist"></a>
## ✅ Checklist subject

| Ítem | ☐ |
|------|---|
| Entrega `ex04/elbow.*` | ☐ |
| Gráfico Elbow (inertia vs k) | ☐ |
| Saber explicar el k y el porqué | ☐ |
| PNG actualizado en `imgs/` tras ejecutar | ☐ |

[↑ Volver al índice](#indice)

---

<a id="navegacion"></a>
## 🔗 Navegación

- [← EX03 Building](../ex03/README.md)
- [← Module 2](../README.md)
- [Siguiente: EX05 Clustering →](../ex05/README.md)

---

*Module 2 – EX04 – sternero – 42 Málaga – 2026*
