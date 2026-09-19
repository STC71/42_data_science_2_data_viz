# 🐍 Guía Python – EX00 American apple Pie

[← README EX00](./README.md) · [← Module 2](../README.md)

---

<a id="indice"></a>
## 📑 Índice

### Parte A – Desde cero (si no has programado en Python)
1. [¿Para quién?](#para-quien)
2. [Qué es un script](#script)
3. [`import`, `def`, f-strings](#basico)
4. [Listas y bucles](#listas)
5. [Conectar a PostgreSQL desde Python](#psycopg2)
6. [Matplotlib en 3 ideas](#matplotlib)

### Parte B – El `pie.py` de este ejercicio
7. [Qué pide el subject](#subject)
8. [Por qué este enfoque](#por-que)
9. [Flujo del script (paso a paso)](#flujo)
10. [La consulta SQL](#sql)
11. [Cómo se dibuja el pie](#pie)
12. [Ejecutar y comprobar](#ejecutar)
13. [Errores frecuentes](#errores)
14. [Glosario](#glosario)

---

<a id="para-quien"></a>
## 👋 ¿Para quién?

Para quien llega a Module 2 y quiere entender **`pie.py`** sin asumir que ya domina Python, SQL o gráficos.

Al final deberías poder explicar en defensa:

> “Me conecto al warehouse del Module 1, cuento filas por `event_type` y dibujo un gráfico de tarta con los porcentajes.”

[↑ Volver al índice](#indice)

---

<a id="script"></a>
## 📜 Qué es un script

Un archivo `.py` es un programa de texto. Lo lanzas así:

```bash
python3 pie.py
```

Python lee el archivo de arriba abajo. Si al final hay:

```python
if __name__ == "__main__":
    main()
```

entonces, **solo cuando ejecutas este archivo directamente**, se llama a `main()`.  
Si otro archivo hiciera `import pie`, no se ejecutaría el programa entero (solo se cargarían las funciones).

[↑ Volver al índice](#indice)

---

<a id="basico"></a>
## 🧱 `import`, `def`, f-strings

### `import`

Trae herramientas de otros módulos:

```python
import os          # variables de entorno
import sys         # salir con error, stderr
from pathlib import Path   # rutas de archivos portables
```

### `def`

Define una función (un bloque reutilizable):

```python
def saludar(nombre: str) -> None:
    print(f"Hola {nombre}")
```

- `nombre: str` → pista de tipo (texto)
- `-> None` → no devuelve valor “útil” (solo hace algo)

### f-strings

```python
n = 42
print(f"Total: {n:,}")   # Total: 42  (con separador de miles si aplica)
```

[↑ Volver al índice](#indice)

---

<a id="listas"></a>
## 📋 Listas y bucles

```python
filas = [("view", 100), ("cart", 50)]
for tipo, cantidad in filas:
    print(tipo, cantidad)
```

En `pie.py`, las filas vienen de PostgreSQL: cada una es un `event_type` y su `COUNT(*)`.

[↑ Volver al índice](#indice)

---

<a id="psycopg2"></a>
## 🐘 Conectar a PostgreSQL desde Python

**psycopg2** es el “cable” entre Python y PostgreSQL (igual que en Module 1).

```python
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    port=5432,
    dbname="piscineds",
    user="tu_login",
    password="mysecretpassword",
)
cur = conn.cursor()
cur.execute("SELECT event_type, COUNT(*) FROM customers GROUP BY 1;")
rows = cur.fetchall()   # lista de tuplas
cur.close()
conn.close()
```

- **`connect`**: abre la sesión con la base (Docker publica el 5432 en tu máquina).  
- **`cursor`**: canal para enviar SQL y leer resultados.  
- **`fetchall`**: trae todas las filas del resultado a memoria (aquí son pocas: un conteo por tipo de evento).

Las credenciales se leen del **`.env` de Module 0** cuando existe (no hardcodear secretos en el código de entrega si puedes evitarlo).

[↑ Volver al índice](#indice)

---

<a id="matplotlib"></a>
## 📈 Matplotlib en 3 ideas

1. **`pyplot` (`plt`)** – interfaz para crear figuras.  
2. **`ax.pie(...)`** – dibuja sectores de un círculo (la “tarta”).  
3. **`plt.show()`** – muestra la ventana; **`savefig`** guarda un PNG.

```python
import matplotlib.pyplot as plt

fig, ax = plt.subplots()
ax.pie([30, 70], labels=["A", "B"], autopct="%1.1f%%")
ax.set_title("Ejemplo")
plt.show()
```

`autopct` escribe el porcentaje dentro de cada porción.

Sin pantalla gráfica (solo terminal):

```bash
MPLBACKEND=Agg python3 pie.py
```

[↑ Volver al índice](#indice)

---

<a id="subject"></a>
## 🎯 Qué pide el subject

| Ítem | Texto del PDF |
|------|----------------|
| Carpeta | `ex00/` |
| Archivo | **`pie.*`** |
| Gráfico | *Make your own pie chart to understand what people do on the site* |
| Fuente | *Connect to your Data Warehouse of module 01* |

En la práctica: tabla **`customers`** (Module 1), columna **`event_type`**, un **pie chart** con porcentajes.

[↑ Volver al índice](#indice)

---

<a id="por-que"></a>
## 💡 Por qué este enfoque

| Alternativa | Problema |
|-------------|----------|
| Leer CSV a mano | El subject pide el **warehouse** de Module 1 |
| Contar solo `purchase` | Aquí queremos **todas** las acciones del sitio |
| Gráfico de barras | El subject pide **pie** (y el ejemplo del PDF es un pie) |

La agregación se hace **en SQL** (`GROUP BY`): PostgreSQL cuenta millones de filas y Python solo recibe unas pocas filas (una por `event_type`). Así no cargamos 19 millones de eventos en RAM solo para un tarta.

[↑ Volver al índice](#indice)

---

<a id="flujo"></a>
## 🔄 Flujo del script (paso a paso)

```text
1. ensure_dependencies()     → psycopg2, dotenv, matplotlib si faltan
2. find_env_file() + load    → POSTGRES_* desde Module 0
3. psycopg2.connect(...)     → piscineds
4. SELECT event_type, COUNT(*) ... GROUP BY event_type
5. Imprimir tabla de conteos en terminal
6. ax.pie(...) + leyenda + título
7. Guardar pie_chart.png y plt.show()
```

### Funciones principales

| Función | Rol |
|---------|-----|
| `ensure_dependencies` | `pip install --user` si falta un módulo |
| `find_env_file` | Busca `data_science_0_creation_db/ex00/.env` |
| `fetch_event_counts` | Ejecuta el SQL y devuelve `[(tipo, n), ...]` |
| `plot_pie` | Dibuja y guarda el gráfico |
| `main` | Orquesta todo |

[↑ Volver al índice](#indice)

---

<a id="sql"></a>
## 🗄️ La consulta SQL

```sql
SELECT event_type, COUNT(*) AS n
FROM customers
GROUP BY event_type
ORDER BY n DESC;
```

- **`GROUP BY event_type`**: una fila de resultado por valor distinto de `event_type`.  
- **`COUNT(*)`**: cuántas filas de `customers` caen en ese grupo.  
- **`ORDER BY n DESC`**: primero lo más frecuente (útil para la leyenda).

Ejemplo de salida típica (los números dependen de tu BD):

| event_type | n |
|------------|---|
| view | … |
| cart | … |
| remove_from_cart | … |
| purchase | … |

[↑ Volver al índice](#indice)

---

<a id="pie"></a>
## 🥧 Cómo se dibuja el pie

Idea:

```python
labels = ["view", "cart", ...]
sizes  = [123456, 78910, ...]   # mismos índices

ax.pie(
    sizes,
    autopct=lambda p: f"{p:.1f}%",  # porcentaje con 1 decimal
    startangle=90,
)
ax.legend(...)   # nombres + conteos
ax.set_title("Qué hacen los usuarios en el sitio")
ax.axis("equal")  # círculo, no elipse
```

- **`startangle=90`**: el primer sector empieza “arriba”.  
- **Leyenda aparte**: los nombres largos no saturan el dibujo; el PDF del subject también etiqueta por tipo.  
- **Colores**: solo estética; lo evaluable es que el gráfico refleje los datos.

[↑ Volver al índice](#indice)

---

<a id="ejecutar"></a>
## ▶️ Ejecutar y comprobar

```bash
# 1) PostgreSQL (Module 0) y customers (Module 1)
docker ps | grep postgres_piscineds

docker exec -it postgres_piscineds \
  psql -U "$(whoami)" -d piscineds -c \
  "SELECT event_type, COUNT(*) FROM customers GROUP BY 1 ORDER BY 2 DESC;"

# 2) Script
cd data_science_2_data_viz/ex00
python3 pie.py
```

Comprobación:

1. Los % del gráfico ≈ los de la consulta SQL.  
2. Aparecen los `event_type` de tu warehouse (con febrero si está en `customers`).  
3. En defensa: “fuente = Module 1 `customers`, no CSV suelto”.

[↑ Volver al índice](#indice)

---

<a id="errores"></a>
## ⚠️ Errores frecuentes

| Síntoma | Causa probable | Qué hacer |
|---------|----------------|-----------|
| `connection refused` | Docker parado | `docker start postgres_piscineds` o Module 0 compose |
| `relation "customers" does not exist` | Falta Module 1 EX01 | Crear `customers` |
| `No module named matplotlib` | Paquete no instalado | El script intenta instalarlo; o `pip install --user matplotlib` |
| No se abre ventana | Sin display / SSH | `MPLBACKEND=Agg python3 pie.py` y mira `pie_chart.png` |
| Porcentajes raros | Tabla vacía o mal filtrada | Revisa `COUNT(*)` total en `customers` |

[↑ Volver al índice](#indice)

---

<a id="glosario"></a>
## 📖 Glosario

| Término | Significado breve |
|---------|-------------------|
| **Data Warehouse** | Aquí: BD `piscineds` tras Module 1 (`customers`) |
| **event_type** | Tipo de acción: view, cart, purchase… |
| **Pie chart** | Gráfico de sectores (tarta) |
| **GROUP BY** | Agrupar filas SQL por una columna |
| **psycopg2** | Driver Python ↔ PostgreSQL |
| **matplotlib** | Biblioteca de gráficos |
| **`.env`** | Archivo de variables (usuario, password, BD) |

[↑ Volver al índice](#indice)

---

*Piscine Data Science – Module 2 – Data Viz – EX00 – Guía Python*  
*sternero – 42 Málaga – Octubre 2026*
