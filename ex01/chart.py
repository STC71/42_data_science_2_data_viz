#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EX01 – chart.py
Module 2 – Data Viz – Piscine Data Science

================================================================================
SUBJECT (literal)
================================================================================
  • Keep only the "purchase" data of 'event_type' column
  • All prices are in Altairian Dollars
  • Create 3 charts from the beginning of October 2022 to the end of February 2023
  • Turn-in directory : ex01/
  • Files to turn in  : chart.*

================================================================================
LOS 3 GRÁFICOS (como en el PDF)
================================================================================
  1) Línea: número de clientes (compras) por día
  2) Barras: ventas totales en millones de ₳ por mes
  3) Área: gasto medio por cliente (₳) a lo largo del tiempo

  Rango temporal: 2022-10-01 … 2023-02-28 (incluye febrero).

Fuente: tabla customers del Data Warehouse (Module 1).
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
# Dependencias (mismo criterio que EX00)
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
    """No fijar Agg aquí (bloquearía plt.show() después)."""
    try:
        import numpy as np
        from numpy.linalg import eigvals

        eigvals(np.eye(2))
        import matplotlib.pyplot as plt

        fig, ax = plt.subplots()
        ax.plot([1, 2, 3])
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
        f"\n✓ .venv listo. Relanza con:\n  {venv_dir}/bin/python {PathLib(__file__).resolve()}\n",
        file=sys.stderr,
    )
    sys.exit(0)


ensure_dependencies()

import matplotlib

if not os.environ.get("MPLBACKEND") and not os.environ.get("DISPLAY"):
    matplotlib.use("Agg")

import matplotlib.dates as mdates
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

# Rango del subject: inicio de octubre 2022 → fin de febrero 2023
DATE_FROM = "2022-10-01"
DATE_TO = "2023-03-01"  # exclusivo: incluye todo febrero

# ---------------------------------------------------------------------------
# Consultas (solo purchase, agregación en SQL)
# ---------------------------------------------------------------------------
# 1) Clientes (compras) por día
SQL_CUSTOMERS_PER_DAY = f"""
SELECT
    event_time::date AS day,
    COUNT(*)        AS n_customers
FROM customers
WHERE event_type = 'purchase'
  AND event_time >= TIMESTAMP '{DATE_FROM}'
  AND event_time <  TIMESTAMP '{DATE_TO}'
GROUP BY event_time::date
ORDER BY day;
"""

# 2) Ventas totales por mes (suma de price) → se divide por 1e6 en Python
SQL_SALES_PER_MONTH = f"""
SELECT
    date_trunc('month', event_time)::date AS month,
    SUM(price) AS total_sales
FROM customers
WHERE event_type = 'purchase'
  AND event_time >= TIMESTAMP '{DATE_FROM}'
  AND event_time <  TIMESTAMP '{DATE_TO}'
GROUP BY date_trunc('month', event_time)
ORDER BY month;
"""

# 3) Gasto medio por cliente y día
#    average spend/customers ≈ SUM(price) / COUNT(*) por día
#    (cada fila purchase = un ítem comprado; el PDF usa “customers” en el eje)
SQL_AVG_SPEND_PER_DAY = f"""
SELECT
    event_time::date AS day,
    SUM(price) / NULLIF(COUNT(*), 0) AS avg_spend
FROM customers
WHERE event_type = 'purchase'
  AND event_time >= TIMESTAMP '{DATE_FROM}'
  AND event_time <  TIMESTAMP '{DATE_TO}'
GROUP BY event_time::date
ORDER BY day;
"""


def fetch_all(conn, sql: str):
    with conn.cursor() as cur:
        cur.execute(sql)
        return cur.fetchall()


def plot_charts(
    daily_customers,
    monthly_sales,
    daily_avg_spend,
    out_dir: Path,
) -> None:
    """
    Genera las 3 figuras del subject y las guarda en out_dir.
    También muestra ventanas si el backend es interactivo.
    """
    style_color = "#4C78A8"
    fill_color = "#4C78A8"

    # --- Chart 1: customers per day (línea) ---
    days = [r[0] for r in daily_customers]
    counts = [int(r[1]) for r in daily_customers]

    fig1, ax1 = plt.subplots(figsize=(10, 4.5), layout="constrained")
    ax1.plot(days, counts, color=style_color, linewidth=1.2)
    ax1.set_ylabel("Number of customers")
    ax1.set_xlabel("")
    ax1.set_title("Purchases per day (customers) · Oct 2022 – Feb 2023")
    ax1.grid(True, alpha=0.35)
    ax1.xaxis.set_major_formatter(mdates.DateFormatter("%b"))
    ax1.xaxis.set_major_locator(mdates.MonthLocator())
    fig1.savefig(
        out_dir / "chart_customers_daily.png",
        dpi=150,
        bbox_inches="tight",
        pad_inches=0.15,
        facecolor="white",
    )
    print(f"→ Guardado: {out_dir / 'chart_customers_daily.png'}")
    plt.show()
    plt.close(fig1)

    # --- Chart 2: total sales per month (barras, millones de ₳) ---
    months = [r[0] for r in monthly_sales]
    sales_m = [float(r[1]) / 1_000_000.0 for r in monthly_sales]
    month_labels = [d.strftime("%b") for d in months]

    fig2, ax2 = plt.subplots(figsize=(8, 4.5), layout="constrained")
    ax2.bar(month_labels, sales_m, color="#A0C4E8", edgecolor="white", width=0.7)
    ax2.set_ylabel("total sales in million of ₳")
    ax2.set_xlabel("month")
    ax2.set_title("Total sales by month · Oct 2022 – Feb 2023")
    ax2.grid(True, axis="y", alpha=0.35)
    fig2.savefig(
        out_dir / "chart_sales_monthly.png",
        dpi=150,
        bbox_inches="tight",
        pad_inches=0.15,
        facecolor="white",
    )
    print(f"→ Guardado: {out_dir / 'chart_sales_monthly.png'}")
    plt.show()
    plt.close(fig2)

    # --- Chart 3: average spend per customer (área) ---
    days3 = [r[0] for r in daily_avg_spend]
    avgs = [float(r[1]) for r in daily_avg_spend]

    fig3, ax3 = plt.subplots(figsize=(10, 4.5), layout="constrained")
    ax3.fill_between(days3, avgs, color=fill_color, alpha=0.45)
    ax3.plot(days3, avgs, color=style_color, linewidth=0.8)
    ax3.set_ylabel("average spend/customers in ₳")
    ax3.set_xlabel("")
    ax3.set_title("Average spend per purchase-day · Oct 2022 – Feb 2023")
    ax3.grid(True, alpha=0.35)
    ax3.xaxis.set_major_formatter(mdates.DateFormatter("%b"))
    ax3.xaxis.set_major_locator(mdates.MonthLocator())
    fig3.savefig(
        out_dir / "chart_avg_spend_daily.png",
        dpi=150,
        bbox_inches="tight",
        pad_inches=0.15,
        facecolor="white",
    )
    print(f"→ Guardado: {out_dir / 'chart_avg_spend_daily.png'}")
    plt.show()
    plt.close(fig3)


def main() -> None:
    print("EX01 – initial data exploration")
    print(f"Filtro: event_type = 'purchase' · {DATE_FROM} → fin de febrero 2023")
    print()

    try:
        conn = psycopg2.connect(**DB_CONFIG)
    except psycopg2.Error as exc:
        print("Error de conexión:", exc, file=sys.stderr)
        sys.exit(1)

    try:
        daily_customers = fetch_all(conn, SQL_CUSTOMERS_PER_DAY)
        monthly_sales = fetch_all(conn, SQL_SALES_PER_MONTH)
        daily_avg = fetch_all(conn, SQL_AVG_SPEND_PER_DAY)
    except psycopg2.Error as exc:
        print("Error SQL:", exc, file=sys.stderr)
        print("¿Existe customers con event_type y price?", file=sys.stderr)
        sys.exit(1)
    finally:
        conn.close()

    if not daily_customers:
        print("Sin compras en el rango. Revisa warehouse + febrero.", file=sys.stderr)
        sys.exit(1)

    print(f"Días con purchase: {len(daily_customers)}")
    print(f"Meses: {len(monthly_sales)}")
    for m, s in monthly_sales:
        print(f"  {m}  total_sales = {float(s):,.2f} ₳  ({float(s)/1e6:.3f} M)")
    print()

    plot_charts(daily_customers, monthly_sales, daily_avg, SCRIPT_DIR)
    print("Proceso terminado ✓")


if __name__ == "__main__":
    main()
