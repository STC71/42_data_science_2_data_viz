# 🐍 Guía Python – EX02 My beautiful mustache

<p align="center">
  <em>Module 2 – Data Viz · estadísticas de precio + box plots</em>
</p>

[← README EX02](./README.md) · [← mustache.py](./mustache.py) · [← Module 2](../README.md) · [EX01 guía](../ex01/python.md)

---

<a id="indice"></a>
## 📑 Índice

### Parte A – Conceptos previos
1. [¿Para quién?](#para-quien)
2. [Qué es un script y `main`](#script)
3. [NumPy en 5 minutos](#numpy-basico)
4. [¿Qué es un box plot (moustache)?](#boxplot)
5. [count, mean, std, min, 25%, 50%, 75%, max](#stats)
6. [Percentiles con NumPy](#percentiles)
7. [De PostgreSQL a un vector de floats](#sql-vector)

### Parte B – El `mustache.py` del ejercicio
8. [Qué pide el subject](#subject)
9. [Por qué dos análisis (ítem y cesta)](#dos)
10. [Flujo completo del script](#flujo)
11. [Consulta 1 – precios de ítem](#q1)
12. [Consulta 2 – panier por usuario](#q2)
13. [La función `describe`](#describe)
14. [Cómo se dibuja el box plot](#plot)
15. [Outliers: mostrarlos u ocultarlos](#fliers)
16. [Backend: ventana vs PNG](#backend)
17. [Ejecutar y comprobar](#ejecutar)
18. [Qué decir en la defensa](#defensa)
19. [Errores frecuentes](#errores)
20. [Mini ejercicios](#ejercicios)
21. [Glosario](#glosario)
22. [Puente EX01 → EX02](#puente)

---

<a id="para-quien"></a>
## 👋 ¿Para quién?

Para entender el nombre del ejercicio (**mustache** = bigotes del *box plot*) y el paso de “millones de precios en `customers`” a una tabla tipo `pandas.describe()` y dos gráficos de caja.

Si ya hiciste EX00/EX01, puedes ir a la **Parte B**. La Parte A no asume estadística avanzada.

Al final, en defensa:

> “Calculo cuartiles y media de los precios `purchase`, dibujo un box plot, y repito el análisis sobre la cesta total por `user_id`.”

[↑ Volver al índice](#indice)

---

<a id="script"></a>
## 📜 Qué es un script y `main`

```bash
python3 mustache.py
```

```python
if __name__ == "__main__":
    main()
```

Solo se ejecuta `main()` cuando lanzas **este** archivo (no cuando alguien hace `import mustache`).

[↑ Volver al índice](#indice)

---

<a id="numpy-basico"></a>
## 🔢 NumPy en 5 minutos

```python
import numpy as np

a = np.array([1.0, 2.0, 3.0, 4.0])
a.size          # 4
np.mean(a)      # media
np.std(a, ddof=1)  # desviación muestral (como pandas)
np.min(a), np.max(a)
np.percentile(a, 50)  # mediana
```

Un `ndarray` de 1,2 millones de `float64` ocupa ~10 MB: viable en el cluster.

[↑ Volver al índice](#indice)

---

<a id="boxplot"></a>
## 📦 ¿Qué es un box plot (moustache)?

En francés: **boîte à moustaches**. En inglés: **box-and-whisker plot**.

```text
         bigote        caja              bigote
    |----------------|========|========|----------------|
   min              Q1       Q2       Q3               max
                           mediana
```

| Elemento | Qué representa |
|----------|----------------|
| **Caja** | Del 25% al 75% de los datos (IQR) |
| **Línea central** | Mediana (50%) |
| **Bigotes** | Extensión típica de los datos (a menudo hasta 1.5×IQR) |
| **Fliers** | Puntos outlier (opcional dibujarlos) |

Sirve para ver de un vistazo **dispersión** y **asimetría**, no solo la media.

[↑ Volver al índice](#indice)

---

<a id="stats"></a>
## 📐 count, mean, std, min, 25%, 50%, 75%, max

Es el resumen clásico de `Series.describe()` en pandas:

| Clave | Significado |
|-------|-------------|
| **count** | Cuántos valores |
| **mean** | Media aritmética |
| **std** | Desviación típica (muestral si `ddof=1`) |
| **min** | Valor más pequeño |
| **25%** | Primer cuartil Q1 |
| **50%** | Mediana Q2 |
| **75%** | Tercer cuartil Q3 |
| **max** | Valor más grande |

El subject pide **mostrar** estos números (en terminal o en el informe) además del dibujo.

[↑ Volver al índice](#indice)

---

<a id="percentiles"></a>
## 📊 Percentiles con NumPy

```python
np.percentile(arr, 25)  # Q1
np.percentile(arr, 50)  # mediana
np.percentile(arr, 75)  # Q3
```

El percentil *p* es un valor tal que aproximadamente el *p*% de las observaciones están por debajo.

[↑ Volver al índice](#indice)

---

<a id="sql-vector"></a>
## 🗄️ De PostgreSQL a un vector de floats

```python
with conn.cursor() as cur:
    cur.execute("SELECT price FROM customers WHERE event_type = 'purchase' ...")
    rows = cur.fetchall()
prices = np.fromiter((float(r[0]) for r in rows), dtype=float, count=len(rows))
```

`fromiter` evita crear una lista de objetos Python intermedios (más liviano).

[↑ Volver al índice](#indice)

---

<a id="subject"></a>
## 🎯 Qué pide el subject

| Requisito | En la práctica |
|-----------|----------------|
| Analizar precios de lo **comprado** | `event_type = 'purchase'` |
| Estadísticos tipo describe | count … max |
| **Box plot** | `ax.boxplot(...)` |
| Análisis del **panier** | `SUM(price) GROUP BY user_id` |
| Entrega | `ex02/mustache.*` |

[↑ Volver al índice](#indice)

---

<a id="dos"></a>
## 🛒 Por qué dos análisis (ítem y cesta)

| Análisis | Unidad de observación | Pregunta |
|----------|----------------------|----------|
| **Ítem** | Cada fila purchase | ¿Cuánto cuesta un producto comprado, de media / en distribución? |
| **Cesta** | Cada `user_id` | ¿Cuánto gasta un cliente en total en el periodo de datos? |

No son intercambiables: un usuario puede comprar 10 ítems baratos; su cesta es la **suma**.

[↑ Volver al índice](#indice)

---

<a id="flujo"></a>
## 🔄 Flujo completo del script

```text
1. ensure_dependencies()
2. Backend Agg si no hay DISPLAY
3. .env + connect
4. SELECT price          → array prices
5. SELECT SUM GROUP BY user_id → array baskets
6. describe(prices)  + print
7. describe(baskets) + print
8. boxplot precios → mustache_item_price.png
9. boxplot cestas  → mustache_basket.png
10. plt.show() (si hay pantalla)
```

[↑ Volver al índice](#indice)

---

<a id="q1"></a>
## 1️⃣ Consulta 1 – precios de ítem

```sql
SELECT price
FROM customers
WHERE event_type = 'purchase'
  AND price IS NOT NULL;
```

`price IS NOT NULL` evita que un NULL rompa `mean`/`percentile`.

[↑ Volver al índice](#indice)

---

<a id="q2"></a>
## 2️⃣ Consulta 2 – panier por usuario

```sql
SELECT user_id, SUM(price) AS basket
FROM customers
WHERE event_type = 'purchase'
  AND price IS NOT NULL
GROUP BY user_id;
```

El box plot y el describe usan solo la columna `basket` (no hace falta el `user_id` en el gráfico).

[↑ Volver al índice](#indice)

---

<a id="describe"></a>
## 🧮 La función `describe`

```python
def describe(arr: np.ndarray) -> dict[str, float]:
    return {
        "count": float(arr.size),
        "mean": float(np.mean(arr)),
        "std": float(np.std(arr, ddof=1)) if arr.size > 1 else 0.0,
        "min": float(np.min(arr)),
        "25%": float(np.percentile(arr, 25)),
        "50%": float(np.percentile(arr, 50)),
        "75%": float(np.percentile(arr, 75)),
        "max": float(np.max(arr)),
    }
```

Misma idea que pandas, sin depender de pandas (el subject no lo exige).

[↑ Volver al índice](#indice)

---

<a id="plot"></a>
## 🎨 Cómo se dibuja el box plot

```python
ax.boxplot(
    data,
    vert=False,           # horizontal (legible con un solo grupo)
    showfliers=False,     # sin puntos outlier
    patch_artist=True,    # caja con color de relleno
    boxprops={"facecolor": "#A0C4E8"},
    medianprops={"color": "#E45756", "linewidth": 1.5},
)
```

`vert=False` es la API estable en matplotlib 3.5 (cluster 42). En versiones muy nuevas también existe `orientation=`, pero `vert` es más portable.

[↑ Volver al índice](#indice)

---

<a id="fliers"></a>
## 📍 Outliers: mostrarlos u ocultarlos

Con precios de e-commerce a menudo hay colas largas (ítems caros).  
Si dejas `showfliers=True`, el eje se estira y **la caja se ve minúscula**.

El script usa `showfliers=False` por defecto para parecerse a los ejemplos limpios del PDF.  
En defensa puedes decir: “oculto fliers para enfatizar cuartiles; el max sigue en la tabla describe”.

[↑ Volver al índice](#indice)

---

<a id="backend"></a>
## 🖥️ Backend: ventana vs PNG

| Entorno | Comportamiento |
|---------|----------------|
| `DISPLAY` definido | Ventana con `plt.show()` |
| SSH sin display | Solo PNG (`Agg`) |
| `MPLBACKEND=Agg` | Fuerza solo PNG |

La prueba de dependencias **no** debe fijar `Agg` de forma permanente (mismo cuidado que EX00/EX01).

[↑ Volver al índice](#indice)

---

<a id="ejecutar"></a>
## ▶️ Ejecutar y comprobar

```bash
# Conteo de control en SQL
docker exec -it postgres_piscineds \
  psql -U "$(whoami)" -d piscineds -c \
  "SELECT COUNT(*) FROM customers WHERE event_type='purchase';"

docker exec -it postgres_piscineds \
  psql -U "$(whoami)" -d piscineds -c \
  "SELECT COUNT(DISTINCT user_id) FROM customers WHERE event_type='purchase';"

cd ex02
python3 mustache.py
```

Comprueba:

1. `count` de ítems ≈ `COUNT(*)` purchase.  
2. `count` de cestas ≈ `COUNT(DISTINCT user_id)`.  
3. `min` ≥ 0 (o el mínimo real de tus datos).  
4. Existen los dos PNG.

[↑ Volver al índice](#indice)

---

<a id="defensa"></a>
## 🎤 Qué decir en la defensa

1. Fuente: **`customers`**, solo **`purchase`**.  
2. Stats con NumPy (cuartiles + media + std).  
3. Box plot = distribución del **precio unitario**.  
4. Segundo paso: **`SUM(price) GROUP BY user_id`** = panier.  
5. Otro describe + otro box plot.  
6. Fliers ocultos para legibilidad; números exactos en la tabla.

[↑ Volver al índice](#indice)

---

<a id="errores"></a>
## ⚠️ Errores frecuentes

| Síntoma | Causa | Qué hacer |
|---------|-------|-----------|
| `connection refused` | Docker off | Arrancar Module 0 |
| count = 0 | Sin purchase | Revisar warehouse |
| `orientation` TypeError | Matplotlib antiguo | Usar `vert=` (script actual) |
| Caja invisible | Escala rota por outliers | `showfliers=False` |
| NumPy / matplotlib crash | Conflicto de versiones | `.venv` o `numpy==1.26.4` como en EX00 |

[↑ Volver al índice](#indice)

---

<a id="ejercicios"></a>
## ✏️ Mini ejercicios

1. Si un usuario compra 3 ítems a 10 ₳, ¿qué aporta al vector de ítems y qué al de cestas?  
2. ¿Por qué `ddof=1` en `std`?  
3. ¿Qué cuartil es la mediana?  
4. ¿Cómo comprobarías en SQL el `count` de cestas sin Python?

*(1: tres veces 10 en ítems; un 30 en cestas. 2: estimador muestral. 3: 50%. 4: `COUNT(DISTINCT user_id)` con purchase.)*

[↑ Volver al índice](#indice)

---

<a id="glosario"></a>
## 📖 Glosario

| Término | Significado |
|---------|-------------|
| **Mustache** | Bigotes del box plot |
| **IQR** | Q3 − Q1 |
| **Panier / basket** | Gasto total de un usuario |
| **Flier / outlier** | Punto fuera de los bigotes |
| **ddof** | Delta degrees of freedom en `std` |
| **vert** | Parámetro de `boxplot` (vertical u horizontal) |

[↑ Volver al índice](#indice)

---

<a id="puente"></a>
## 🔗 Puente EX01 → EX02

| EX01 | EX02 |
|------|------|
| Series temporales (día/mes) | Distribución de **una variable** (precio) |
| Totales y medias en el tiempo | Cuartiles y caja |
| Tres charts de volumen/gasto | Dos box plots (ítem + cesta) |

Misma fuente (`customers` / warehouse) y mismo espíritu: **SQL + Python + matplotlib**.

[↑ Volver al índice](#indice)

---

*Piscine Data Science – Module 2 – Data Viz – EX02 – Guía Python*  
*sternero – 42 Málaga – Octubre 2026*
