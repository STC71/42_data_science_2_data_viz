#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EX00 – pie.py
Module 2 – Data Viz – Piscine Data Science

Qué pide el subject:
  • Hacer un pie chart para entender qué hacen las personas en el sitio.
  • Conectarse al Data Warehouse del Module 01 (tabla customers).

Qué hace este script:
  1) Localiza el .env de Module 0 (credenciales PostgreSQL).
  2) Conecta a piscineds y cuenta eventos por event_type en customers.
  3) Dibuja un gráfico de sectores (pie) con porcentajes.
  4) Muestra el gráfico y, opcionalmente, lo guarda como PNG.

Analogía:
  El pie chart es como cortar una tarta: cada porción es un tipo de acción
  (view, cart, remove_from_cart, purchase…). A simple vista ves qué manda
  en el tráfico del sitio.

Uso:
  python3 pie.py
  ./pie.py
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Dependencias
# ---------------------------------------------------------------------------
def ensure_dependencies() -> None:
    """Instala psycopg2, python-dotenv, matplotlib si faltan (pip --user)."""
    import importlib.util
    import subprocess

    needed = {
        "psycopg2": "psycopg2-binary",
        "dotenv": "python-dotenv",
        "matplotlib": "matplotlib",
    }
    missing = [
        pkg for mod, pkg in needed.items() if importlib.util.find_spec(mod) is None
    ]
    if missing:
        print(f"Instalando: {', '.join(missing)} ...")
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "--user", *missing]
        )


ensure_dependencies()

import matplotlib.pyplot as plt
import psycopg2
from dotenv import load_dotenv

# ---------------------------------------------------------------------------
# Rutas / .env (Module 0)
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
MODULE2_DIR = SCRIPT_DIR.parent


def find_env_file() -> Path | None:
    """
    Busca Module 0 ex00/.env (mismo patrón que Module 1).
    También prueba rutas del monorepo piscine_pedago_data_science.
    """
    candidates = [
        MODULE2_DIR.parent / "data_science_0_creation_db" / "ex00" / ".env",
        MODULE2_DIR / ".." / "data_science_0_creation_db" / "ex00" / ".env",
        MODULE2_DIR.parent
        / "data_science_1_data_warehouse"
        / ".."
        / "data_science_0_creation_db"
        / "ex00"
        / ".env",
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
        / (os.environ.get("USER") or "")
        / "42_outer_core"
        / "piscine_pedago_data_science"
        / "data_science_0_creation_db"
        / "ex00"
        / ".env",
    ]
    for path in candidates:
        path = path.resolve()
        if path.is_file():
            return path
    return None


ENV_PATH = find_env_file()
if ENV_PATH is not None:
    load_dotenv(ENV_PATH)
    print(f"→ .env: {ENV_PATH}")
else:
    print("→ .env no encontrado; variables de entorno / valores por defecto")

DB_CONFIG = {
    "host": os.environ.get("POSTGRES_HOST", "localhost"),
    "port": int(os.environ.get("POSTGRES_PORT", "5432")),
    "dbname": os.environ.get("POSTGRES_DB", "piscineds"),
    "user": os.environ.get("POSTGRES_USER", os.environ.get("USER", "")),
    "password": os.environ.get("POSTGRES_PASSWORD", "mysecretpassword"),
}

# Consulta: distribución de acciones en el sitio (toda la tabla customers del warehouse)
SQL_EVENT_COUNTS = """
SELECT event_type, COUNT(*) AS n
FROM customers
GROUP BY event_type
ORDER BY n DESC;
"""


def fetch_event_counts(conn) -> list[tuple[str, int]]:
    """Devuelve lista (event_type, count) ordenada de mayor a menor."""
    with conn.cursor() as cur:
        cur.execute(SQL_EVENT_COUNTS)
        rows = cur.fetchall()
    return [(str(r[0]), int(r[1])) for r in rows]


def plot_pie(labels: list[str], sizes: list[int], out_path: Path | None = None) -> None:
    """
    Dibuja el pie chart del subject.
    Porcentajes en cada sector; leyenda con el nombre del event_type.
    """
    total = sum(sizes) or 1
    # Colores cercanos al ejemplo del PDF (azul, verde, amarillo-verde, rojo suave…)
    colors = ["#4C78A8", "#54A24B", "#F58518", "#E45756", "#B279A2", "#72B7B2"]

    fig, ax = plt.subplots(figsize=(8, 8))
    wedges, texts, autotexts = ax.pie(
        sizes,
        labels=None,
        autopct=lambda p: f"{p:.1f}%",
        startangle=90,
        colors=colors[: len(sizes)],
        pctdistance=0.65,
        wedgeprops={"linewidth": 1, "edgecolor": "white"},
    )
    for t in autotexts:
        t.set_fontsize(10)
        t.set_color("white")
        t.set_fontweight("bold")

    ax.legend(
        wedges,
        [f"{lab}  ({n:,})" for lab, n in zip(labels, sizes)],
        title="event_type",
        loc="center left",
        bbox_to_anchor=(1.0, 0.5),
        frameon=False,
    )
    ax.set_title(
        "Qué hacen los usuarios en el sitio\n(event_type · tabla customers · Module 1)",
        fontsize=13,
        pad=16,
    )
    # Círculo: aspecto de tarta redonda
    ax.axis("equal")
    fig.tight_layout()

    if out_path is not None:
        fig.savefig(out_path, dpi=150, bbox_inches="tight")
        print(f"→ Guardado: {out_path}")

    plt.show()
    plt.close(fig)


def main() -> None:
    print("EX00 – American apple Pie")
    print("Fuente: public.customers (Data Warehouse Module 1)")
    print()

    try:
        conn = psycopg2.connect(**DB_CONFIG)
    except psycopg2.Error as exc:
        print("Error de conexión a PostgreSQL:", exc, file=sys.stderr)
        print(
            "Revisa: docker ps, Module 0 .env, y que exista customers (Module 1 EX01+).",
            file=sys.stderr,
        )
        sys.exit(1)

    try:
        rows = fetch_event_counts(conn)
    except psycopg2.Error as exc:
        print("Error SQL:", exc, file=sys.stderr)
        print("¿Existe la tabla customers? Ejecuta Module 1 EX01 (y EX02/EX03 si aplica).", file=sys.stderr)
        sys.exit(1)
    finally:
        conn.close()

    if not rows:
        print("No hay filas en customers.", file=sys.stderr)
        sys.exit(1)

    labels = [r[0] for r in rows]
    sizes = [r[1] for r in rows]
    total = sum(sizes)

    print(f"Total eventos: {total:,}")
    print("-" * 40)
    for lab, n in rows:
        print(f"  {lab:20s}  {n:12,}  ({100.0 * n / total:5.1f}%)")
    print("-" * 40)

    out = SCRIPT_DIR / "pie_chart.png"
    plot_pie(labels, sizes, out_path=out)
    print("Proceso terminado.")


if __name__ == "__main__":
    main()
