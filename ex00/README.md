# 🥧 Ejercicio 00 – American apple Pie

<p align="center">
  <img src="../imgs/banner_20.jpg" alt="Piscine Data Science – Module 0 – pie chart de event_type" width="100%">
</p>

[← README Module 2](../README.md)

---

<a id="indice"></a>
## 📑 Índice

1. [¿Qué se pide?](#que)
2. [Archivos](#archivos)
3. [Prerrequisitos](#prereq)
4. [Idea del gráfico](#idea)
5. [Ejecutar](#ejecutar)
6. [Comprobar](#comprobar)
7. [Guía Python](#guia)
8. [Checklist](#checklist)
9. [Navegación](#navegacion)

---

<a id="que"></a>
## 🎯 ¿Qué se pide?

Literalmente (subject):

> Make your own pie chart to understand what people do on the site  
> You have to connect to your Data Warehouse of module 01

| Requisito | Detalle |
|-----------|---------|
| Directorio | `ex00/` |
| Entrega | **`pie.*`** |
| Fuente | Data Warehouse Module 1 → tabla **`customers`** |
| Gráfico | **Pie chart** de acciones en el sitio |

El ejemplo del PDF reparte sectores por `event_type` (`view`, `cart`, `remove_from_cart`, `purchase`, …) con porcentajes.

[↑ Volver al índice](#indice)

---

<a id="archivos"></a>
## 📁 Archivos

| Archivo | Rol |
|---------|-----|
| [`pie.py`](./pie.py) | Conexión a PostgreSQL + pie chart (entrega `pie.*`) |
| [`python.md`](./python.md) | Guía didáctica (Python desde cero + el script) |
| [`start.sh`](./start.sh) | Menú opcional: entorno, SQL, ejecutar pie.py |

Opcional al ejecutar: se genera `pie_chart.png` en esta carpeta (no es obligatorio para el subject; sirve para README/defensa).

[↑ Volver al índice](#indice)

---

<a id="prereq"></a>
## ⚙️ Prerrequisitos

1. Contenedor `postgres_piscineds` en marcha (Module 0).  
2. Tabla **`customers`** creada (Module 1 **EX01** como mínimo; idealmente tras EX02/EX03).  
3. Credenciales habituales: login / `mysecretpassword` / `piscineds`.  
4. Python 3 con `psycopg2`, `python-dotenv`, `matplotlib` (el script puede instalarlos con `pip --user`).

```bash
docker exec -it postgres_piscineds \
  psql -U "$(whoami)" -d piscineds -c \
  "SELECT event_type, COUNT(*) FROM customers GROUP BY 1 ORDER BY 2 DESC;"
```
| ¿Qué hace el SQL?  |  |
| ----------------- | - |
| <b>Fragmento</b> | <b>Significado</b> |
| FROM customers | Tabla del warehouse (Module 1): todos los eventos apilados. |
| event_type | Tipo de acción: view, cart, purchase, remove_from_cart, etc. |
| COUNT(*) | Cuántas filas hay en cada grupo. |
| GROUP BY 1 | Agrupa por la 1ª columna del SELECT → event_type. (Equivalente a GROUP BY event_type.) |
| ORDER BY 2 DESC | Ordena por la 2ª columna (COUNT(*)) de mayor a menor. |

<p align="center">
  <img src="./imgs/psql_00.png" alt="Piscine Data Science – Module 2 – psql_00.png" width="100%">
</p>

[↑ Volver al índice](#indice)

---

<a id="idea"></a>
## 🧠 Idea del gráfico

```sql
SELECT event_type, COUNT(*) AS n
FROM customers
GROUP BY event_type
ORDER BY n DESC;
```

Cada fila es una **porción de la tarta**. No filtramos por fecha ni por `purchase`: el subject pide entender **qué hacen** en el sitio en general.

[↑ Volver al índice](#indice)

---

<a id="ejecutar"></a>
## ▶️ Ejecutar

```bash
cd data_science_2_data_viz/ex00
python3 pie.py
# o
chmod +x pie.py && ./pie.py
```

Se guarda `pie_chart.png` si el backend de matplotlib lo permite; `plt.show()` mostrará ventana.

<p align="center">
  <img src="./imgs/pie_py_00.png" alt="Piscine Data Science – Module 2 – pie_py_00.png" width="100%">
</p>

<p align="center">
  <img src="./imgs/matplotlib_00.png" alt="Piscine Data Science – Module 2 – matplotlib" width="100%">
</p>

En un entorno sin pantalla (solo terminal), puedes usar:

```bash
MPLBACKEND=Agg python3 pie.py
```
<p align="center">
  <img src="./imgs/pie_py_01.png" alt="Piscine Data Science – Module 2 – pie_py_01.png" width="100%">
</p>

(el PNG se generará igual; `plt.show()` no mostrará ventana).

[↑ Volver al índice](#indice)

---

<a id="comprobar"></a>
## ✅ Comprobar

- Ejecuta `pie.py` y compara los porcentajes de cada sector con los resultados de la consulta `GROUP BY event_type` anterior. Ambos deben representar la misma proporción de eventos.  
- Deben aparecer los `event_type` presentes en tu `customers` (incl. febrero si está en el warehouse).  
- En defensa: explicar “conectamos al Module 1, agregamos por `event_type`, dibujamos el pie”.

[↑ Volver al índice](#indice)

---


<a id="guia"></a>
## 📘 Guía Python

Si partes de cero o quieres repasar el script línea a línea:

**[python.md](./python.md)** — conceptos básicos, `psycopg2`, matplotlib, flujo de `pie.py`, errores frecuentes.

Asistente local:

```bash
chmod +x start.sh
./start.sh
```

[↑ Volver al índice](#indice)

---

<a id="checklist"></a>
## ✅ Checklist subject

| Ítem | ☐ |
|------|---|
| Entrega `ex00/pie.*` | ☐ |
| Conexión al Data Warehouse (Module 1 / `customers`) | ☐ |
| Pie chart legible con tipos de evento | ☐ |
| Demostrable en la máquina del evaluado | ☐ |

[↑ Volver al índice](#indice)

---

<a id="navegacion"></a>
## 🔗 Navegación

- [← README Module 2](../README.md)
- [Siguiente: EX01 – chart →](../ex01/README.md)

---

*Piscine Data Science – Module 2 – Data Viz – EX00*  
*sternero – 42 Málaga – Octubre 2026*
