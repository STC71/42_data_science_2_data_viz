# 📐 Matemáticas del Module 2 – Data Viz

<p align="center">
  <img src="./imgs/banner_mates.jpg" alt="Piscine Data Science – Module 2 – Training Piscine datascience – 2  – Matemáticas  – sternero – 42 Málaga" width="100%">
</p>

<br>Este es un documento **didáctico**: no sustituye al subject ni a los scripts (`pie.*`, `chart.*`, …).  
Sirve para **entender con calma** las cuentas que hay detrás de cada gráfico, **sin dar por sentado** que ya sabes estadística o machine learning.

> **Analogía global:** la tabla `customers` es un cuaderno enorme de lo que hizo cada persona en la tienda online.  
> Aquí no inventamos números: **contamos, promediamos, ordenamos y agrupamos** esos apuntes para que un jefe los entienda de un vistazo.

> **Sobre las fórmulas:** cuando aparezca un símbolo (\(\bar{x}\), \(\sigma\), \(\sum\)…), justo debajo hay una tabla o un ejemplo numérico.  
> No hace falta memorizar la notación: sirve para **ver de dónde sale** el número que luego dibuja el gráfico.

---

## 📑 Índice

1. [Ideas que se repiten en todo el módulo](#ideas-base)
2. [EX00 – Porcentajes y el gráfico de tarta](#ex00)
3. [EX01 – Conteos, sumas y medias en el tiempo](#ex01)
4. [EX02 – Media, mediana, cuartiles y el “bigote”](#ex02)
5. [EX03 – Histogramas: frequency y monetary](#ex03)
6. [RFM – Tres números por cliente](#rfm)
7. [EX04 – Escalado, K-Means e inertia (codo)](#ex04)
8. [EX05 – Mismos grupos, lectura de negocio](#ex05)
9. [Mini glosario](#glosario)
10. [Cómo usarlo en la defensa](#defensa)

---

## 1. Ideas que se repiten en todo el módulo {#ideas-base}

### 1.1 Contar

**Contar** = “¿cuántas filas cumplen esto?”

- En SQL suele ser `COUNT(*)`.
- Ejemplo: ¿cuántos eventos son de tipo `view`?

**Analogía:** en una urna con papeletas de colores, contar las rojas.

### 1.2 Sumar

**Sumar** = juntar cantidades (`SUM(price)`).

- SUM(): Es la función que le dice a la base de datos: "Suma todos los valores de esta columna".
- price: Es el nombre de la columna (en este caso, los precios) que quieres juntar y sumar.

**Analogía:** total de la caja registradora al final del día.

### 1.3 Media (promedio)

$$
\text{media} = \frac{\text{suma de los valores}}{\text{cuántos valores hay}}
$$

**Analogía:** cinco amigos pagan 2, 2, 2, 2 y 100 €. La media es \((2+2+2+2+100)/5 = 21,6 €\).  
La media **se deja arrastrar** por el 100 € (un valor raro).

#### Fórmula “con letras” (sin miedo)

Si tienes \(n\) números \(x_1, x_2, \ldots, x_n\) (por ejemplo, \(n\) precios):

$$
\bar{x} = \frac{1}{n}\sum_{i=1}^{n} x_i
= \frac{x_1 + x_2 + \cdots + x_n}{n}
$$

| Símbolo | Significado cotidiano |
|---------|------------------------|
| \(x_i\) | el valor número \(i\) (un precio, un gasto…) |
| \(n\) | cuántos valores hay |
| \(\sum\) | “suma desde el primero hasta el último” |
| \(\bar{x}\) | nombre habitual de la **media** (se lee “x barra”) |

**Cómo se calcula a mano (ejemplo del módulo):**

1. Suma: \(2+2+2+2+100 = 108\).
2. Divide por la cantidad: \(108 / 5 = 21{,}6\).

No hay truco oculto: **sumar y dividir por cuántos hay**.

### 1.4 Valores distintos (DISTINCT)

A veces no queremos contar **filas**, sino **personas**.

- `COUNT(*)` → tickets / eventos.
- `COUNT(DISTINCT user_id)` → clientes diferentes.

**Analogía:** en una cola, la misma persona pasa tres veces. ¿Hay tres personas o una que volvió?

### 1.5 Filtrar

Casi todo EX01–EX05 trabaja solo con **`event_type = 'purchase'`** (compras).  
Es como ignorar “solo miré el escaparate” y quedarte con “pagué en caja”.

### 1.6 Porcentaje

$$
\text{porcentaje de A} = \frac{\text{cantidad de A}}{\text{total}} \times 100
$$

Si hay 100 eventos y 50 son `view` → 50 %.

[↑ Volver al índice](#indice)

**De dónde sale la fórmula:**  
“Parte entre total” es una **proporción** (número entre 0 y 1). Multiplicar por 100 solo la expresa en **porcentaje** (más cómodo de leer).

Ejemplo con números del pie (orden de magnitud del warehouse):

| Tipo | Conteo (ejemplo) | Proporción | Porcentaje |
|------|------------------|------------|------------|
| view | 9 654 310 | \(9654310 / 19175899 \approx 0{,}503\) | ≈ 50,3 % |
| purchase | 1 286 088 | \(1286088 / 19175899 \approx 0{,}067\) | ≈ 6,7 % |

[↑ Volver al índice](#indice)

---

## 2. EX00 – Porcentajes y el gráfico de tarta {#ex00}

### Qué pregunta responde

> De **todo** lo que pasó en el sitio (mirar, carrito, quitar, comprar…), ¿qué **parte** es cada cosa?

### La cuenta (en palabras)

1. Cuenta cuántos eventos hay de cada `event_type`.
2. Suma todos esos conteos → total.
3. Para cada tipo: \(\text{porción} = \text{conteo} / \text{total}\).

En SQL la idea es:

#### Fórmula del sector del pie

Sea \(n_c\) el número de eventos de la categoría \(c\), y \(N = \sum_c n_c\) el total:

$$
p_c = \frac{n_c}{N}, \qquad
\text{porcentaje}_c = 100 \cdot p_c, \qquad
\text{ángulo del sector}_c = 360^\circ \cdot p_c
$$

- \(p_c\) es la **proporción** (parte del círculo).  
- El ángulo en grados es la misma proporción del círculo completo (360°).  
- Matplotlib (y cualquier librería) dibuja el sector con área proporcional a \(p_c\); no hace falta calcular el ángulo a mano, pero **entenderlo** aclara por qué “media tarta” ≈ 50 %.

**Ejemplo minúsculo:** 3 view, 1 purchase → \(N=4\).  
view → \(3/4 = 0{,}75\) → 75 % → \(0{,}75 \times 360^\circ = 270^\circ\).

En SQL la idea es:

```sql
SELECT event_type, COUNT(*) AS n
FROM customers
GROUP BY event_type;
```

### Por qué un *pie chart* (tarta)

Cuando la pregunta es **“¿qué fracción del total?”**, un círculo partido en sectores es natural: el área de cada porción **es** ese porcentaje.

**No** sirve bien para “cómo cambió esto mes a mes” (eso es EX01).

### Números típicos en *nuestro* warehouse

Tras Module 1, con ~19 millones de eventos, el orden suele ser:

| Tipo | Orden de magnitud (orientativo) |
|------|----------------------------------|
| `view` | ~ mitad de los eventos |
| `cart` | ~ un tercio o menos |
| `remove_from_cart` | menor |
| `purchase` | la porción **más pequeña** |

Los % exactos salen de **vuestra** BD; el PDF del subject solo muestra un ejemplo.

[↑ Volver al índice](#indice)

---

## 3. EX01 – Conteos, sumas y medias en el tiempo {#ex01}

Tres gráficos; **solo `purchase`**.

### 3.1 Clientes distintos por día

**Pregunta:** cada día, ¿cuántas **personas diferentes** compraron?

**PNG correspondiente:** [`puchases_per_day.png`](./ex01/imgs/puchases_per_day.png)  
Es el gráfico de línea con el número de **clientes distintos por día**.

$$
\text{clientes del día } d = \text{número de } user\_id \text{ distintos con purchase en } d
$$

```sql
SELECT COUNT(DISTINCT user_id) AS clientes_unicos
FROM tu_tabla_de_ventas
WHERE fecha_columna = 'tu_fecha_aqui'  -- Aquí defines el día (d = n)
  AND estado_compra = 'purchase';      -- Aquí filtras solo los que compraron
```


¿Y si quieres ver el cálculo de todos los días por separado?

Si en lugar de un solo día quieres ver una lista con el conteo de cada uno de los días, solo debes agregar un GROUP BY:

```sql
SELECT 
    fecha_columna AS dia,                        -- Fecha en la que se registró la compra
    COUNT(DISTINCT user_id) AS clientes_unicos   -- Cuenta cada cliente una sola vez por día
FROM tu_tabla_de_ventas                          -- Tabla que contiene las ventas
WHERE estado_compra = 'purchase'                 -- Conserva únicamente las compras
GROUP BY fecha_columna                           -- Agrupa todas las compras del mismo día
ORDER BY fecha_columna;                          -- Muestra los días en orden cronológico
```

**Analogía:** no cuentas tickets de caja, cuentas **personas distintas que compraron** en la tienda ese día.

### 3.2 Ventas por mes

**Pregunta:** cada mes, ¿cuánto dinero sumaron las compras?

**PNG correspondiente:** [`total_sales_by_months.png`](./ex01/imgs/total_sales_by_months.png)  
Es el gráfico de barras con las **ventas totales de cada mes**.

$$
\text{ventas del mes } m = \sum \text{price de los purchase en } m
$$

Para responder a esta pregunta y generar ese gráfico de barras de ventas mensuales, en SQL usamos una combinación de SUM(price) para sumar el dinero y un GROUP BY para separar los resultados mes por mes.

```sql
SELECT 
    mes_columna AS mes,                 -- Mes en el que se registraron las compras
    SUM(price) AS ventas_totales        -- Suma el precio de todas las compras del mes
FROM tu_tabla_de_ventas                 -- Tabla que contiene las ventas
WHERE estado_compra = 'purchase'        -- Conserva únicamente las compras
GROUP BY mes_columna                    -- Agrupa las ventas correspondientes al mismo mes
ORDER BY mes_columna;                   -- Muestra los meses en orden cronológico
```

**Analogía:** total de la caja de octubre, de noviembre, etc.

### 3.3 Gasto medio por cliente y día

**Pregunta:** el día \(d\), de media, ¿cuánto gastó cada comprador?

**PNG correspondiente:** [`average_spend.png`](./ex01/imgs/average_spend.png)  
Es el gráfico de área con el **gasto medio diario por cliente**.

$$
\text{gasto medio}(d) = \frac{\text{suma de price ese día}}{\text{clientes distintos ese día}}
$$

Con notación un poco más formal, si el día \(d\) tiene precios de compra \(x_1,\ldots,x_m\) repartidos entre \(u\) clientes distintos:

$$
\text{gasto medio}(d) = \frac{\sum_{i=1}^{m} x_i}{u}
= \frac{\mathrm{SUM}(\texttt{price})\text{ del día }d}{\mathrm{COUNT}(\mathrm{DISTINCT}\ \texttt{user\_id})\text{ del día }d}
$$

**Ojo:** el denominador es **personas**, no filas. Si un cliente compra tres veces el mismo día, aporta tres precios al numerador pero **solo uno** al denominador.

```sql
SELECT 
    fecha_columna AS dia,                                -- Día en el que se registraron las compras
    SUM(price) / COUNT(DISTINCT user_id) AS gasto_medio  -- Ventas del día divididas entre sus clientes
FROM tu_tabla_de_ventas                                  -- Tabla que contiene las ventas
WHERE estado_compra = 'purchase'                         -- Conserva únicamente las compras
GROUP BY fecha_columna                                   -- Calcula un resultado independiente por día
ORDER BY fecha_columna;                                  -- Muestra los días en orden cronológico
```

**Analogía:** un día pueden pasar pocas personas pero comprar caro → media alta; o muchas personas comprando barato → media más baja.

### Por qué “líneas” y “barras” en el tiempo

En estos gráficos, el eje X representa el **tiempo**: cada punto o barra corresponde a
un día o a un mes. Al colocar las fechas en orden, podemos **comparar periodos y detectar
la evolución de las compras**: subidas, bajadas, picos o temporadas con más actividad.
La línea resulta especialmente útil para seguir una tendencia, mientras que las barras
facilitan comparar cantidades entre meses.

Un *pie chart* (como el que tenemos en ex00) responde a otra pregunta: **cómo se reparte un total entre varias
categorías**. Sus sectores muestran proporciones, pero no colocan los datos en una
secuencia temporal; por eso no es adecuado para observar cómo cambian las ventas de un
mes a otro.

[↑ Volver al índice](#indice)

---

## 4. EX02 – Media, mediana, cuartiles y el “bigote” {#ex02}

En EX02, los apartados **4.1, 4.2 y 4.3** explican los valores estadísticos
que se calculan, pero no tienen un PNG independiente: esos valores se resumen
visualmente dentro de los box plots del apartado 4.4.

### Qué vemos en cada box plot

#### `box_plot_price.png`: precio de los artículos comprados

**PNG correspondiente:** [`box_plot_price.png`](./ex02/imgs/box_plot_price.png)

Cada valor representa el `price` de una línea `purchase`, es decir, el precio
de un artículo comprado. La caja contiene el 50 % central de esos precios:
su extremo izquierdo es Q1, la línea roja es la mediana (Q2) y su extremo
derecho es Q3. Los bigotes muestran el rango de valores que el gráfico no
considera extremos. En esta imagen no aparecen puntos de *outliers* porque el
script los oculta con `showfliers=False`.

La caja es bastante más ancha hacia la derecha y el bigote derecho es largo:
esto indica que hay más dispersión entre los precios altos y algunos productos
son mucho más caros que los precios habituales. La media, que se imprime en la
consola pero no se dibuja como una línea, puede verse afectada por esos valores
altos.

#### `box_plot_average.png`: precio medio por usuario

**PNG correspondiente:** [`box_plot_average.png`](./ex02/imgs/box_plot_average.png)

Aquí cada valor representa el precio medio de los artículos comprados por un
usuario: primero se calcula `AVG(price)` agrupando por `user_id` y después se
construye el box plot con esas medias. Por eso este gráfico responde a una
pregunta distinta: no describe cada artículo, sino el precio típico de compra
de cada cliente.

La caja muestra el 50 % central de las medias de los usuarios. En comparación
con el gráfico anterior, la escala es mucho mayor y la caja se extiende
aproximadamente entre los 16 y los 62 ₳, con una mediana cercana a 33 ₳. El
bigote derecho llega aproximadamente a 130 ₳, lo que muestra que algunos
usuarios tienen una media de compra bastante más alta. Como en el gráfico
anterior, los posibles *outliers* no se dibujan.

### 4.1 Media vs mediana (con paciencia)

Imagina que ordenas **todos los precios de compra** de menor a mayor, como ordenar a la gente por altura en una fila.

#### Mediana (el del centro)

- Si hay un número **impar** de valores → la mediana es el valor que queda **exactamente en el medio**.
- Si hay un número **par** → suele tomarse la **media de los dos valores centrales**.

Ordena los datos: \(x_{(1)} \le x_{(2)} \le \cdots \le x_{(n)}\) (el subíndice entre paréntesis significa “ya ordenados”).

$$
\mathrm{mediana} =
\begin{cases}
x_{\big(\frac{n+1}{2}\big)} & \text{si } n \text{ es impar} \\[6pt]
\dfrac{x_{\big(\frac{n}{2}\big)} + x_{\big(\frac{n}{2}+1\big)}}{2} & \text{si } n \text{ es par}
\end{cases}
$$

**Ejemplo impar (\(n=5\)):** precios \(1,\,2,\,3,\,4,\,100\).  
Posición del centro: \((5+1)/2 = 3\) → mediana \(= 3\). La media sería \(22\).

**Ejemplo par (\(n=4\)):** \(1,\,2,\,8,\,10\).  
Centro entre las posiciones 2 y 3 → mediana \(= (2+8)/2 = 5\).

**Analogía:** en una fila de 9 personas ordenadas por altura, la mediana es la persona número 5.  
Si al final de la fila llega un gigante de 2,50 m, **la persona del centro no se mueve**. La mediana **no se deja arrastrar** por un valor extremo.

#### Media (el promedio clásico)

$$
\text{media} = \frac{\text{suma de todos los precios}}{\text{cuántos precios hay}}
$$

**Analogía:** los mismos amigos de la sección 1.3 (2, 2, 2, 2 y 100 €). La media sube mucho por el 100.  
En una tienda online pasa lo mismo: muchos productos baratos y unos pocos carísimos → la **media** se infla; la **mediana** sigue describiendo mejor “lo típico”.

| Pregunta de negocio | Mejor resumen |
|---------------------|---------------|
| “¿Cuál es el precio **habitual**?” | **Mediana** |
| “¿Cuánto dinero **en total** / por ticket de media?” | **Media** (y a veces también la suma) |

#### Cómo se calcula la mediana en SQL (PostgreSQL)

No existe un `MEDIAN()` universal y simple en todos los motores. En PostgreSQL se usa el **percentil 0,50** (el 50 % de los valores queda por debajo):

```sql
SELECT
    PERCENTILE_CONT(0.50)                  -- Percentil 50 = mediana
    WITHIN GROUP (ORDER BY price)          -- Primero ordena los precios
    AS precio_mediana
FROM customers
WHERE event_type = 'purchase';              -- Solo compras reales
```

En el script Python del EX02 suele usarse algo equivalente con NumPy:

```python
np.percentile(array_de_precios, 50)   # mediana
np.mean(array_de_precios)             # media
```

**Qué recordar en defensa:**  
“La mediana es el centro de la lista ordenada; un outlier caro no la mueve como mueve a la media.”

---

### 4.2 Cuartiles (Q1, Q2, Q3)

Los **cuartiles** cortan la lista ordenada en **cuatro partes** con (aproximadamente) el mismo número de observaciones.

| Nombre | Percentil | Significado cotidiano |
|--------|-----------|------------------------|
| **Mínimo** | — | el valor más pequeño |
| **Q1** | 25 % | un cuarto de los datos son **menores o iguales** |
| **Q2** | 50 % | la **mediana** |
| **Q3** | 75 % | tres cuartos de los datos son **menores o iguales** |
| **Máximo** | — | el valor más grande |

**Analogía paso a paso:**  
Ordenas a 100 clientes por lo que gastaron.  
- Q1 ≈ el gasto del cliente número 25.  
- Q2 ≈ el del número 50 (mediana).  
- Q3 ≈ el del número 75.  

Entre Q1 y Q3 está la **mitad central** de los datos (el 50 % “más típico”).  
Eso es exactamente lo que dibuja la **caja** del box plot.

#### Fórmulas / código

En Python (como en `mustache.py`):

```python
q1 = np.percentile(arr, 25)
q2 = np.percentile(arr, 50)   # mediana
q3 = np.percentile(arr, 75)
```

En SQL (PostgreSQL), la idea es la misma con percentiles:

```sql
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) AS q1,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY price) AS mediana,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) AS q3
FROM customers
WHERE event_type = 'purchase';
```

**Rango intercuartílico (IQR):**

$$
\text{IQR} = Q3 - Q1
$$

Mide **anchura de la caja**: si Q1 y Q3 están muy lejos, los precios “normales” están muy dispersos.

**De dónde sale:** tras ordenar, Q1 es el valor bajo el cual queda ~25 % de los datos (percentil 25); Q3, ~75 %. Restar Q3 − Q1 mide solo la “franja central”, ignorando las colas extremas.

**Ejemplo:** precios ordenados \(1, 2, 3, 4, 5, 6, 7, 8, 9\).  
Aprox. Q1 ≈ 3, mediana ≈ 5, Q3 ≈ 7 → \(\mathrm{IQR} ≈ 4\). La caja iría de 3 a 7.

**Qué recordar en defensa:**  
“Q1–Q3 es la caja; dentro vive el 50 % central de los precios (o de las medias por cliente).”

---

### 4.3 Desviación típica (std)

La **desviación típica** (o *standard deviation*) resume, con un solo número, **cuánto se alejan** los valores de la **media**.

- Si casi todos los precios son parecidos → std **pequeña**.  
- Si hay de 0,40 ₳ a 300 ₳ → std **grande**.

**Analogía:** dos clases con media de nota 7.  
- En una, casi todos sacaron 6, 7 u 8 → poca dispersión.  
- En la otra, hay muchos 3 y muchos 10 → misma media, **mucha** dispersión.

#### Fórmula (población) y versión “muestra”

Primero se calcula la media \(\bar{x}\). Luego, para cada valor, se mide **cuánto se aparta** de esa media \((x_i - \bar{x})\).  
Esos apartados se **cuadran** (así no se cancelan positivos con negativos), se promedian y se hace la **raíz cuadrada** para volver a la unidad original (euros, ₳…):

$$
\sigma = \sqrt{\frac{1}{n}\sum_{i=1}^{n}(x_i - \bar{x})^2}
\quad\text{(población / a veces NumPy con }\texttt{ddof=0}\text{)}
$$

En estadística de **muestra** (estimar la dispersión de un conjunto mayor) suele usarse \(n-1\) en el denominador:

$$
s = \sqrt{\frac{1}{n-1}\sum_{i=1}^{n}(x_i - \bar{x})^2}
\quad\text{(muestra / }\texttt{ddof=1}\text{)}
$$

**Por qué al cuadrado (la idea de la derivación):**  
Si sumaras \((x_i - \bar{x})\) a pelo, lo que está por encima de la media y lo que está por debajo **se anularían** y obtendrías ~0 aunque hubiera mucha dispersión. Al cuadrar, todo aporta en positivo. La raíz final deshace el cambio de unidades (de “euros²” a “euros”).

**Ejemplo mínimo:** valores \(2, 4, 6\). Media \(= 4\).  
Apartados: \(-2,\, 0,\, +2\). Cuadrados: \(4,\, 0,\, 4\). Media de cuadrados \(= 8/3\).  
\(\sigma = \sqrt{8/3} \approx 1{,}63\).

En la defensa no hace falta calcularlo a mano; sí poder decir:  
*“es la raíz de la media de las distancias al cuadrado respecto a la media”*.

> “La std mide la dispersión alrededor de la media; junto con media y cuartiles describe la forma de los precios.”

En el EX02 el script imprime algo al estilo de `describe` de pandas:

| Campo | Significado |
|-------|-------------|
| `count` | cuántos valores |
| `mean` | media |
| `std` | desviación típica |
| `min` / `max` | extremos |
| `25%` / `50%` / `75%` | Q1, mediana, Q3 |

```python
# Idea equivalente en NumPy
np.std(arr)           # dispersión
np.mean(arr)          # media
np.percentile(arr, [25, 50, 75])
```

**Relación con el box plot:**  
La std **no** se dibuja como una marca fija en el mustache del subject, pero **explica** por qué la caja es ancha o estrecha y por qué la media puede alejarse de la mediana.

---

### 4.4 Box plot (“mustache”)

El box plot es un **dibujo resumen** de mínimo, Q1, mediana, Q3, máximo y (a veces) *outliers*.

```text
        |-----[====|====]-----|     •  •
      bigote  Q1  mediana Q3  bigote   outliers
```

| Parte del dibujo | Qué representa |
|------------------|----------------|
| **Caja** | de Q1 a Q3 (50 % central) |
| **Raya dentro de la caja** | mediana (Q2) |
| **Bigotes** | se alargan hasta valores aún “no extremos” (regla del programa / matplotlib) |
| **Puntos sueltos** | *outliers* (valores raros), si el script los muestra |

En este proyecto, los PNG principales del EX02 suelen ocultar outliers con `showfliers=False` (ver descripción de imágenes al inicio de esta sección 4). Eso **no borra** los outliers de los datos: solo deja el dibujo más limpio para la defensa.

#### Los dos box plots del subject

1. **Precios de ítem** (`box_plot_price.png`)  
   - Unidad de dato: cada `price` de una fila `purchase`.  
   - Pregunta: “¿cómo se distribuyen los precios de los productos comprados?”

2. **Cesta media por usuario** (`box_plot_average.png`)  
   - Paso A: por cada `user_id`, `AVG(price)` de sus compras.  
   - Paso B: box plot sobre **esas medias** (una por cliente).  
   - Pregunta: “¿cómo de ‘generoso’ es, de media, cada cliente?”

```sql
-- Idea de la cesta media por usuario (luego el box se hace en Python)
SELECT
    user_id,
    AVG(price) AS cesta_media
FROM customers
WHERE event_type = 'purchase'
GROUP BY user_id;
```

**Analogía final:**  
(1) miras el precio de **cada producto** en el ticket;  
(2) miras, por cada persona, **cuánto suele costar de media** lo que compra.

`mustache_python.png` y `mustache_diagrama_flujo.png` son material explicativo del código/proceso, **no** los dos box plots de entrega.

[↑ Volver al índice](#indice)

---

## 5. EX03 – Histogramas: frequency y monetary {#ex03}

Un **histograma** no ordena el tiempo (como EX01). Ordena **cuántos clientes** caen en cada **cajón (bin)** de una variable.

**Analogía global:** clasificas a los socios de un gimnasio por “veces al mes” o por “cuánto pagan al año” y levantas un **edificio** por cada rango. La altura del edificio = cuántas personas hay en ese rango.

### 5.1 Frequency (frecuencia de compra)

**Pregunta:** ¿cuántas veces ha comprado cada cliente, y cómo se reparte eso en la base?

**Pasos (con paciencia):**

1. Filtra solo `purchase`.
2. Por cada `user_id`, cuenta sus compras → un entero (1, 2, 15, 40…).
3. Mete ese entero en un **bin** (cajón), por ejemplo en este proyecto:

| Bin (etiqueta) | Frecuencia de compra (idea del script) |
|----------------|------------------------------------------|
| `0-10` | pocas compras (p. ej. 1…9, según cortes exactos del código) |
| `10-20` | frecuencia media-baja |
| `20-30` | frecuencia media-alta |
| `30+` | clientes muy recurrentes (30 o más) |

4. Cada **barra** del gráfico = **número de clientes** en ese cajón (no el número de tickets).

```sql
-- Idea: compras por cliente (luego se agrupan en bins en Python)
SELECT
    user_id,
    COUNT(*) AS n_compras
FROM customers
WHERE event_type = 'purchase'
GROUP BY user_id;
```

**PNG típico:** el de “edificios” de frequency del EX03 (`building_frequency` / nombre equivalente en `ex03/`).

**Qué suele verse:** barra **más alta a la izquierda** (muchos compran pocas veces) y **cola a la derecha** (pocos muy fieles).

### 5.2 Monetary (gasto total por cliente)

Misma lógica, otra variable:

1. Por cada `user_id`: `SUM(price)` de sus `purchase` → gasto total.  
2. Bins de dinero, p. ej. `0-50`, `50-100`, `100-150`, `150-200`, `200+` (₳).  
3. Altura de la barra = cuántos clientes cayeron en ese rango de gasto.

```sql
SELECT
    user_id,
    SUM(price) AS gasto_total
FROM customers
WHERE event_type = 'purchase'
GROUP BY user_id;
```

**Analogía:** frequency = “¿cuántas veces vino al bar?”; monetary = “¿cuánto se dejó en total?”.

### Por qué se parecen a “edificios” (Highest Building)

- Barras altas a la **izquierda** → la masa de la base es ocasional / gasta poco.  
- Cola a la **derecha** → minoría intensiva o de alto valor.  

Eso es **información de negocio** (quién merece campaña de activación vs quién es VIP), no solo un dibujo.

**Puente al EX04:** frequency y monetary (junto con la recencia) son la materia prima del **RFM**.

[↑ Volver al índice](#indice)

---

## 6. RFM – Tres números por cliente {#rfm}

Antes de “agrupar clientes parecidos” (EX04–EX05), cada persona se resume en **tres medidas** clásicas. No hace falta memorizar la sigla: basta entender las tres preguntas.

| Letra | Nombre en inglés | Pregunta en cristiano | Ejemplo de cálculo (solo `purchase`) |
|-------|------------------|------------------------|--------------------------------------|
| **R** | *Recency* | ¿Hace **cuánto** compró por última vez? | Días (o distancia temporal) desde el último `purchase` |
| **F** | *Frequency* | ¿**Cuántas veces** ha comprado? | `COUNT(*)` por `user_id` |
| **M** | *Monetary* | ¿**Cuánto dinero** ha dejado? | `SUM(price)` por `user_id` |

**Analogía del bar de siempre:**  
De cada cliente anotas: “¿cuándo vino la última vez?”, “¿cuántas veces al mes suele venir?” y “¿cuánto se gasta?”. Con solo eso ya puedes separar al que viene cada día y deja mucho del que no aparece desde hace meses.

#### Fórmulas RFM (esquema)

Fijada una fecha de referencia \(t_{\mathrm{ref}}\) (p. ej. el último día del dataset o “hoy”):

$$
\begin{aligned}
R_u &= t_{\mathrm{ref}} - \max\{ t : \text{compra del usuario } u \text{ en } t \} \\
F_u &= \#\{ \text{compras del usuario } u \} = \mathrm{COUNT}(*)_u \\
M_u &= \sum \text{price de las compras de } u = \mathrm{SUM}(\texttt{price})_u
\end{aligned}
$$

- \(R_u\) **grande** → lleva mucho tiempo sin comprar (más “frío”).  
- \(F_u\) **grande** → compra a menudo.  
- \(M_u\) **grande** → deja más dinero.

En el código, a veces \(R\) se expresa en días enteros; lo importante es que **más recencia numérica** signifique lo mismo para todos los clientes.

#### Esquema SQL (idea)

```sql
SELECT
    user_id,
    MAX(event_time) AS ultima_compra,   -- base de la recencia
    COUNT(*)        AS frequency,       -- F
    SUM(price)      AS monetary         -- M
FROM customers
WHERE event_type = 'purchase'
GROUP BY user_id;
```

La **recencia** se convierte después en un número (p. ej. días hasta una fecha de referencia).  
Con **tres columnas numéricas por cliente** ya se puede:

1. dibujar histogramas (EX03),  
2. escalar y agrupar con K-Means (EX04–EX05).

**Qué recordar en defensa:**  
“RFM no es magia: son tres resúmenes por cliente para poder compararlos en igualdad de condiciones.”

[↑ Volver al índice](#indice)

---

## 7. EX04 – Escalado, K-Means e inertia (codo) {#ex04}

### 7.1 ¿Por qué escalar? (`StandardScaler`)

R, F y M **no hablan el mismo idioma**:

| Variable | Unidades típicas | Orden de magnitud habitual |
|----------|------------------|----------------------------|
| Recency | días | decenas o cientos |
| Frequency | conteos | unidades o decenas |
| Monetary | dinero (₳) | puede ser cientos o miles |

**Analogía:** comparar alturas en **metros** con pesos en **gramos**. Sin convertir, el peso “gana” siempre porque los números son más gordos, aunque no sea lo más importante.

`StandardScaler` (scikit-learn) transforma cada columna para que, a grandes rasgos:

- la **media** quede cerca de 0,  
- la **dispersión** quede cerca de 1.

Así K-Means no se obsesiona solo con la variable de números más grandes.

**Qué recordar:** escalar **no inventa** clientes nuevos; solo pone las tres reglas del juego en la misma pista.

#### Fórmula del z-score (lo que hace, en esencia, StandardScaler)

Para cada valor \(x\) de una columna (p. ej. monetary de un cliente):

$$
z = \frac{x - \mu}{\sigma}
$$

| Símbolo | Significado |
|---------|-------------|
| \(x\) | valor original (p. ej. 120 ₳ de gasto) |
| \(\mu\) | media de **esa** columna en todos los clientes |
| \(\sigma\) | desviación típica de esa columna |
| \(z\) | valor **escalado** |

- Si \(x = \mu\) → \(z = 0\) (cliente “en la media” de esa variable).  
- Si \(x\) está una desviación por encima → \(z \approx +1\).  
- Si está muy por debajo → \(z\) negativo.

**Ejemplo:** frequency media 5, std 3. Un cliente con 11 compras → \(z = (11-5)/3 = 2\).  
Otro con 2 compras → \(z = (2-5)/3 = -1\).

Después del escalado, R, F y M viven en escalas comparables y la **distancia** entre clientes tiene sentido para K-Means.

---

### 7.2 K-Means en una frase (y luego con paciencia)

**Objetivo:** partir a los clientes en **k grupos** de forma que, dentro de cada grupo, se parezcan entre sí (en el espacio RFM escalado).

**Pasos del algoritmo (idea):**

1. Eliges **k** = cuántos grupos quieres (1, 2, 3, …).  
2. Se colocan **k centros** (*centroides*), al inicio de forma más o menos aleatoria (con semilla reproducible en el proyecto).  
3. Cada cliente se asigna al centro **más cercano** (distancia en el espacio escalado).  
4. Cada centro se **mueve** al “centro de gravedad” de los clientes que le tocaron.  
5. Se repite 3–4 hasta que las asignaciones casi no cambian.

**Analogía de las chinchetas:**  
En un mapa de puntos (clientes), clavas k chinchetas. Cada punto se queda con la chincheta más cercana. Luego mueves cada chincheta al centro de “sus” puntos, y vuelves a repartir. Al final, las chinchetas marcan los grupos.

#### Distancia al centro (idea euclídea)

En el espacio RFM escalado, un cliente es un punto \((z_R, z_F, z_M)\) y un centroide es \((c_R, c_F, c_M)\). La distancia “en línea recta” es:

$$
d = \sqrt{(z_R - c_R)^2 + (z_F - c_F)^2 + (z_M - c_M)^2}
$$

**Analogía:** en un mapa 2D (solo norte-sur y este-oeste) es el teorema de Pitágoras; aquí hay **tres** ejes (R, F, M), pero la idea es la misma: sumar cuadrados de diferencias y raíz.

K-Means asigna cada cliente al centroide con **menor** \(d\).

---

### 7.3 Inertia (WCSS)

Para un **k** concreto, la *inertia* (a veces llamada WCSS: *Within-Cluster Sum of Squares*) mide cuánto de **desparramados** están los puntos respecto a **su** centro:

- Grupos **compactos** → inertia **baja**.  
- Grupos **mezclados / alargados** → inertia **alta**.

#### Fórmula

Sea \(C_j\) el conjunto de clientes del grupo \(j\), y \(c_j\) su centroide. Para cada cliente \(x\) del grupo se mira la distancia al cuadrado a su centro y se **suma todo**:

$$
\mathrm{Inertia}(k) = \sum_{j=1}^{k}\ \sum_{x \in C_j}\ \| x - c_j \|^2
$$

\(\| x - c_j \|^2\) es justo el cuadrado de la distancia euclídea de la sección anterior (sin la raíz, porque al cuadrado ya basta para sumar errores).

- **Un solo grupo (\(k=1\)):** un único centro (la media global) → inertia alta si los clientes son muy distintos.  
- **Muchos grupos:** cada centro “abarca” menos puntos → la suma de errores **baja**.

Por eso la curva del codo **decrece** al subir \(k\); el truco es encontrar dónde **deja de bajar de forma útil**.

**Importante:** si **subes k**, la inertia **casi siempre puede bajar** un poco (más chinchetas → cada punto puede estar más cerca de alguna).  
El extremo absurdo sería **un grupo por cliente**: inertia casi 0, pero **sin ningún valor de negocio**.

Por eso **no** se elige el k con la inertia mínima a ciegas.

---

### 7.4 Método del codo (*Elbow Method*)

Se construye una curva:

| Eje | Qué representa |
|-----|----------------|
| **X** | \(k = 1, 2, 3, \ldots, 10\) (en este proyecto) |
| **Y** | inertia obtenida con ese k |

Comportamiento típico:

1. Al principio la curva **cae fuerte** (pasar de 1 a 2, de 2 a 3… aporta mucho).  
2. Luego **se aplana**: añadir otro grupo ya no mejora tanto.

La zona donde “deja de compensar” es el **codo**.

**Analogía:** al doblar el brazo, el **codo** es el cambio de dirección; más allá el antebrazo sigue, pero el pliegue principal ya pasó.

**PNG típico:** `elbow_method.png` en `ex04/`.

---

### 7.5 Elegir k = 5 en este repo

Hay que separar **tres capas** de decisión:

| Capa | Qué dice |
|------|----------|
| **Subject EX05** | al menos **4** perfiles de negocio (p. ej. nuevos, inactivos, loyal…) |
| **Curva del codo** | la caída fuerte suele estar hacia k ≈ 3–5; después se suaviza |
| **Este proyecto** | `SELECTED_K = 5` (cinco segmentos: p. ej. new, inactive, silver, gold, platinum) |

**k = 5 no es un dogma del PDF:** es una **elección defendible** (codo + necesidad de varios perfiles).  
En defensa hay que **explicar** por qué no 2 (demasiado grueso) ni 9 (sobre-partir sin interpretación clara).

[↑ Volver al índice](#indice)

---

## 8. EX05 – Mismos grupos, lectura de negocio {#ex05}

### Matemáticamente (misma tubería que EX04)

1. Mismo RFM (solo `purchase`).  
2. Mismo tipo de escalado (`StandardScaler`).  
3. **Mismo k** que en EX04 (la hoja de evaluación lo exige).  
4. K-Means asigna a cada cliente un número de grupo \(0, 1, \ldots, k-1\).  
5. **Vosotros** traducís esos números a etiquetas de negocio (`new`, `inactive`, `silver`, `gold`, `platinum`, …).

Si el k de EX05 no coincide con el de EX04, la coherencia del módulo se rompe a ojos de la evaluación.

### Qué muestran los gráficos

| Tipo de gráfico | Pregunta que responde |
|-----------------|------------------------|
| **Barras de tamaño** (`customers_per_cluster`, etc.) | ¿Cuántos clientes hay en cada segmento? |
| **Plano frequency vs monetary** (u otra proyección) | ¿Se **separan** de verdad los grupos en comportamiento? |

**Analogía:** no basta decir “hay cinco cajones”. Hay que poder decir:

- **quién** hay en cada cajón (recién llegado, dormido, VIP…),  
- **para qué email o acción** serviría (bienvenida, cupón de retorno, trato premium…).

### Qué pedir en defensa (checklist mental)

- [ ] Mismo k que el codo / EX04  
- [ ] Al menos dos gráficos  
- [ ] Una frase de negocio por grupo (no solo “cluster 0, 1, 2”)  
- [ ] Relación con RFM (por qué ese grupo tiene poca frecuencia o mucho gasto)

[↑ Volver al índice](#indice)

---

## 9. Mini glosario {#glosario}

| Término | En una línea |
|---------|----------------|
| **Agregación** | Resumir muchas filas en un número (suma, conteo, media). |
| **Bin / cajón** | Intervalo donde agrupas valores para un histograma. |
| **Centroide** | “Centro” de un grupo en K-Means. |
| **Cluster** | Grupo de clientes parecidos según el algoritmo. |
| **Distribución** | Cómo se reparte un conjunto de valores (muchos bajos, pocos altos…). |
| **Histograma** | Barras que cuentan cuántos caen en cada cajón. |
| **Inertia (WCSS)** | Suma de “lejanías” de los puntos a su centro; baja = grupos compactos. |
| **IQR** | \(Q3 - Q1\); anchura de la caja del box plot. |
| **Mediana** | Valor central de la lista ordenada; resistente a outliers. |
| **Outlier** | Valor raro, muy lejos del resto. |
| **Percentil** | Umbral bajo el cual queda un % de los datos (p. ej. 50 % = mediana). |
| **Proporción** | Parte / total (base del pie chart). |
| **RFM** | Recency, Frequency, Monetary. |
| **Scaler** | Transformación para que variables distintas sean comparables. |
| **Std** | Desviación típica; dispersión alrededor de la media. |

[↑ Volver al índice](#indice)

---

## 10. Cómo usarlo en la defensa {#defensa}

No hace falta recitar fórmulas. Sí poder decir, con calma y mirando el PNG:

1. **EX00:** “Cuento eventos por `event_type` y cada porción del pie es conteo / total.”  
2. **EX01:** “Solo `purchase`; `DISTINCT` para personas; `SUM` para dinero; media diaria = dinero / personas.”  
3. **EX02:** “Mediana = centro de la lista ordenada; la caja es Q1–Q3; un box es precios de ítem y el otro medias por cliente.”  
4. **EX03:** “Un número por cliente (veces o dinero), cajones (bins), altura de la barra = cuántos clientes.”  
5. **EX04:** “Escalo RFM para igualar unidades, pruebo varios k, miro dónde se aplana la inertia y elijo k justificándolo.”  
6. **EX05:** “Mismo k que EX04; cada grupo es un tipo de cliente con lectura de negocio y al menos dos gráficos.”

### Relacionado en este repo

| Recurso | Rol |
|---------|-----|
| `ex0N/python.md` | Cómo está escrito el código |
| `ex0N/README.md` | Subject, defensa, checklist del ejercicio |
| `evaluation.sh` | Guía de defensa (no es entregable del subject) |
| `mates.md` | Este documento: las **cuentas** detrás de los gráficos |

---

*mates.md · Module 2 Data Viz · material de apoyo · no sustituye en.subject.pdf*  
*sternero – 42 Málaga*
