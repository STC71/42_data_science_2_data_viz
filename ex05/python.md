# 🐍 Guía Python – EX05 Clustering

<p align="center">
  <img src="./imgs/python_banner.jpg" alt="Piscine Data Science – Module 2 – Guía Python EX05 Clustering" width="100%">
</p>

[← README EX05](./README.md) · [← Clustering.py](./Clustering.py) · [← Module 2](../README.md)

---

<a id="indice"></a>
## 📑 Índice

1. [¿Para quién?](#para-quien)
2. [Subject en lenguaje humano](#subject)
3. [RFM otra vez (30 segundos)](#rfm)
4. [KMeans en una frase](#kmeans)
5. [De id de cluster a cartel de negocio](#etiquetas)
6. [Los dos gráficos](#graficos)
7. [Mapa de `Clustering.py`](#mapa)
8. [Relación con EX04](#ex04)
9. [Defensa](#defensa)
10. [Errores frecuentes](#errores)
11. [Glosario](#glosario)

---

<a id="para-quien"></a>
## 👋 ¿Para quién?

Para quien ya vio el Elbow (EX04) y quiere **poner nombres** a los grupos y **dibujarlos**.

[↑ Volver al índice](#indice)

---

<a id="subject"></a>
## 🎯 Subject en lenguaje humano

El jefe quiere correos distintos:

| Grupo | Ejemplo de correo |
|-------|-------------------|
| Nuevo | Welcome + descuento 2ª compra |
| Inactivo | “Te echamos de menos” + cupón |
| Silver / Gold / Platinum | Status y ventajas |

Hace falta un **algoritmo de clustering** y **al menos dos gráficos**.

[↑ Volver al índice](#indice)

---

<a id="rfm"></a>
## 📦 RFM otra vez (30 segundos)

Misma ficha por cliente que en EX04:

| Columna | Significado |
|---------|-------------|
| Recency | Días desde la última compra |
| Frequency | Nº de compras |
| Monetary | Suma de `price` (₳) |

Solo `event_type = 'purchase'`.

[↑ Volver al índice](#indice)

---

<a id="kmeans"></a>
## 🔁 KMeans en una frase

Elige *k* centros y asigna cada cliente al centro más cercano (tras escalar).  
Aquí **k = 5** para cubrir new + inactive + tres niveles de loyalty (≥ 4 del PDF).

[↑ Volver al índice](#indice)

---

<a id="etiquetas"></a>
## 🏷️ De id de cluster a cartel de negocio

KMeans devuelve 0,1,2… Sin más, eso no sirve para marketing.

1. Se miran los **centroides en escala real** (días, compras, ₳).  
2. **inactive** = mayor recency.  
3. **new** = menor frequency entre el resto.  
4. Los que quedan se ordenan por monetary → **silver < gold < platinum**.

Así las etiquetas **siguen a los datos**, no a un orden fijo del algoritmo.

[↑ Volver al índice](#indice)

---

<a id="graficos"></a>
## 📊 Los dos gráficos (mínimo del subject)

1. **`customers_per_cluster.png`** — barras: cuántos clientes hay en cada cartel.  
2. **`clusters_frequency_monetary.png`** — scatter Frequency × Monetary coloreado por grupo (muestra aleatoria para no saturar el PNG).

[↑ Volver al índice](#indice)

---

<a id="mapa"></a>
## 🗺️ Mapa de `Clustering.py`

| Bloque | Rol |
|--------|-----|
| `ensure_dependencies` | Campus: instalar sklearn si falta |
| `SQL_RFM` / `fetch_rfm` | Matriz clientes × 3 |
| `fit_clusters` | Scaler + KMeans |
| `assign_business_labels` | Carteles de negocio |
| `print_cluster_report` | Tabla en consola |
| `plot_group_sizes` | Gráfico 1 |
| `plot_scatter_fm` | Gráfico 2 |

[↑ Volver al índice](#indice)

---

<a id="ex04"></a>
## 🔗 Relación con EX04

EX04 argumenta el **número** de grupos; EX05 los **materializa**.  
No hace falta rehacer el Elbow dentro de este script: se reutiliza la lógica RFM y se fija k=5 (≥ 4).

[↑ Volver al índice](#indice)

---

<a id="defensa"></a>
## 🎤 Defensa

1. Subject: ≥ 4 grupos + clustering + ≥ 2 gráficos.  
2. RFM solo purchase.  
3. KMeans k=5, seed fija.  
4. Cómo se asignan new / inactive / loyalty.  
5. Enseñar los dos PNG.

[↑ Volver al índice](#indice)

---

<a id="errores"></a>
## ⚠️ Errores frecuentes

| Síntoma | Qué hacer |
|---------|-----------|
| `No module named sklearn` | `elbow`/`Clustering` instalan; o `pip install --user scikit-learn` |
| Grupos “al revés” | Revisar reglas de centroides (recency alta = inactive) |
| Scatter vacío / denso | Es normal muestrear; no cambia el modelo |

[↑ Volver al índice](#indice)

---

<a id="glosario"></a>
## 📖 Glosario

| Término | Significado |
|---------|-------------|
| **Centroid** | “Promedio” del grupo en el espacio RFM |
| **KMeans** | Clustering por cercanía a k centros |
| **Loyalty** | silver / gold / platinum según gasto |

[↑ Volver al índice](#indice)

---


---

<a id="etiquetado-afinado"></a>
## 🏷️ Etiquetado afinado (new vs inactive vs loyalty)

### Problema que resolvía el afinado

Con la regla antigua (“inactive = máxima recency global; new = mínima frequency del resto”), en datos reales **new** e **inactive** salían con frequency ≈ 7 y monetary ≈ 36 ₳: casi el mismo perfil; solo se distinguían por unos días de recency. Decir “new” por “el que compra menos” no contaba una historia de negocio clara.

### Regla actual (dos pasos)

```text
1) Ordenar centroides por monetary (descendente)
   → top 3 = loyalty → silver < gold < platinum (monetary ascendente)

2) Los 2 restantes (bajo volumen)
   → inactive = mayor recency
   → new      = menor recency
```

### Analogía

Imagina dos montones de clientes que casi no gastan:

- Uno lleva **más tiempo** sin pasar por la tienda → cupón de **reactivación** (inactive).
- El otro, igual de “pequeño” en gasto, pero su última visita es **más reciente** → mensaje de **bienvenida / segunda compra** (new).

Los que sí gastan se escalonan en **silver / gold / platinum** como tarjetas de fidelidad.

### Qué no cambia

- Sigue siendo **KMeans** (algoritmo de clustering del subject).
- Siguen siendo **≥ 4 grupos** y **≥ 2 gráficos**.
- Solo mejora la **lectura comercial** de las etiquetas.

[↑ Volver al índice](#indice)

---

<a id="lectura-resultados"></a>
## 📊 Cómo leer una corrida típica

En el warehouse completo (~110 k compradores) es normal ver:

| Bloque | Orden de magnitud | Idea |
|--------|-------------------|------|
| new + inactive | decenas de miles cada uno | La base: poco volumen |
| silver | ~10 k | Loyalty medio |
| gold | ~2 k | Loyalty alto |
| platinum | cientos | Muy pocos, mucho gasto |

El scatter Frequency × Monetary debe mostrar **platinum/gold** a la derecha/arriba y el bloque new/inactive cerca del origen. Si new e inactive se solapan en F×M, es esperado: su diferencia principal es **recency** (no visible en ese eje).

[↑ Volver al índice](#indice)

*Module 2 – EX05 – Guía Python · sternero – 42 Málaga – Octubre 2026*
