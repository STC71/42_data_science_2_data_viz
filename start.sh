#!/usr/bin/env bash
# ============================================================
# PISCINE PEDAGO - DATA SCIENCE
# Data Science 2 - Data Viz — ASISTENTE GLOBAL (raíz)
#
# INDEPENDIENTE de ex00…ex05/start.sh
#   • Estado Module 0 / .env / contenedor / entregas
#   • PostgreSQL, psql
#   • Lanzar pie / chart / mustache / Building / elbow / Clustering
#
# Uso:
#   ./start.sh
#   /ruta/a/data_science_2_data_viz/start.sh
#
# Este menú es AYUDA. Las entregas del subject son:
#   pie.* chart.* mustache.* Building.* elbow.* Clustering.*
# ============================================================

set -u

RESET='\033[0m'
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
CONTAINER_NAME="postgres_piscineds"

print_header() {
    clear
    echo
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}║  PISCINE PEDAGO - DATA SCIENCE - sternero - 42 Málaga      ║${RESET}"
    echo -e "${CYAN}${BOLD}║  Data Science 2 – Data Viz – Asistente GLOBAL              ║${RESET}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${WHITE}  Script:   ${SCRIPT_DIR}/start.sh${RESET}"
    echo -e "${WHITE}  Proyecto: ${PROJECT_DIR}${RESET}"
    echo
}

ask_yes_no() {
    local prompt="$1" default="$2" answer
    if [ "$default" = "s" ]; then
        read -r -p "$(echo -e "${YELLOW}${prompt} [S/n] → ${RESET}")" answer
        answer=${answer:-s}
    else
        read -r -p "$(echo -e "${YELLOW}${prompt} [s/N] → ${RESET}")" answer
        answer=${answer:-n}
    fi
    [[ "$answer" =~ ^[sS]$ ]]
}

pause() { echo; read -r -p "$(echo -e "${CYAN}Pulsa Enter...${RESET}")"; }

section() {
    echo
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}$1${RESET}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
}

ok()   { echo -e "${GREEN}✓ $1${RESET}"; }
warn() { echo -e "${YELLOW}⚠ $1${RESET}"; }
err()  { echo -e "${RED}✗ $1${RESET}"; }
info() { echo -e "${CYAN}→ $1${RESET}"; }

find_module0() {
    local c
    for c in \
        "$PROJECT_DIR/../data_science_0_creation_db" \
        "$PROJECT_DIR/../../data_science_0_creation_db" \
        "$HOME/sgoinfre/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db" \
        "$HOME/sgoinfre/students/$(id -un)/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db"
    do
        if [[ -f "$c/ex00/docker-compose.yml" ]] || [[ -f "$c/ex00/.env" ]]; then
            echo "$(cd -- "$c" && pwd)"
            return 0
        fi
    done
    return 1
}

MODULE0_DIR="$(find_module0 || true)"
ENV_FILE=""
[[ -n "${MODULE0_DIR:-}" && -f "$MODULE0_DIR/ex00/.env" ]] && ENV_FILE="$MODULE0_DIR/ex00/.env"

read_env() {
    POSTGRES_USER=""
    POSTGRES_PASSWORD=""
    POSTGRES_DB=""
    [[ -n "$ENV_FILE" && -f "$ENV_FILE" ]] || return 1
    POSTGRES_USER="$(sed -n 's/^POSTGRES_USER=//p' "$ENV_FILE" | head -n 1)"
    POSTGRES_PASSWORD="$(sed -n 's/^POSTGRES_PASSWORD=//p' "$ENV_FILE" | head -n 1)"
    POSTGRES_DB="$(sed -n 's/^POSTGRES_DB=//p' "$ENV_FILE" | head -n 1)"
    [[ -n "$POSTGRES_USER" && -n "$POSTGRES_DB" ]]
}

db_user() {
    if read_env; then echo "$POSTGRES_USER"; else id -un 2>/dev/null || whoami; fi
}

db_name() {
    if read_env; then echo "$POSTGRES_DB"; else echo "piscineds"; fi
}

container_up() {
    docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER_NAME"
}

status_env() {
    section "📊  Estado del Module 2"
    if [[ -n "${MODULE0_DIR:-}" ]]; then
        ok "Module 0: $MODULE0_DIR"
    else
        warn "Module 0 no localizado"
    fi
    if [[ -n "$ENV_FILE" ]]; then
        ok ".env USER=$(db_user) DB=$(db_name)"
    else
        warn ".env no encontrado"
    fi
    if container_up; then
        ok "Contenedor $CONTAINER_NAME Up"
    else
        warn "Contenedor $CONTAINER_NAME no está Up"
    fi
    echo
    echo -e "${BOLD}Entregas (subject)${RESET}"
    local pairs=(
        "ex00:pie.py"
        "ex01:chart.py"
        "ex02:mustache.py"
        "ex03:Building.py"
        "ex04:elbow.py"
        "ex05:Clustering.py"
    )
    local p dir file
    for p in "${pairs[@]}"; do
        dir="${p%%:*}"
        file="${p##*:}"
        if [[ -f "$PROJECT_DIR/$dir/$file" ]]; then
            ok "$dir/$file"
        else
            warn "Falta $dir/$file"
        fi
    done
    echo
    info "Este menú NO sustituye pie.* / chart.* / … / Clustering.*"
}

start_postgres() {
    section "🐘  PostgreSQL (Module 0)"
    if [[ -z "${MODULE0_DIR:-}" ]]; then
        err "No se encontró Module 0"
        return 1
    fi
    local compose="$MODULE0_DIR/ex00"
    if [[ ! -f "$compose/docker-compose.yml" ]]; then
        err "Sin docker-compose.yml en $compose"
        return 1
    fi
    info "cd $compose && docker compose up -d"
    ( cd "$compose" && docker compose up -d )
    sleep 2
    if container_up; then ok "Contenedor Up"; else warn "Revisa docker compose logs"; fi
}

open_psql() {
    section "💻  psql"
    if ! container_up; then
        warn "Contenedor parado. Usa la opción de levantar PostgreSQL."
        return 1
    fi
    local u d
    u="$(db_user)"
    d="$(db_name)"
    info "docker exec -it $CONTAINER_NAME psql -U $u -d $d"
    docker exec -it "$CONTAINER_NAME" psql -U "$u" -d "$d"
}

run_exercise() {
    local num="$1"
    local script="$2"
    local title="$3"
    local dir="$PROJECT_DIR/ex${num}"
    section "▶️  EX${num} – ${title}"
    if [[ ! -f "$dir/$script" ]]; then
        err "No está $dir/$script"
        return 1
    fi
    echo "  1) ventana (DISPLAY)   2) solo PNG (Agg)"
    local m
    read -r -p "[1/2] → " m
    echo
    if [[ "${m:-1}" == "2" ]]; then
        info "MPLBACKEND=Agg python3 $script"
        ( cd "$dir" && MPLBACKEND=Agg python3 "$script" )
    else
        info "python3 $script"
        ( cd "$dir" && python3 "$script" )
    fi
    echo
    ok "Fin EX${num}"
}

show_docs() {
    section "📘  Documentación"
    echo "  README del módulo:  $PROJECT_DIR/README.md"
    echo "  Por ejercicio:      ex00/README.md … ex05/README.md"
    echo "                      ex00/python.md  … ex05/python.md"
    echo
    echo "  Subject (entregas):"
    echo "    pie.*  chart.*  mustache.*  Building.*  elbow.*  Clustering.*"
}

main_menu() {
    while true; do
        print_header
        echo -e "  ${BOLD}MENÚ GLOBAL – Module 2 Data Viz${RESET}"
        echo
        echo "  1)  Estado del entorno y entregas"
        echo "  2)  Levantar PostgreSQL (Module 0)"
        echo "  3)  Abrir psql"
        echo "  4)  Ejecutar EX00 pie.py"
        echo "  5)  Ejecutar EX01 chart.py"
        echo "  6)  Ejecutar EX02 mustache.py"
        echo "  7)  Ejecutar EX03 Building.py"
        echo "  8)  Ejecutar EX04 elbow.py"
        echo "  9)  Ejecutar EX05 Clustering.py"
        echo "  d)  Documentación"
        echo "  q)  Salir"
        echo
        local o
        read -r -p "Opción → " o
        case "${o:-}" in
            1) status_env; pause ;;
            2) start_postgres; pause ;;
            3) open_psql; pause ;;
            4) run_exercise "00" "pie.py" "Pie"; pause ;;
            5) run_exercise "01" "chart.py" "Charts"; pause ;;
            6) run_exercise "02" "mustache.py" "Mustache"; pause ;;
            7) run_exercise "03" "Building.py" "Building"; pause ;;
            8) run_exercise "04" "elbow.py" "Elbow"; pause ;;
            9) run_exercise "05" "Clustering.py" "Clustering"; pause ;;
            d|D) show_docs; pause ;;
            q|Q) echo "Hasta luego."; exit 0 ;;
            *) warn "Opción no válida"; pause ;;
        esac
    done
}

# --- main ---
print_header
echo -e "Asistente ${BOLD}GLOBAL${RESET} del Module 2."
echo -e "Los menús de cada ${BOLD}ex0N/start.sh${RESET} siguen disponibles y más detallados."
echo
if ask_yes_no "¿Ver estado al arrancar?" "s"; then
    status_env
    pause
fi
main_menu
