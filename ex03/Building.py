#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EX03 – Building.py
Module 2 – Data Viz – Piscine Data Science

================================================================================
SUBJECT – Highest Building
================================================================================
  • Analizar la frecuencia de compra de los clientes y el valor monetario.
  • Gráficos tipo “edificios” (barras):
      1) Nº de clientes según cuántas veces han comprado (frequency)
      2) Nº de clientes según el gasto total (monetary)
  • Turn-in directory : ex03/
  • Files to turn in  : Building.*

Fuente: Data Warehouse Module 1 → customers (event_type = purchase).
"""

from __future__ import annotations

import os                   # Para leer variables de entorno y rutas de archivos
import sys                  # Para sys.exit() y sys.path
import warnings             # Para filtrar advertencias de matplotlib
from pathlib import Path    # Para manejar rutas de archivos de manera portátil

warnings.filterwarnings("ignore", message=r"Unable to import Axes3D.*")
warnings.filterwarnings("ignore", message=r"FigureCanvasAgg is non-interactive.*")
warnings.filterwarnings(
    "ignore",
    category=UserWarning,
    module=r"matplotlib(\..*)?",
)
# Se filtran los warnings de matplotlib que no afectan a la funcionalidad principal 
# del script, especialmente en entornos sin interfaz gráfica, 3D, o cuando se usan 
# backends no interactivos como Agg. La idea es mantener la salida limpia y centrarse 
# en los resultados relevantes del análisis de datos.

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
    """No fijar Agg aquí."""
    try:
        import numpy as np
        from numpy.linalg import eigvals

        eigvals(np.eye(2))
        import matplotlib.pyplot as plt

        fig, ax = plt.subplots()
        ax.bar([1, 2, 3], [3, 2, 1])
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

# Frecuencia: cuántos clientes tienen exactamente n compras.
# Las compras >= FREQ_CAP se agrupan en la última barra (estilo PDF "30+").
FREQ_CAP = 30

SQL_FREQUENCY = f"""
WITH per_user AS (
    SELECT user_id, COUNT(*)::int AS freq
    FROM customers
    WHERE event_type = 'purchase'
    GROUP BY user_id
),
capped AS (
    SELECT
        CASE
            WHEN freq >= {FREQ_CAP} THEN {FREQ_CAP}
            ELSE freq
        END AS freq_bin
    FROM per_user
)
SELECT freq_bin, COUNT(*)::bigint AS n_customers
FROM capped
GROUP BY freq_bin
ORDER BY freq_bin;
"""

# Monetario: gasto total por usuario, agrupado en tramos (edificios).
# Bins alineados con rangos típicos del subject (0–50, 50–100, …, 200+).
SQL_MONETARY = """
WITH per_user AS (
    SELECT user_id, SUM(price) AS total_spent
    FROM customers
    WHERE event_type = 'purchase'
      AND price IS NOT NULL
    GROUP BY user_id
),
binned AS (
    SELECT
        CASE
            WHEN total_spent >= 0  AND total_spent < 50  THEN 0
            WHEN total_spent >= 50 AND total_spent < 100 THEN 1
            WHEN total_spent >= 100 AND total_spent < 150 THEN 2
            WHEN total_spent >= 150 AND total_spent < 200 THEN 3
            ELSE 4
        END AS bin_id
    FROM per_user
)
SELECT bin_id, COUNT(*)::bigint AS n_customers
FROM binned
GROUP BY bin_id
ORDER BY bin_id;
"""

MONETARY_LABELS = {
    0: "0–50",
    1: "50–100",
    2: "100–150",
    3: "150–200",
    4: "200+",
}


def fetch_all(conn, sql: str):
    with conn.cursor() as cur:
        cur.execute(sql)
        return cur.fetchall()


def plot_frequency(rows, out_path: Path) -> None:
    """Barras: eje X = nº de compras (1…29, 30+); Y = nº de clientes."""
    bins = [int(r[0]) for r in rows]
    counts = [int(r[1]) for r in rows]
    labels = [str(b) if b < FREQ_CAP else f"{FREQ_CAP}+" for b in bins]

    fig, ax = plt.subplots(figsize=(11, 4.8), layout="constrained")
    ax.bar(labels, counts, color="#4C78A8", edgecolor="white", width=0.85)
    ax.set_xlabel("frequency")
    ax.set_ylabel("customers")
    ax.set_title("Number of customers by purchase frequency")
    ax.grid(True, axis="y", alpha=0.35)
    # Evitar solapamiento de etiquetas si hay muchas barras
    if len(labels) > 20:
        for i, tick in enumerate(ax.get_xticklabels()):
            if i % 2 != 0:
                tick.set_visible(False)
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


def plot_monetary(rows, out_path: Path) -> None:
    """Barras: eje X = tramo de gasto total (₳); Y = nº de clientes."""
    ids = [int(r[0]) for r in rows]
    counts = [int(r[1]) for r in rows]
    labels = [MONETARY_LABELS.get(i, str(i)) for i in ids]

    fig, ax = plt.subplots(figsize=(8, 4.8), layout="constrained")
    ax.bar(labels, counts, color="#54A24B", edgecolor="white", width=0.7)
    ax.set_xlabel("monetary value (₳)")
    ax.set_ylabel("customers")
    ax.set_title("Number of customers by total spend (basket)")
    ax.grid(True, axis="y", alpha=0.35)
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
    print("EX03 – Highest Building")
    print("Fuente: customers · purchase · frequency + monetary")
    print()

    try:
        conn = psycopg2.connect(**DB_CONFIG)
    except psycopg2.Error as exc:
        print("Error de conexión:", exc, file=sys.stderr)
        sys.exit(1)

    try:
        freq_rows = fetch_all(conn, SQL_FREQUENCY)
        mon_rows = fetch_all(conn, SQL_MONETARY)
    except psycopg2.Error as exc:
        print("Error SQL:", exc, file=sys.stderr)
        sys.exit(1)
    finally:
        conn.close()

    if not freq_rows:
        print("Sin clientes con purchase.", file=sys.stderr)
        sys.exit(1)

    print("Frequency (compras por usuario → nº de clientes):")
    print("-" * 40)
    for b, n in freq_rows:
        label = str(b) if int(b) < FREQ_CAP else f"{FREQ_CAP}+"
        print(f"  freq {label:>4s}  →  {int(n):>10,} customers")
    print("-" * 40)
    print()
    print("Monetary (gasto total por usuario → nº de clientes):")
    print("-" * 40)
    for b, n in mon_rows:
        print(f"  {MONETARY_LABELS.get(int(b), b):>8s}  →  {int(n):>10,} customers")
    print("-" * 40)
    print()

    plot_frequency(freq_rows, SCRIPT_DIR / "building_frequency.png")
    plot_monetary(mon_rows, SCRIPT_DIR / "building_monetary.png")
    print("Proceso terminado.")


if __name__ == "__main__":
    main()
