#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EX02 – mustache.py
Module 2 – Data Viz – Piscine Data Science

================================================================================
SUBJECT (idea del PDF – “My beautiful mustache”)
================================================================================
  • Analizar los valores de precio de los artículos comprados (purchase).
  • Calcular estadísticas tipo describe: count, mean, std, min, 25%, 50%, 75%, max.
  • Representar un box plot (“boîte à moustaches”).
  • Luego: precio medio del panier (cesta) por usuario → mismas stats + box plot.
  • Turn-in directory : ex02/
  • Files to turn in  : mustache.*

Fuente: Data Warehouse Module 1 → tabla customers.
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

# ---------------------------------------------------------------------------
# Dependencias (mismo criterio EX00/EX01)
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


def _purge_numpy_matplotlib() -> None:
    for name in list(sys.modules):
        if (
            name == "numpy"
            or name.startswith("numpy.")
            or name == "matplotlib"
            or name.startswith("matplotlib.")
        ):
            del sys.modules[name]


def _matplotlib_works() -> bool:
    """No fijar Agg aquí (no bloquear plt.show())."""
    try:
        import numpy as np
        from numpy.linalg import eigvals

        eigvals(np.eye(2))
        import matplotlib.pyplot as plt

        fig, ax = plt.subplots()
        ax.boxplot([1, 2, 3, 4, 5])
        plt.close(fig)
        return True
    except Exception as exc:
        print(f"⚠ stack gráficos no OK: {type(exc).__name__}: {exc}")
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

    for mod, pkg in {"psycopg2": "psycopg2-binary", "dotenv": "python-dotenv"}.items():
        if importlib.util.find_spec(mod) is None:
            _pip([pkg], user=True)

    if _matplotlib_works():
        return

    print("→ Reparando NumPy + matplotlib...")
    try:
        _pip(
            ["--force-reinstall", "--no-cache-dir", "numpy==1.26.4", "matplotlib"],
            user=True,
        )
    except subprocess.CalledProcessError as exc:
        print("pip falló:", exc, file=sys.stderr)

    _purge_numpy_matplotlib()
    try:
        _prefer_paths([site.getusersitepackages()])
    except Exception:
        pass

    if _matplotlib_works():
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

# ---------------------------------------------------------------------------
# Rutas / .env
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
MODULE2_DIR = SCRIPT_DIR.parent


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

# Precios unitarios de cada línea de compra
SQL_ITEM_PRICES = """
SELECT price
FROM customers
WHERE event_type = 'purchase'
  AND price IS NOT NULL;
"""

# Cesta por usuario: suma de precios de todas sus compras
SQL_BASKET_PER_USER = """
SELECT user_id, SUM(price) AS basket
FROM customers
WHERE event_type = 'purchase'
  AND price IS NOT NULL
GROUP BY user_id;
"""


def fetch_prices(conn) -> np.ndarray:
    """Vector 1D de precios de ítems comprados."""
    with conn.cursor() as cur:
        cur.execute(SQL_ITEM_PRICES)
        rows = cur.fetchall()
    if not rows:
        return np.array([], dtype=float)
    return np.fromiter((float(r[0]) for r in rows), dtype=float, count=len(rows))


def fetch_baskets(conn) -> np.ndarray:
    """Vector 1D de total gastado por user_id (panier)."""
    with conn.cursor() as cur:
        cur.execute(SQL_BASKET_PER_USER)
        rows = cur.fetchall()
    if not rows:
        return np.array([], dtype=float)
    return np.fromiter((float(r[1]) for r in rows), dtype=float, count=len(rows))


def describe(arr: np.ndarray) -> dict[str, float]:
    """
    Estadísticos al estilo pandas.Series.describe() para un vector 1D.

    count, mean, std, min, 25%, 50%, 75%, max
    """
    if arr.size == 0:
        return {
            k: float("nan")
            for k in ("count", "mean", "std", "min", "25%", "50%", "75%", "max")
        }
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


def print_describe(title: str, stats: dict[str, float]) -> None:
    """Imprime la tabla de estadísticas (formato legible tipo pandas)."""
    print(title)
    print("-" * 28)
    for key in ("count", "mean", "std", "min", "25%", "50%", "75%", "max"):
        val = stats[key]
        if key == "count":
            print(f"  {key:8s}  {val:,.0f}")
        else:
            print(f"  {key:8s}  {val:,.6f}")
    print("-" * 28)
    print()


def plot_boxplot(
    data: np.ndarray,
    title: str,
    ylabel: str,
    out_path: Path,
    *,
    horizontal: bool = True,
    show_fliers: bool = False,
) -> None:
    """
    Box plot (“boîte à moustaches”).

    Por defecto horizontal y sin outliers (fliers): el PDF suele enfatizar
    cuartiles y bigotes; con 1M+ puntos los fliers saturan el dibujo.
    """
    fig, ax = plt.subplots(figsize=(9, 3.2) if horizontal else (4.5, 6), layout="constrained")
    # vert=False → horizontal (compatible matplotlib 3.5+ del cluster)
    ax.boxplot(
        data,
        vert=not horizontal,
        showfliers=show_fliers,
        patch_artist=True,
        boxprops={"facecolor": "#A0C4E8", "edgecolor": "#4C78A8"},
        medianprops={"color": "#E45756", "linewidth": 1.5},
        whiskerprops={"color": "#4C78A8"},
        capprops={"color": "#4C78A8"},
    )
    if horizontal:
        ax.set_xlabel(ylabel)
        ax.set_yticklabels([])
    else:
        ax.set_ylabel(ylabel)
        ax.set_xticklabels([])
    ax.set_title(title)
    ax.grid(True, axis="x" if horizontal else "y", alpha=0.35)
    fig.savefig(
        out_path,
        dpi=150,
        bbox_inches="tight",
        pad_inches=0.15,
        facecolor="white",
    )
    print(f"→ Guardado: {out_path}")
    plt.show()
    plt.close(fig)


def main() -> None:
    print("EX02 – My beautiful mustache")
    print("Fuente: customers · event_type = purchase")
    print()

    try:
        conn = psycopg2.connect(**DB_CONFIG)
    except psycopg2.Error as exc:
        print("Error de conexión:", exc, file=sys.stderr)
        sys.exit(1)

    try:
        print("Cargando precios de ítems (purchase)...")
        prices = fetch_prices(conn)
        print(f"  → {prices.size:,} precios")
        print("Agregando cestas por user_id...")
        baskets = fetch_baskets(conn)
        print(f"  → {baskets.size:,} usuarios con al menos una compra")
        print()
    except psycopg2.Error as exc:
        print("Error SQL:", exc, file=sys.stderr)
        sys.exit(1)
    finally:
        conn.close()

    if prices.size == 0:
        print("Sin precios purchase.", file=sys.stderr)
        sys.exit(1)

    stats_items = describe(prices)
    stats_baskets = describe(baskets)

    print_describe("Item price (purchase) · ₳", stats_items)
    print_describe("Basket total per user · ₳", stats_baskets)

    plot_boxplot(
        prices,
        title="Box plot – price of purchased items (₳)",
        ylabel="price (₳)",
        out_path=SCRIPT_DIR / "mustache_item_price.png",
        horizontal=True,
        show_fliers=False,
    )
    plot_boxplot(
        baskets,
        title="Box plot – average basket (total spend per user) (₳)",
        ylabel="basket total (₳)",
        out_path=SCRIPT_DIR / "mustache_basket.png",
        horizontal=True,
        show_fliers=False,
    )

    print("Proceso terminado.")


if __name__ == "__main__":
    main()
