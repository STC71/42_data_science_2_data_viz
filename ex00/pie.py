#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EX00 – pie.py
Module 2 – Data Viz – Piscine Data Science

================================================================================
SUBJECT (literal)
================================================================================
  • Make your own pie chart to understand what people do on the site
  • You have to connect to your Data Warehouse of module 01
  • Turn-in directory : ex00/
  • Files to turn in  : pie.*

================================================================================
QUÉ HACE ESTE SCRIPT
================================================================================
  1) Localiza el .env de Module 0 (usuario / password / nombre de BD).
  2) Se conecta a PostgreSQL (contenedor postgres_piscineds, BD piscineds).
  3) Cuenta filas de la tabla customers agrupadas por event_type
     (view, cart, remove_from_cart, purchase, …).
  4) Dibuja un gráfico de sectores (pie chart) con porcentajes.
  5) Guarda pie_chart.png junto a este script.
  6) Si hay pantalla gráfica (variable DISPLAY), abre una ventana con el gráfico.
     Si no (SSH sin X11), solo genera el PNG (backend Agg).

Analogía:
  El pie es una tarta: cada porción es un tipo de acción del usuario en el sitio.
  A simple vista se ve qué predomina (casi siempre "view").

Uso:
  python3 pie.py
  ./pie.py
  MPLBACKEND=Agg python3 pie.py   # forzar solo PNG (sin intentar ventana)

Dependencias:
  psycopg2-binary, python-dotenv, numpy, matplotlib
  (el script intenta instalarlas en el usuario o crear un .venv del módulo 2
   si el cluster tiene el típico choque NumPy 2 / matplotlib del sistema).
"""

from __future__ import annotations

import os
import sys
import warnings
from pathlib import Path

# ---------------------------------------------------------------------------
# Warnings de matplotlib en el cluster 42
# ---------------------------------------------------------------------------
# Deben registrarse ANTES de importar matplotlib (también dentro de
# ensure_dependencies). Python usa re.match sobre el texto del warning:
# el patrón tiene que coincidir desde el inicio del mensaje.
warnings.filterwarnings("ignore", message=r"Unable to import Axes3D.*")
warnings.filterwarnings("ignore", message=r"FigureCanvasAgg is non-interactive.*")
warnings.filterwarnings(
    "ignore",
    category=UserWarning,
    module=r"matplotlib(\..*)?",
)

# ===========================================================================
# Instalación / reparación de dependencias (cluster 42)
# ===========================================================================
#
# Problema habitual:
#   - matplotlib de /usr/lib compilado contra NumPy 1.x
#   - NumPy 2.x instalado con pip --user (a veces por opencv-python)
#   → AttributeError: _ARRAY_API not found  /  multiarray failed to import
#   → o TypeError en numpy.linalg.eigvals al dibujar el pie
#
# Estrategia:
#   1) Preferir site-packages del usuario (y de .venv del módulo si existe).
#   2) Comprobar que matplotlib + numpy.linalg funcionan de verdad.
#   3) Si no: force-reinstall numpy==1.26.4 + matplotlib --user.
#   4) Si sigue mal: crear data_science_2_data_viz/.venv aislado e indicar
#      que se relance con ese intérprete.
# ===========================================================================


def _pip(cmd_packages: list[str], user: bool = True) -> None:
    """Ejecuta: python -m pip install [--user] <paquetes>."""
    import subprocess

    cmd = [sys.executable, "-m", "pip", "install"]
    if user:
        cmd.append("--user")
    cmd.extend(cmd_packages)
    print("→", " ".join(cmd))
    subprocess.check_call(cmd)


def _prefer_paths(paths: list[str]) -> None:
    """Antepone rutas a sys.path (prioridad sobre paquetes del sistema)."""
    for path in reversed(paths):
        if path and path not in sys.path:
            sys.path.insert(0, path)


def _purge_numpy_matplotlib() -> None:
    """
    Quita de sys.modules numpy/matplotlib ya cargados a medias.
    Así el siguiente import vuelve a leer los binarios recién instalados.
    """
    for name in list(sys.modules):
        if (
            name == "numpy"
            or name.startswith("numpy.")
            or name == "matplotlib"
            or name.startswith("matplotlib.")
        ):
            del sys.modules[name]


def _matplotlib_works() -> bool:
    """
    Comprueba que el stack de gráficos es usable.

    Importante: NO llamar aquí a matplotlib.use("Agg").
    Si se fija Agg en esta prueba, el backend queda bloqueado para todo el
    proceso y plt.show() ya no puede abrir ventana aunque exista DISPLAY.
    """
    try:
        import numpy as np
        from numpy.linalg import eigvals

        # Detecta NumPy “a medias” tras un downgrade incompleto
        eigvals(np.eye(2))

        import matplotlib.pyplot as plt

        fig, ax = plt.subplots()
        ax.pie([1, 2, 3], autopct="%1.0f%%")
        plt.close(fig)
        return True
    except Exception as exc:
        print(f"⚠ stack gráficos no OK: {type(exc).__name__}: {exc}")
        return False


def ensure_dependencies() -> None:
    """
    Garantiza psycopg2, dotenv y un matplotlib coherente con NumPy.
    Puede instalar paquetes con pip --user o crear un .venv del módulo 2.
    """
    import importlib.util
    import site
    import subprocess
    from pathlib import Path as PathLib

    module2 = PathLib(__file__).resolve().parent.parent
    venv_python = module2 / ".venv" / "bin" / "python"
    venv_sites = list((module2 / ".venv").glob("lib/python*/site-packages"))

    # Si existe .venv del módulo, priorizar sus site-packages en este proceso
    if venv_python.is_file() and PathLib(sys.executable).resolve() != venv_python.resolve():
        _prefer_paths([str(p) for p in venv_sites])

    try:
        _prefer_paths([site.getusersitepackages()])
    except Exception:
        pass

    # Drivers de BD y .env
    for mod, pkg in {"psycopg2": "psycopg2-binary", "dotenv": "python-dotenv"}.items():
        if importlib.util.find_spec(mod) is None:
            _pip([pkg], user=True)

    if _matplotlib_works():
        return

    print("→ Reparando NumPy + matplotlib (instalación coherente para el usuario)...")
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

    # Último recurso: venv aislado del módulo (no pelea con opencv/numpy2 del user)
    venv_dir = module2 / ".venv"
    print(f"→ Creando entorno virtual aislado: {venv_dir}")
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
        print("No se pudo crear/usar .venv:", exc, file=sys.stderr)
        print(
            "Haz a mano:\n"
            f"  cd {module2}\n"
            "  python3 -m venv .venv\n"
            "  source .venv/bin/activate\n"
            "  pip install 'numpy==1.26.4' matplotlib psycopg2-binary python-dotenv\n"
            "  cd ex00 && python pie.py\n",
            file=sys.stderr,
        )
        sys.exit(1)

    print(
        "\n✓ .venv listo. Vuelve a lanzar el script así:\n"
        f"  source {venv_dir}/bin/activate\n"
        "  cd ex00 && python pie.py\n"
        f"  # o:  {venv_dir}/bin/python {PathLib(__file__).resolve()}\n",
        file=sys.stderr,
    )
    sys.exit(0)


ensure_dependencies()

# ---------------------------------------------------------------------------
# Backend de matplotlib
# ---------------------------------------------------------------------------
# - Si el usuario exporta MPLBACKEND, se respeta (ej. MPLBACKEND=Agg).
# - Si NO hay DISPLAY (SSH sin reenvío X11) → Agg (solo fichero PNG).
# - Si HAY DISPLAY (puesto gráfico del campus) → backend por defecto
#   (TkAgg, Qt5Agg, …) y plt.show() abrirá una ventana.
# ---------------------------------------------------------------------------
import matplotlib

if not os.environ.get("MPLBACKEND") and not os.environ.get("DISPLAY"):
    matplotlib.use("Agg")

import matplotlib.pyplot as plt
import psycopg2
from dotenv import load_dotenv

# ===========================================================================
# Rutas del proyecto y credenciales (Module 0)
# ===========================================================================
SCRIPT_DIR = Path(__file__).resolve().parent
MODULE2_DIR = SCRIPT_DIR.parent


def find_env_file() -> Path | None:
    """
    Busca data_science_0_creation_db/ex00/.env en rutas típicas del monorepo
    y del campus (sgoinfre). Devuelve la primera ruta que exista o None.
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
    print("→ .env no encontrado; se usan variables de entorno / valores por defecto")

# Credenciales: subject Module 0 → user = login, password = mysecretpassword, db = piscineds
DB_CONFIG = {
    "host": os.environ.get("POSTGRES_HOST", "localhost"),
    "port": int(os.environ.get("POSTGRES_PORT", "5432")),
    "dbname": os.environ.get("POSTGRES_DB", "piscineds"),
    "user": os.environ.get("POSTGRES_USER", os.environ.get("USER", "")),
    "password": os.environ.get("POSTGRES_PASSWORD", "mysecretpassword"),
}

# ---------------------------------------------------------------------------
# SQL: una fila por event_type con el número de eventos en customers
# ---------------------------------------------------------------------------
# GROUP BY  en SQL evita traer ~19 millones de filas a Python solo para contar.
# ORDER BY n DESC  pone primero lo más frecuente (útil para la leyenda).
SQL_EVENT_COUNTS = """
SELECT event_type, COUNT(*) AS n
FROM customers
GROUP BY event_type
ORDER BY n DESC;
"""


def fetch_event_counts(conn) -> list[tuple[str, int]]:
    """
    Ejecuta SQL_EVENT_COUNTS y devuelve [(event_type, count), ...].

    conn: conexión psycopg2 ya abierta a piscineds.
    """
    with conn.cursor() as cur:
        cur.execute(SQL_EVENT_COUNTS)
        rows = cur.fetchall()
    return [(str(r[0]), int(r[1])) for r in rows]


def plot_pie(
    labels: list[str],
    sizes: list[int],
    out_path: Path | None = None,
) -> None:
    """
    Dibuja el pie chart del subject.

    labels : nombres de event_type (view, cart, …)
    sizes  : conteos absolutos (misma longitud y orden que labels)
    out_path : si se indica, guarda PNG (pie_chart.png)

    Layout compacto: figura horizontal, leyenda a la derecha, poco margen.
    """
    # Paleta legible (azul, verde, naranja, rojo, …)
    colors = ["#4C78A8", "#54A24B", "#F58518", "#E45756", "#B279A2", "#72B7B2"]

    fig, ax = plt.subplots(figsize=(7.2, 4.8), layout="constrained")

    wedges, _texts, autotexts = ax.pie(
        sizes,
        labels=None,
        autopct=lambda p: f"{p:.1f}%",  # porcentaje con 1 decimal dentro del sector
        startangle=90,  # el primer sector empieza “arriba”
        colors=colors[: len(sizes)],
        pctdistance=0.55,  # distancia del % al centro (0–1)
        radius=1.0,
        wedgeprops={"linewidth": 1.2, "edgecolor": "white"},
    )
    for txt in autotexts:
        txt.set_fontsize(11)
        txt.set_color("white")
        txt.set_fontweight("bold")

    ax.legend(
        wedges,
        [f"{lab}  ({n:,})" for lab, n in zip(labels, sizes)],
        title="event_type",
        loc="center left",
        bbox_to_anchor=(1.02, 0.5),  # leyenda a la derecha del pie
        frameon=False,
        fontsize=10,
        title_fontsize=11,
        borderaxespad=0.0,
        handlelength=1.2,
        labelspacing=0.6,
    )
    ax.set_title(
        "Qué hacen los usuarios en el sitio\n"
        "(event_type · tabla customers · Module 1)",
        fontsize=12,
        pad=8,
    )
    ax.axis("equal")  # círculo, no elipse
    ax.set_xticks([])
    ax.set_yticks([])
    for spine in ax.spines.values():
        spine.set_visible(False)

    if out_path is not None:
        fig.savefig(
            out_path,
            dpi=160,
            bbox_inches="tight",  # recorta márgenes en blanco del PNG
            pad_inches=0.15,
            facecolor="white",
        )
        print(f"→ Guardado: {out_path}")

    # Ventana interactiva si el backend lo permite (DISPLAY + TkAgg/Qt/…).
    # Con backend Agg es un no-op; el warning queda filtrado arriba.
    plt.show()
    plt.close(fig)


def main() -> None:
    """Punto de entrada: conectar → agregar → imprimir tabla → pie + PNG."""
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
        print(
            "¿Existe la tabla customers? Ejecuta Module 1 EX01 (y EX02/EX03 si aplica).",
            file=sys.stderr,
        )
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
