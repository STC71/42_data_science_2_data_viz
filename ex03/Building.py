#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EX03 – Building.py
Module 2 – Data Viz – Piscine Data Science

================================================================================
SUBJECT (literal, en.subject.pdf – Exercise 03 : Highest Building)
================================================================================
  • made a bar chart with the number of orders according to the frequency
  • made a bar chart the Altairian Dollars spent on the site by customers
  • Turn-in directory : ex03/
  • Files to turn in  : Building.*

Expected look (PDF figure):
  LEFT  – frequency: histogram-like bars, X ≈ 0 / 10 / 20 / 30
          (NOT one bar per integer 1,2,3,…,30)
  RIGHT – monetary: bars by spend ranges, X ≈ 0 / 50 / 100 / 150 / 200

Nota: el PDF se hizo sin febrero; con data_2023_feb los conteos cambian,
pero la FORMA de los bins debe ser la del subject.

Fuente: Data Warehouse Module 1 → public.customers (event_type = 'purchase').
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
# Dependencias (mismo criterio que EX00–EX02)
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
    """No fijar Agg aquí (no bloquear plt.show() después)."""
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
# Rutas / .env (Module 0)
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

# ===========================================================================
# FREQUENCY – bins de ancho 10 (como el PDF)
#
#   [1, 10)  → bin 0   (clientes con 1…9 compras)
#   [10, 20) → bin 1
#   [20, 30) → bin 2
#   [30, ∞)  → bin 3   (30 o más)
#
# Antes se dibujaba una barra por cada entero 1,2,…,29 + "30+".
# Eso NO coincide con la figura del subject (4 edificios anchos).
# ===========================================================================
SQL_FREQUENCY = """
WITH per_user AS (
    SELECT user_id, COUNT(*)::int AS freq
    FROM customers
    WHERE event_type = 'purchase'
    GROUP BY user_id
),
binned AS (
    SELECT
        CASE
            WHEN freq < 10 THEN 0
            WHEN freq < 20 THEN 1
            WHEN freq < 30 THEN 2
            ELSE 3
        END AS bin_id
    FROM per_user
)
SELECT bin_id, COUNT(*)::bigint AS n_customers
FROM binned
GROUP BY bin_id
ORDER BY bin_id;
"""

# Centros de barra y ancho para imitar el eje continuo del PDF (0, 10, 20, 30)
FREQ_BAR_CENTERS = [5.0, 15.0, 25.0, 35.0]
FREQ_BAR_WIDTH = 9.0
FREQ_BIN_LABELS = ("0–10", "10–20", "20–30", "30+")

# ===========================================================================
# MONETARY – tramos de 50 ₳ (como el PDF)
#
#   [0, 50)    → bin 0
#   [50, 100)  → bin 1
#   [100, 150) → bin 2
#   [150, 200) → bin 3
#   [200, ∞)   → bin 4
# ===========================================================================
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
            WHEN total_spent < 50  THEN 0
            WHEN total_spent < 100 THEN 1
            WHEN total_spent < 150 THEN 2
            WHEN total_spent < 200 THEN 3
            ELSE 4
        END AS bin_id
    FROM per_user
)
SELECT bin_id, COUNT(*)::bigint AS n_customers
FROM binned
GROUP BY bin_id
ORDER BY bin_id;
"""

MON_BAR_CENTERS = [25.0, 75.0, 125.0, 175.0, 225.0]
MON_BAR_WIDTH = 48.0
MON_BIN_LABELS = ("0–50", "50–100", "100–150", "150–200", "200+")


def fetch_all(conn, sql: str):
    with conn.cursor() as cur:
        cur.execute(sql)
        return cur.fetchall()


def counts_by_bin(rows, n_bins: int) -> list[int]:
    """
    Convierte filas (bin_id, n) en lista de longitud n_bins (0 si falta un bin).
    """
    out = [0] * n_bins
    for bin_id, n in rows:
        i = int(bin_id)
        if 0 <= i < n_bins:
            out[i] = int(n)
    return out


def _save_bar_chart(
    centers: list[float],
    counts: list[int],
    *,
    width: float,
    xlim: tuple[float, float],
    xticks: list[int],
    xlabel: str,
    ylabel: str,
    title: str,
    out_path: Path,
    show: bool,
) -> None:
    fig, ax = plt.subplots(figsize=(7.5, 4.8), layout="constrained")
    ax.bar(
        centers,
        counts,
        width=width,
        color="#A0C4E8",
        edgecolor="white",
        align="center",
    )
    ax.set_xlim(*xlim)
    ax.set_xticks(xticks)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    ax.grid(True, axis="y", alpha=0.35)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(
        out_path,
        dpi=150,
        bbox_inches="tight",
        pad_inches=0.15,
        facecolor="white",
    )
    print(f"→ Guardado: {out_path}")
    if show:
        plt.show()
    plt.close(fig)


def plot_frequency(counts: list[int], out_path: Path, *, show: bool = False) -> None:
    """Frequency: bins de ancho 10 (PDF)."""
    _save_bar_chart(
        FREQ_BAR_CENTERS,
        counts,
        width=FREQ_BAR_WIDTH,
        xlim=(0, 40),
        xticks=[0, 10, 20, 30],
        xlabel="frequency",
        ylabel="customers",
        title="Number of customers by purchase frequency",
        out_path=out_path,
        show=show,
    )


def plot_monetary(counts: list[int], out_path: Path, *, show: bool = False) -> None:
    """Monetary: bins de 50 ₳ (PDF)."""
    _save_bar_chart(
        MON_BAR_CENTERS,
        counts,
        width=MON_BAR_WIDTH,
        xlim=(0, 250),
        xticks=[0, 50, 100, 150, 200],
        xlabel="monetary value in ₳",
        ylabel="customers",
        title="Number of customers by total spend",
        out_path=out_path,
        show=show,
    )


# Consultas independientes (no reutilizan el CASE de los histogramas)
SQL_TOTAL_BUYERS = """
SELECT COUNT(DISTINCT user_id)::bigint
FROM customers
WHERE event_type = 'purchase';
"""

SQL_FREQ_30PLUS = """
SELECT COUNT(*)::bigint
FROM (
    SELECT user_id
    FROM customers
    WHERE event_type = 'purchase'
    GROUP BY user_id
    HAVING COUNT(*) >= 30
) t;
"""

SQL_MON_200PLUS = """
SELECT COUNT(*)::bigint
FROM (
    SELECT user_id
    FROM customers
    WHERE event_type = 'purchase' AND price IS NOT NULL
    GROUP BY user_id
    HAVING SUM(price) >= 200
) t;
"""

SQL_USERS_WITH_PRICE = """
SELECT COUNT(DISTINCT user_id)::bigint
FROM customers
WHERE event_type = 'purchase' AND price IS NOT NULL;
"""


def run_self_check(conn, freq_counts: list[int], mon_counts: list[int]) -> bool:
    """
    Contrasta los arrays del gráfico con SQL independiente.
    Devuelve True si todo cuadra.
    """
    print()
    print("=" * 52)
    print("SELF-CHECK EX03 (SQL independiente vs bins del gráfico)")
    print("=" * 52)

    total_buyers = int(fetch_all(conn, SQL_TOTAL_BUYERS)[0][0])
    n_30 = int(fetch_all(conn, SQL_FREQ_30PLUS)[0][0])
    n_200 = int(fetch_all(conn, SQL_MON_200PLUS)[0][0])
    users_price = int(fetch_all(conn, SQL_USERS_WITH_PRICE)[0][0])

    sum_f = sum(freq_counts)
    sum_m = sum(mon_counts)
    last_f = freq_counts[3] if len(freq_counts) > 3 else -1
    last_m = mon_counts[4] if len(mon_counts) > 4 else -1

    checks = [
        ("Suma frequency == total_buyers", sum_f == total_buyers, sum_f, total_buyers),
        ("Frequency 30+ == HAVING COUNT(*)>=30", last_f == n_30, last_f, n_30),
        ("Suma monetary == users con price", sum_m == users_price, sum_m, users_price),
        ("Monetary 200+ == HAVING SUM>=200", last_m == n_200, last_m, n_200),
    ]

    ok_all = True
    for label, ok, a, b in checks:
        mark = "✓" if ok else "✗"
        print(f"  {mark} {label}")
        print(f"      gráfico/bins = {a:,}  |  SQL ref = {b:,}")
        if not ok:
            ok_all = False

    print("-" * 52)
    if ok_all:
        print("✓ SELF-CHECK OK — tablas y gráficos coherentes con la BD")
    else:
        print("✗ SELF-CHECK FALLÓ — revisa SQL o bins")
    print("=" * 52)
    return ok_all


def load_counts(conn):
    freq_rows = fetch_all(conn, SQL_FREQUENCY)
    mon_rows = fetch_all(conn, SQL_MONETARY)
    return counts_by_bin(freq_rows, 4), counts_by_bin(mon_rows, 5)


def print_tables(freq_counts: list[int], mon_counts: list[int]) -> None:
    print("Frequency – clientes por tramo de nº de compras:")
    print("-" * 44)
    for lab, n in zip(FREQ_BIN_LABELS, freq_counts):
        print(f"  {lab:>8s}  →  {n:>10,} customers")
    print(f"  {'TOTAL':>8s}  →  {sum(freq_counts):>10,} customers")
    print("-" * 44)
    print()
    print("Monetary – clientes por tramo de gasto total (₳):")
    print("-" * 44)
    for lab, n in zip(MON_BIN_LABELS, mon_counts):
        print(f"  {lab:>8s}  →  {n:>10,} customers")
    print(f"  {'TOTAL':>8s}  →  {sum(mon_counts):>10,} customers")
    print("-" * 44)
    print()


def main(argv: list[str] | None = None) -> None:
    """
    Uso:
      python3 Building.py              # tablas + gráficos
      python3 Building.py --self-check # tablas + gráficos + verificación SQL
      python3 Building.py --check-only # solo verificación (sin gráficos)
    """
    argv = list(sys.argv[1:] if argv is None else argv)
    self_check = "--self-check" in argv or "--check" in argv
    check_only = "--check-only" in argv

    print("EX03 – Highest Building")
    print("Fuente: customers · purchase · frequency (bins×10) + monetary (bins×50 ₳)")
    print()

    try:
        conn = psycopg2.connect(**DB_CONFIG)
    except psycopg2.Error as exc:
        print("Error de conexión:", exc, file=sys.stderr)
        sys.exit(1)

    try:
        freq_counts, mon_counts = load_counts(conn)
        if sum(freq_counts) == 0:
            print("Sin clientes con purchase.", file=sys.stderr)
            sys.exit(1)

        print_tables(freq_counts, mon_counts)

        passed = True
        if self_check or check_only:
            passed = run_self_check(conn, freq_counts, mon_counts)

        if not check_only:
            imgs = SCRIPT_DIR / "imgs"
            imgs.mkdir(parents=True, exist_ok=True)
            plot_frequency(freq_counts, imgs / "customers_by_purchase_frecuency.png", show=True)
            plot_frequency(freq_counts, SCRIPT_DIR / "building_frequency.png", show=False)
            plot_monetary(mon_counts, imgs / "customers_by_total_spend.png", show=True)
            plot_monetary(mon_counts, SCRIPT_DIR / "building_monetary.png", show=False)
            print("Proceso terminado.")
    except psycopg2.Error as exc:
        print("Error SQL:", exc, file=sys.stderr)
        sys.exit(1)
    finally:
        conn.close()

    if (self_check or check_only) and not passed:
        sys.exit(2)


if __name__ == "__main__":
    main()
