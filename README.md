# 📊 Piscine Data Science – Module 2 – Data Viz

<p align="center">
  <img src="./imgs/banner_00.jpg" alt="Piscine Data Science – Module 2 – Training Piscine datascience – 2" width="100%">
</p>

<p align="center">
  <strong>Visualización · reporting · clustering de clientes</strong><br>
</p>

---

<a id="indice"></a>
## 📑 Índice

1. [¿De qué trata?](#proyecto)
2. [Estructura del repositorio](#estructura)
3. [Prerrequisitos](#prereq)
4. [Orden de trabajo (subject)](#orden)
5. [Qué entrega cada ejercicio](#entregas)
6. [Asistente global (`./start.sh`)](#asistente-global)
7. [Asistentes por ejercicio](#asistentes-ex)
8. [Nota sobre febrero](#febrero)
9. [Checklist subject](#checklist)
10. [Navegación](#navegacion)

---

<a id="proyecto"></a>
## 🎯 ¿De qué trata?

Conectar al **Data Warehouse del Module 01** (`customers`) y **mostrar** los datos:

| Bloque | Idea |
|--------|------|
| EX00–EX02 | Acciones en el sitio, clientes/compras en el tiempo, distribución de precios |
| EX03 | Frequency y monetary (edificios) |
| EX04 | Elbow → número de clusters (selecciona `k=5`) |
| EX05 | Clustering con etiquetas de negocio (≥ 4 grupos) |

Todo el pipeline de gráficos usa **PostgreSQL** (`piscineds`) y, en la práctica, solo eventos `purchase` cuando el subject lo pide.

[↑ Volver al índice](#indice)

---

<a id="estructura"></a>
## 📁 Estructura del repositorio

```text
data_science_2_data_viz/
├── README.md          ← este fichero
├── start.sh           ← asistente GLOBAL del módulo
├── imgs/              ← banners / capturas opcionales
├── ex00/  pie.*
├── ex01/  chart.*
├── ex02/  mustache.*
├── ex03/  Building.*
├── ex04/  elbow.*
├── ex05/  Clustering.*
└── evaluation.sh       ← guía interactiva de defensa
```

Cada `ex0N/` incluye, además de la entrega:

| Extra | Rol |
|-------|-----|
| `README.md` | Subject, defensa, checklist |
| `python.md` | Guía didáctica |
| `start.sh` | Menú local del ejercicio (opcional) |

[↑ Volver al índice](#indice)

---

<a id="prereq"></a>
## ⚙️ Prerrequisitos

| Módulo | Qué hace falta |
|--------|----------------|
| **0** | Contenedor `postgres_piscineds` · BD `piscineds` · `.env` |
| **1** | Tabla **`customers`** (eventos + items fusionados) |

Python habitual: `psycopg2`, `matplotlib`, `numpy`; EX04–EX05 también **`scikit-learn`**.

[↑ Volver al índice](#indice)

---

<a id="orden"></a>
## 🧭 Orden de trabajo (subject)

```text
EX00 Pie  →  EX01 Charts  →  EX02 Mustache
                ↓
            EX03 Building (frequency / monetary)
                ↓
            EX04 Elbow (¿cuántos grupos?)
                ↓
            EX05 Clustering (≥ 4 grupos + ≥ 2 gráficos)
```

[↑ Volver al índice](#indice)

---

<a id="entregas"></a>
## 📦 Qué entrega cada ejercicio

| Carpeta | Ejercicio | Entrega | Estado |
|---------|-----------|---------|--------|
| [`ex00/`](ex00/README.md) | American apple Pie | **`pie.*`** | ✅ |
| [`ex01/`](ex01/README.md) | initial data exploration | **`chart.*`** | ✅ |
| [`ex02/`](ex02/README.md) | My beautiful mustache | **`mustache.*`** | ✅ |
| [`ex03/`](ex03/README.md) | Highest Building | **`Building.*`** | ✅ |
| [`ex04/`](ex04/README.md) | Elbow | **`elbow.*`** | ✅ |
| [`ex05/`](ex05/README.md) | Clustering | **`Clustering.*`** | ✅ |

> Los menús y README **no** sustituyen los ficheros del subject.

[↑ Volver al índice](#indice)

---

<a id="asistente-global"></a>
## 🖥️ Asistente global (`./start.sh`)

En la **raíz** del módulo:

```bash
cd data_science_2_data_viz
./start.sh
```

Permite, sin sustituir las entregas:

- Estado del entorno (Module 0, `.env`, contenedor, entregas presentes)
- Levantar PostgreSQL (vía Module 0)
- Abrir `psql`
- Lanzar cada ejercicio (`pie` … `Clustering`) en ventana o solo PNG
- Recordar qué fichero hay que entregar en cada `ex0N/`

Cada ejercicio sigue teniendo su propio `ex0N/start.sh` más detallado.

## 🧪 Evaluación guiada (`evaluation.sh`)

La guía se basa en `en.subject.pdf` y `evaluation_en_2.pdf` y funciona desde
cualquier directorio porque resuelve dinámicamente la ruta donde está ubicada.
No sustituye la defensa oficial: ayuda a preparar el entorno, ejecutar los
entregables y conservar las evidencias.

```bash
chmod +x evaluation.sh
./evaluation.sh
```

Comprueba, con confirmación antes de ejecutar acciones:

- estructura y entregables `pie.*`, `chart.*`, `mustache.*`, `Building.*`,
  `elbow.*` y `Clustering.*`;
- Docker, PostgreSQL y la tabla `customers` producida por Module 1;
- patrones relevantes del código (`purchase`, estadísticas, `boxplot`,
  barras, elbow, `StandardScaler`, `KMeans`) localizados dinámicamente, sin
  depender de números de línea fijos. La revisión aparece justo al comenzar
  cada EX, junto con su explicación, referencia al archivo y línea relevante y artefactos esperados;
- ejecución opcional de cada script con `MPLBACKEND=Agg`, generación de PNG y
  comandos reproducibles;
- demostración visual de cada ejercicio y explicación del codo, el número de
  clusters y el significado de los segmentos.

La escala tiene criterios que no pueden aprobarse solo mirando archivos. Por
eso la guía pregunta expresamente si se han mostrado:

| Ejercicio | Evidencia de defensa |
|-----------|----------------------|
| EX00 | pie chart conectado al warehouse |
| EX01 | tres gráficos con solo `purchase`, clientes distintos por día y gasto medio por cliente, desde octubre hasta febrero |
| EX02 | estadísticas, box plot de precios, box plot de cesta y explicación |
| EX03 | dos bar charts equivalentes al subject |
| EX04 | curva elbow y justificación de `k` |
| EX05 | el mismo `k` que EX04, al menos dos gráficos e interpretación de cada grupo |

La coherencia EX04 → EX05 se comprueba después de ejecutar ambos ejercicios:
primero se explica la curva y la elección de `k`, y después se verifica que EX05
usa exactamente el mismo número. En este proyecto se ha elegido `k=5` porque
la curva se suaviza en esa zona y permite los cinco segmentos de negocio
`new`, `inactive`, `silver`, `gold` y `platinum`. El mínimo de cuatro procede
del subject y exige al menos separar clientes nuevos, inactivos y perfiles de
fidelidad; no convierte `k=4` en una elección obligatoria.

El PNG existente no se considera por sí solo una prueba de ejecución correcta:
el evaluador debe abrirlo o mostrar la ventana y explicar lo que observa.
Después de cada Enter se limpia la terminal y se indica que se trata de una
continuación, no de un reinicio. El resultado verde es orientativo y no
sustituye la decisión oficial de la escala.

[↑ Volver al índice](#indice)

---

<a id="asistentes-ex"></a>
## 🧰 Asistentes por ejercicio

| Ruta | Uso típico |
|------|------------|
| `ex00/start.sh` … `ex05/start.sh` | Estado, SQL de control, ejecutar script, docs |

[↑ Volver al índice](#indice)

---

<a id="febrero"></a>
## 📅 Nota sobre febrero

El PDF del subject muestra gráficos **sin** febrero. Con el warehouse completo (oct 2022–feb 2023) los **totales cambian**; la lógica de filtros y gráficos es la que evalúan.

[↑ Volver al índice](#indice)

---

<a id="checklist"></a>
## ✅ Checklist subject

| Ítem | ☐ |
|------|---|
| EX00 `pie.*` | ☐ |
| EX01 `chart.*` | ☐ |
| EX02 `mustache.*` | ☐ |
| EX03 `Building.*` | ☐ |
| EX04 `elbow.*` | ☐ |
| EX05 `Clustering.*` | ☐ |
| Contenedor Up + `customers` accesible | ☐ |

[↑ Volver al índice](#indice)

---

<a id="navegacion"></a>
## 🔗 Navegación

- [← Module 1 Data Warehouse](../data_science_1_data_warehouse/README.md)
- [→ Module 3 The present](../data_science_3_the_present/README.md)
- [Monorepo](../README.md)

---

*sternero – 42 Málaga – Module 2 – Data Viz – Octubre 2026*
