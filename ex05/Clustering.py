#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EX05 – Clustering.py
Module 2 – Data Viz – Piscine Data Science

================================================================================
SUBJECT (Clustering)
================================================================================
  Your boss wants groups of customers for e-mail targeting
  (welcome offers, win-back coupons, loyalty gold/silver/platinum …).

  • Make at least 4 groups (new, inactive, loyalty: gold + silver + platinum …)
  • Use a Clustering algorithm
  • Make graphic representations of the groups (minimum 2)

  Turn-in directory : ex05/
  Files to turn in  : Clustering.*

================================================================================
ENFOQUE
================================================================================
  1) RFM por user_id (solo purchase) — misma idea que EX04.
  2) StandardScaler + KMeans (k = 5 ≥ 4 del subject).
  3) Etiquetas de negocio según centroides (no nombres aleatorios).
  4) Al menos 2 gráficos: tamaños de grupo + scatter Frequency × Monetary.

Analogía:
  Como ordenar la clientela de una tienda en estanterías con cartelitos
  (nuevos, dormidos, plata, oro, platino) para mandar el correo adecuado.
"""

from __future__ import annotations

import os
import sys
import warnings
from pathlib import Path

warnings.filterwarnings("ignore", message=r"Unable to import Axes3D.*")
warnings.filterwarnings("ignore", message=r"FigureCanvasAgg is non-interactive.*")
warnings.filterwarnings(
    "ignore",
    category=UserWarning,
    module=r"matplotlib(\..*)?",
)
# SciPy del sistema (apt) vs NumPy 1.26 del stack de la piscine — mismo aviso que EX04.
warnings.filterwarnings(
    "ignore",
    message=r"A NumPy version .* is required for this version of SciPy.*",
)

# ---------------------------------------------------------------------------
# Dependencias
# ---------------------------------------------------------------------------


def _pip(cmd_packages: list[str], user: bool = True) -> None:
    import subprocess

    cmd = [sys.executable, "-m", "pip", "install"]
    if user:
        cmd.append("--user")
    cmd.extend(cmd_packages)
    print("→", " ".join(cmd))
    subprocess.check_call(cmd)


def _prefer_paths(paths: list[str]) -> None:
    for path in reversed(paths):
        if path and path not in sys.path:
            sys.path.insert(0, path)


def _purge_stack() -> None:
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
    try:
        import numpy as np
        from numpy.linalg import eigvals

        eigvals(np.eye(2))
        import matplotlib.pyplot as plt
        from sklearn.cluster import KMeans

        fig, ax = plt.subplots()
        ax.plot([1, 2, 3], [1, 2, 3])
        plt.close(fig)
        _ = KMeans(n_clusters=2, n_init=10, random_state=42)
        return True
    except Exception as exc:
        print(f"⚠ stack no OK: {type(exc).__name__}: {exc}")
        return False


def ensure_dependencies() -> None:
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
    _purge_stack()
    try:
        _prefer_paths([site.getusersitepackages()])
    except Exception:
        pass
    if _stack_works():
        return
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

# k ≥ 4 del subject; 5 permite new + inactive + silver + gold + platinum
N_CLUSTERS = 5
RANDOM_STATE = 42
# Muestra en el scatter (todos los puntos saturan el PNG)
SCATTER_SAMPLE = 25_000

SQL_RFM = """
SELECT
    user_id,
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

# Orden de lectura legible en tablas
BUSINESS_ORDER = (
    "new_customer",
    "inactive_customer",
    "silver",
    "gold",
    "platinum",
)


def find_env_file() -> Path | None:
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


def fetch_rfm(conn) -> tuple[np.ndarray, np.ndarray]:
    """
    Returns
    -------
    user_ids : shape (n,)
    X : shape (n, 3) columns [recency_days, frequency, monetary]
    """
    with conn.cursor() as cur:
        cur.execute(SQL_RFM)
        rows = cur.fetchall()
    if not rows:
        return np.array([]), np.empty((0, 3), dtype=float)
    user_ids = np.array([r[0] for r in rows])
    # SQL: user_id, frequency, monetary, recency_days
    X = np.array(
        [[float(r[3]), float(r[1]), float(r[2])] for r in rows],
        dtype=float,
    )
    X = np.nan_to_num(X, nan=0.0, posinf=0.0, neginf=0.0)
    return user_ids, X


def assign_business_labels(
    centroids_original: np.ndarray,
) -> dict[int, str]:
    """
    Map cluster_id → etiqueta de negocio a partir del centroide en escala real
    (columnas: recency_days, frequency, monetary).

    Estrategia en dos pasos (más alineada con marketing que solo “min F”):

      1) Loyalty (silver / gold / platinum)
         Los 3 centroides con mayor monetary (gasto típico del grupo).
         Dentro de ellos, orden monetary ascendente → silver < gold < platinum.

      2) new vs inactive (los 2 centroides que quedan, bajo volumen)
         • inactive = mayor recency (hace más tiempo de la última compra)
         • new      = menor recency (última compra más reciente dentro del
           bloque de bajo gasto; no implica “cliente de ayer”, sino el
           segmento frío-bajo menos dormido)

    Así new e inactive no compiten por “quién tiene menos compras” cuando
    ambos clusters son casi iguales en F y M (caso típico del warehouse).
    """
    n = centroids_original.shape[0]
    ids = list(range(n))
    # --- 1) loyalty: top por monetary ---
    by_money = sorted(ids, key=lambda i: centroids_original[i, 2], reverse=True)
    n_loyalty = min(3, max(0, n - 2))  # dejar al menos 2 para new/inactive si n>=5
    if n <= 3:
        # edge case: todo loyalty + sin new/inactive formales
        n_loyalty = n
    loyalty_ids = by_money[:n_loyalty]
    rest_ids = by_money[n_loyalty:]

    loyalty_names = ["silver", "gold", "platinum"]
    loyalty_sorted = sorted(loyalty_ids, key=lambda i: centroids_original[i, 2])
    labels: dict[int, str] = {}
    # asignar desde la cola de nombres (si hay 1 loyalty → platinum, si 2 → gold+platinum)
    names_slice = loyalty_names[-len(loyalty_sorted) :] if loyalty_sorted else []
    for cid, name in zip(loyalty_sorted, names_slice):
        labels[cid] = name

    # --- 2) new / inactive entre el resto ---
    if len(rest_ids) == 1:
        # solo uno: si recency alta → inactive, si no → new
        cid = rest_ids[0]
        labels[cid] = (
            "inactive_customer"
            if centroids_original[cid, 0] >= np.median(centroids_original[:, 0])
            else "new_customer"
        )
    elif len(rest_ids) >= 2:
        inactive_id = max(rest_ids, key=lambda i: centroids_original[i, 0])
        new_id = min(rest_ids, key=lambda i: centroids_original[i, 0])
        # si empatan en recency, desempate: menor frequency = new
        if inactive_id == new_id:
            new_id = min(rest_ids, key=lambda i: centroids_original[i, 1])
            inactive_id = max(rest_ids, key=lambda i: centroids_original[i, 0])
        labels[inactive_id] = "inactive_customer"
        labels[new_id] = "new_customer"
        for cid in rest_ids:
            if cid not in labels:
                labels[cid] = "new_customer"
    return labels


def fit_clusters(X: np.ndarray) -> tuple[np.ndarray, np.ndarray, dict[int, str]]:
    """
    Scale → KMeans → etiquetas de negocio.

    Returns
    -------
    labels_raw : cluster id 0..k-1 por cliente
    centroids_original : centroides en escala RFM original
    id_to_name : mapa id → nombre comercial
    """
    scaler = StandardScaler()
    Xs = scaler.fit_transform(X)
    model = KMeans(
        n_clusters=N_CLUSTERS,
        n_init=10,
        random_state=RANDOM_STATE,
    )
    labels_raw = model.fit_predict(Xs)
    # Centroides en espacio escalado → volver a escala original para interpretar
    centroids_scaled = model.cluster_centers_
    centroids_original = scaler.inverse_transform(centroids_scaled)
    id_to_name = assign_business_labels(centroids_original)
    return labels_raw, centroids_original, id_to_name


def print_cluster_report(
    X: np.ndarray,
    labels_raw: np.ndarray,
    centroids: np.ndarray,
    id_to_name: dict[int, str],
) -> None:
    print()
    print("Clusters (KMeans k={}, seed={})".format(N_CLUSTERS, RANDOM_STATE))
    print("-" * 72)
    print(
        f"{'group':<20s} {'n':>8s} {'recency_d':>12s} "
        f"{'frequency':>12s} {'monetary':>12s}"
    )
    print("-" * 72)
    for name in BUSINESS_ORDER:
        # encontrar id con ese nombre
        ids = [i for i, n in id_to_name.items() if n == name]
        if not ids:
            continue
        cid = ids[0]
        mask = labels_raw == cid
        n = int(mask.sum())
        r, f, m = centroids[cid]
        print(f"{name:<20s} {n:8,d} {r:12.1f} {f:12.2f} {m:12.2f}")
    print("-" * 72)
    print(f"{'TOTAL':<20s} {len(labels_raw):8,d}")
    print()
    print("Lectura rápida de centroides:")
    print("  silver / gold / platinum → top monetary (loyalty)")
    print("  inactive → entre el resto, mayor recency (más tiempo sin comprar)")
    print("  new      → entre el resto, menor recency (último contacto más reciente)")
    print()


def plot_group_sizes(
    labels_raw: np.ndarray,
    id_to_name: dict[int, str],
    out: Path,
) -> None:
    """Gráfico 1: barras con el número de clientes por grupo de negocio."""
    counts = []
    names = []
    for name in BUSINESS_ORDER:
        ids = [i for i, n in id_to_name.items() if n == name]
        if not ids:
            continue
        names.append(name.replace("_", " "))
        counts.append(int((labels_raw == ids[0]).sum()))
    fig, ax = plt.subplots(figsize=(8, 4.8), layout="constrained")
    colors = ["#4C78A8", "#F58518", "#54A24B", "#E45756", "#B279A2"]
    ax.bar(names, counts, color=colors[: len(names)], edgecolor="white")
    ax.set_ylabel("customers")
    ax.set_xlabel("customer group")
    ax.set_title("Customers per cluster (business labels)")
    ax.tick_params(axis="x", rotation=15)
    for i, v in enumerate(counts):
        ax.text(i, v, f"{v:,}", ha="center", va="bottom", fontsize=8)
    fig.savefig(out, dpi=150, bbox_inches="tight", pad_inches=0.15, facecolor="white")
    print(f"→ Guardado: {out}")
    plt.show()
    plt.close(fig)


def plot_scatter_fm(
    X: np.ndarray,
    labels_raw: np.ndarray,
    id_to_name: dict[int, str],
    out: Path,
) -> None:
    """
    Gráfico 2: Frequency × Monetary coloreado por grupo.
    Muestra aleatoria para legibilidad (mismo seed).
    """
    rng = np.random.default_rng(RANDOM_STATE)
    n = X.shape[0]
    if n > SCATTER_SAMPLE:
        idx = rng.choice(n, size=SCATTER_SAMPLE, replace=False)
    else:
        idx = np.arange(n)
    fig, ax = plt.subplots(figsize=(8, 4.8), layout="constrained")
    # color por nombre de negocio
    name_to_color = {
        "new_customer": "#4C78A8",
        "inactive_customer": "#F58518",
        "silver": "#54A24B",
        "gold": "#E45756",
        "platinum": "#B279A2",
    }
    for name in BUSINESS_ORDER:
        ids = [i for i, n in id_to_name.items() if n == name]
        if not ids:
            continue
        cid = ids[0]
        mask = labels_raw[idx] == cid
        ax.scatter(
            X[idx][mask, 1],  # frequency
            X[idx][mask, 2],  # monetary
            s=8,
            alpha=0.35,
            c=name_to_color.get(name, "#999999"),
            label=name.replace("_", " "),
            edgecolors="none",
        )
    ax.set_xlabel("frequency (purchases)")
    ax.set_ylabel("monetary value in ₳")
    ax.set_title("Clusters in Frequency × Monetary space")
    ax.legend(markerscale=2, fontsize=8, loc="upper right")
    ax.grid(True, alpha=0.3)
    fig.savefig(out, dpi=150, bbox_inches="tight", pad_inches=0.15, facecolor="white")
    print(f"→ Guardado: {out}")
    plt.show()
    plt.close(fig)


def main() -> None:
    print("EX05 – Clustering")
    print(
        f"RFM → StandardScaler → KMeans(k={N_CLUSTERS}) → etiquetas de negocio"
    )
    print()

    try:
        conn = psycopg2.connect(**DB_CONFIG)
    except psycopg2.Error as exc:
        print("Error de conexión:", exc, file=sys.stderr)
        sys.exit(1)

    try:
        _uids, X = fetch_rfm(conn)
    except psycopg2.Error as exc:
        print("Error SQL:", exc, file=sys.stderr)
        sys.exit(1)
    finally:
        conn.close()

    if X.shape[0] < N_CLUSTERS:
        print("Pocos usuarios para clustering.", file=sys.stderr)
        sys.exit(1)

    print(f"Usuarios (RFM): {X.shape[0]:,}")
    labels_raw, centroids, id_to_name = fit_clusters(X)
    print_cluster_report(X, labels_raw, centroids, id_to_name)

    # Un PNG por gráfico en la raíz de ex05/ (como elbow en EX04)
    plot_group_sizes(labels_raw, id_to_name, SCRIPT_DIR / "customers_per_cluster.png")
    plot_scatter_fm(X, labels_raw, id_to_name, SCRIPT_DIR / "clusters_frequency_monetary.png")
    print("Proceso terminado.")


if __name__ == "__main__":
    main()
