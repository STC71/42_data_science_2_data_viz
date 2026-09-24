#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EX04 – elbow.py
Module 2 – Data Viz – Piscine Data Science

================================================================================
SUBJECT (Elbow)
================================================================================
  Your Boss wants groups of customer type for commercial targeting (e-mails).

  • Make an Elbow Method to understand the 'optimal' number of clusters.
  • You have to be able to explain how many clusters you choose and why.

  Turn-in directory : ex04/
  Files to turn in  : elbow.*

================================================================================
QUÉ HACE ESTE SCRIPT (lectura humana)
================================================================================
  1) Se conecta al Data Warehouse (tabla customers del Module 1).
  2) Resume CADA cliente con tres números (RFM):
       R – Recency:   días desde la última compra
       F – Frequency: cuántas veces ha comprado
       M – Monetary:  cuánto ha gastado en total (₳)
  3) Pone esas tres medidas en la misma escala (StandardScaler),
     para que “días” no compitan en desigualdad con “euros”.
  4) Prueba KMeans con k = 1, 2, …, 10 y anota la inertia (error interno).
  5) Dibuja inertia frente a k → curva del codo (“The Elbow Method”).
  6) Sugiere un k (heurística + suelo 4, porque EX05 pide ≥ 4 grupos).

Analogía:
  Como decidir cuántas baldas pone una tienda para ordenar clientes:
  demasiadas baldas = caos operativo; pocas = mezclas raras.
  El codo marca el compromiso razonable.

Uso:
  python3 elbow.py
  MPLBACKEND=Agg python3 elbow.py
"""

from __future__ import annotations
# annotations: permite tipos como Path | None en firmas modernas.

import os
# os: variables de entorno (POSTGRES_*, USER, DISPLAY, MPLBACKEND).
import sys
# sys: salida de errores y sys.exit ante fallos irrecuperables.
import warnings
# warnings: silenciar avisos ruidosos de matplotlib en el campus.
from pathlib import Path
# Path: rutas portables al .env de Module 0 y a los PNG de salida.

# Avisos típicos en sesión gráfica / backends del cluster.
warnings.filterwarnings("ignore", message=r"Unable to import Axes3D.*")
warnings.filterwarnings("ignore", message=r"FigureCanvasAgg is non-interactive.*")
warnings.filterwarnings(
    "ignore",
    category=UserWarning,
    module=r"matplotlib(\..*)?",
)
# En el campus, el SciPy del sistema (apt) pide NumPy < 1.25, pero el stack
# gráfico estable de la piscine usa NumPy 1.26.x (--user / .venv). El aviso
# "A NumPy version >= … and < 1.25.0 is required for this version of SciPy"
# no impide KMeans ni el plot; solo ensucia la consola. Se silencia a propósito.
warnings.filterwarnings(
    "ignore",
    message=r"A NumPy version .* is required for this version of SciPy.*",
)

# ---------------------------------------------------------------------------
# Dependencias (campus 42: a menudo hay que instalar en --user o .venv)
# ---------------------------------------------------------------------------


def _pip(cmd_packages: list[str], user: bool = True) -> None:
    """Ejecuta pip install (por defecto --user, sin sudo)."""
    import subprocess

    cmd = [sys.executable, "-m", "pip", "install"]
    if user:
        cmd.append("--user")
    cmd.extend(cmd_packages)
    print("→", " ".join(cmd))
    subprocess.check_call(cmd)


def _prefer_paths(paths: list[str]) -> None:
    """Antepone rutas de site-packages al sys.path (user o .venv)."""
    for path in reversed(paths):
        if path and path not in sys.path:
            sys.path.insert(0, path)


def _purge_numpy_matplotlib() -> None:
    """
    Borra de sys.modules numpy/matplotlib/sklearn a medias.
    Útil tras un pip --force-reinstall incompleto en la misma sesión.
    """
    for name in list(sys.modules):
        if (
            name == "numpy"
            or name.startswith("numpy.")
            or name == "matplotlib"
            or name.startswith("matplotlib.")
            or name == "sklearn"
            or name.startswith("sklearn.")
        ):
            del sys.modules[name]


def _stack_works() -> bool:
    """
    Comprueba que el stack numérico + gráficos + KMeans es usable.
    Importante: NO fijar aquí matplotlib.use("Agg") o se bloquea la ventana
    para todo el proceso aunque exista DISPLAY.
    """
    try:
        import numpy as np
        from numpy.linalg import eigvals

        eigvals(np.eye(2))  # detecta NumPy roto tras downgrades raros
        import matplotlib.pyplot as plt
        from sklearn.cluster import KMeans

        fig, ax = plt.subplots()
        ax.plot([1, 2, 3], [3, 2, 1])
        plt.close(fig)
        _ = KMeans(n_clusters=2, n_init=10, random_state=42)
        return True
    except Exception as exc:
        print(f"⚠ stack no OK: {type(exc).__name__}: {exc}")
        return False


def ensure_dependencies() -> None:
    """
    Garantiza psycopg2, dotenv, numpy, matplotlib y scikit-learn.
    Estrategia (igual que en otros ejercicios de la piscine):
      1) Preferir paquetes ya instalados / .venv del Module 2
      2) pip install --user de lo que falte
      3) Si el stack sigue roto → force-reinstall controlado
      4) Último recurso: crear Module2/.venv y pedir relanzar con ese python
    """
    import importlib.util
    import site
    import subprocess
    from pathlib import Path as PathLib

    module2 = PathLib(__file__).resolve().parent.parent
    venv_python = module2 / ".venv" / "bin" / "python"
    venv_sites = list((module2 / ".venv").glob("lib/python*/site-packages"))
    if venv_python.is_file() and PathLib(sys.executable).resolve() != venv_python.resolve():
        _prefer_paths([str(p) for p in venv_sites])
    try:
        _prefer_paths([site.getusersitepackages()])
    except Exception:
        pass

    # módulo importable → nombre del paquete pip
    for mod, pkg in {
        "psycopg2": "psycopg2-binary",
        "dotenv": "python-dotenv",
        "sklearn": "scikit-learn",
    }.items():
        if importlib.util.find_spec(mod) is None:
            _pip([pkg], user=True)

    if _stack_works():
        return

    print("→ Reparando numpy / matplotlib / scikit-learn...")
    try:
        _pip(
            [
                "--force-reinstall",
                "--no-cache-dir",
                "numpy==1.26.4",
                "matplotlib",
                "scikit-learn",
            ],
            user=True,
        )
    except subprocess.CalledProcessError as exc:
        print("pip falló:", exc, file=sys.stderr)
    _purge_numpy_matplotlib()
    try:
        _prefer_paths([site.getusersitepackages()])
    except Exception:
        pass
    if _stack_works():
        return

    # .venv local al Module 2 (evita pelearse con el Python del sistema)
    venv_dir = module2 / ".venv"
    print(f"→ Creando .venv: {venv_dir}")
    try:
        subprocess.check_call([sys.executable, "-m", "venv", str(venv_dir)])
        pip = str(venv_dir / "bin" / "pip")
        subprocess.check_call(
            [
                pip,
                "install",
                "--upgrade",
                "pip",
                "numpy==1.26.4",
                "matplotlib",
                "scikit-learn",
                "psycopg2-binary",
                "python-dotenv",
            ]
        )
    except subprocess.CalledProcessError as exc:
        print("No se pudo crear .venv:", exc, file=sys.stderr)
        sys.exit(1)
    print(
        f"\n✓ .venv listo. Relanza:\n  {venv_dir}/bin/python {PathLib(__file__).resolve()}\n",
        file=sys.stderr,
    )
    sys.exit(0)


ensure_dependencies()

import matplotlib

# Solo Agg si no hay DISPLAY ni MPLBACKEND ya elegido (cluster / SSH sin X).
if not os.environ.get("MPLBACKEND") and not os.environ.get("DISPLAY"):
    matplotlib.use("Agg")

import matplotlib.pyplot as plt
import numpy as np
import psycopg2
from dotenv import load_dotenv
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

SCRIPT_DIR = Path(__file__).resolve().parent
MODULE2_DIR = SCRIPT_DIR.parent

# Rango de k como en la figura del PDF del subject (1…10).
K_MIN = 1
K_MAX = 10
# Semilla fija: mismos centroides iniciales → resultados reproducibles en defensa.
RANDOM_STATE = 42

# ---------------------------------------------------------------------------
# SQL RFM
# ---------------------------------------------------------------------------
# Un cliente = una fila. Solo event_type = 'purchase'.
# recency_days: días entre “ahora” y la última compra (menor = más reciente).
# frequency:    número de compras.
# monetary:     suma de price (puede incluir precios negativos del dataset).
#
SQL_RFM = """
SELECT
    user_id,
    EXTRACT(EPOCH FROM (MAX(event_time) - MIN(event_time))) / 86400.0
        AS span_days,
    COUNT(*)::float AS frequency,
    COALESCE(SUM(price), 0)::float AS monetary,
    EXTRACT(EPOCH FROM (NOW() - MAX(event_time))) / 86400.0
        AS recency_days
FROM customers
WHERE event_type = 'purchase'
  AND event_time IS NOT NULL
GROUP BY user_id
HAVING COUNT(*) >= 1;
"""


def find_env_file() -> Path | None:
    """
    Busca el .env de Module 0 (ex00) en rutas típicas del monorepo / sgoinfre.
    Misma idea que en pie.py / Building.py: un solo origen de credenciales.
    """
    login = os.environ.get("USER") or ""
    candidates = [
        MODULE2_DIR.parent / "data_science_0_creation_db" / "ex00" / ".env",
        (MODULE2_DIR / ".." / "data_science_0_creation_db" / "ex00" / ".env").resolve(),
        Path.home()
        / "sgoinfre"
        / "42_outer_core"
        / "piscine_pedago_data_science"
        / "data_science_0_creation_db"
        / "ex00"
        / ".env",
        Path.home()
        / "sgoinfre"
        / "students"
        / login
        / "42_outer_core"
        / "piscine_pedago_data_science"
        / "data_science_0_creation_db"
        / "ex00"
        / ".env",
    ]
    for path in candidates:
        try:
            path = path.resolve()
        except OSError:
            continue
        if path.is_file():
            return path
    return None


ENV_PATH = find_env_file()
if ENV_PATH is not None:
    load_dotenv(ENV_PATH)
    print(f"→ .env: {ENV_PATH}")
else:
    print("→ .env no encontrado; valores por defecto")

DB_CONFIG = {
    "host": os.environ.get("POSTGRES_HOST", "localhost"),
    "port": int(os.environ.get("POSTGRES_PORT", "5432")),
    "dbname": os.environ.get("POSTGRES_DB", "piscineds"),
    "user": os.environ.get("POSTGRES_USER", os.environ.get("USER", "")),
    "password": os.environ.get("POSTGRES_PASSWORD", "mysecretpassword"),
}


def fetch_rfm(conn) -> np.ndarray:
    """
    Devuelve una matriz (n_usuarios × 3) con columnas:
      [0] recency_days
      [1] frequency
      [2] monetary

    Analogía: cada fila es la “ficha” de un cliente en tres casillas.
    """
    with conn.cursor() as cur:
        cur.execute(SQL_RFM)
        rows = cur.fetchall()
    if not rows:
        return np.empty((0, 3), dtype=float)
    # Orden de columnas en el SELECT:
    # 0 user_id | 1 span_days | 2 frequency | 3 monetary | 4 recency_days
    data = np.array(
        [[float(r[4]), float(r[2]), float(r[3])] for r in rows],
        dtype=float,
    )
    # nan_to_num: evita que un NULL suelto tumbe KMeans.
    data = np.nan_to_num(data, nan=0.0, posinf=0.0, neginf=0.0)
    return data


def elbow_inertias(X: np.ndarray, k_min: int, k_max: int) -> list[float]:
    """
    Para cada k en [k_min, k_max]:
      1) Escala X (fit_transform del StandardScaler UNA vez fuera del bucle
         sería aún más limpio; aquí se escala antes del bucle en main… —
         en esta función recibimos X ya listo o lo escalamos aquí).

    Implementación: escalamos dentro para que la función sea autosuficiente.

    inertia_ (WCSS): suma de distancias al cuadrado de cada punto a su
    centroide. Baja al subir k; el codo es donde la bajada se suaviza.
    """
    scaler = StandardScaler()
    Xs = scaler.fit_transform(X)
    inertias: list[float] = []
    for k in range(k_min, k_max + 1):
        model = KMeans(
            n_clusters=k,
            n_init=10,  # varias inicializaciones; se queda la mejor
            random_state=RANDOM_STATE,
        )
        model.fit(Xs)
        inertias.append(float(model.inertia_))
        print(f"  k={k:2d}  inertia={model.inertia_:,.1f}")
    return inertias


def suggest_k(inertias: list[float], k_min: int) -> int:
    """
    Heurística simple de codo:
      - Calcula la 2ª diferencia discreta de la serie de inertias
        (cambio en la pendiente).
      - Toma el índice de mayor curvatura como candidato.
      - Si el candidato es < 4, sube a 4 (coherencia con EX05).

    No sustituye el juicio en defensa: es una ayuda cuantitativa.
    """
    if len(inertias) < 3:
        return k_min + len(inertias) - 1
    d1 = np.diff(inertias)  # primeras diferencias (caídas)
    d2 = np.diff(d1)  # segundas diferencias (cambio de pendiente)
    idx = int(np.argmax(d2)) + 1
    k = k_min + idx
    if k < 4:
        k = 4
    return k


def plot_elbow(ks: list[int], inertias: list[float], chosen: int, out: Path) -> None:
    """
    Dibuja la curva del subject (“The Elbow Method”) y la guarda en PNG.
    La línea vertical roja marca el k sugerido (argumento visual en defensa).
    """
    fig, ax = plt.subplots(figsize=(8, 4.8), layout="constrained")
    ax.plot(ks, inertias, marker="o", color="#4C78A8", linewidth=1.5)
    ax.axvline(
        chosen,
        color="#E45756",
        linestyle="--",
        alpha=0.8,
        label=f"k sugerido = {chosen}",
    )
    ax.set_xlabel("Number of clusters")
    ax.set_ylabel("Inertia (WCSS)")
    ax.set_title("The Elbow Method")
    ax.set_xticks(ks)
    ax.grid(True, alpha=0.35)
    ax.legend(loc="upper right")
    fig.savefig(out, dpi=150, bbox_inches="tight", pad_inches=0.15, facecolor="white")
    print(f"→ Guardado: {out}")
    plt.show()
    plt.close(fig)


def main() -> None:
    """Punto de entrada: RFM → inertias → gráfico → mensaje de k."""
    print("EX04 – Elbow Method")
    print("Features: Recency · Frequency · Monetary (purchase / user_id)")
    print()

    try:
        conn = psycopg2.connect(**DB_CONFIG)
    except psycopg2.Error as exc:
        print("Error de conexión:", exc, file=sys.stderr)
        sys.exit(1)

    try:
        X = fetch_rfm(conn)
    except psycopg2.Error as exc:
        print("Error SQL:", exc, file=sys.stderr)
        sys.exit(1)
    finally:
        conn.close()

    if X.shape[0] < K_MAX:
        print(
            f"Pocos usuarios ({X.shape[0]}) para explorar k hasta {K_MAX}.",
            file=sys.stderr,
        )
        sys.exit(1)

    print(f"Usuarios (RFM): {X.shape[0]:,}")
    print(f"Features: recency_days, frequency, monetary  shape={X.shape}")
    print()
    print(
        f"KMeans k={K_MIN}…{K_MAX} "
        f"(StandardScaler, n_init=10, seed={RANDOM_STATE})"
    )
    inertias = elbow_inertias(X, K_MIN, K_MAX)
    ks = list(range(K_MIN, K_MAX + 1))
    chosen = suggest_k(inertias, K_MIN)

    print()
    print("-" * 48)
    print(f"  k sugerido (heurística + EX05 ≥ 4):  {chosen}")
    print("  Criterio: codo en la curva inertia vs k;")
    print("  EX05 pide al menos 4 grupos (new / inactive / loyalty…).")
    print("-" * 48)
    print()

    # Un solo PNG en la raíz de ex04/ (evita generar el mismo gráfico dos veces).
    plot_elbow(ks, inertias, chosen, SCRIPT_DIR / "elbow_method.png")
    print("Proceso terminado.")


if __name__ == "__main__":
    main()
