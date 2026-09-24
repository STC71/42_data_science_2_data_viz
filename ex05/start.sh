#!/usr/bin/env bash

# ============================================================
# PISCINE PEDAGO - DATA SCIENCE
# Module 2 – Data Viz – EX05 Clustering
#
# sternero – 42 Málaga – 2026
#
# Asistente opcional (NO sustituye Clustering.*)
# - Estado del entorno (Module 0 .env, Docker, DISPLAY)
# - PostgreSQL: arranque si hace falta
# - SQL de control: nº de compradores (RFM base)
# - Ejecutar Clustering.py (ventana o solo PNG)
# - psql, verificar entrega Clustering.*, documentación
#
# Uso:
#   cd /ruta/a/data_science_2_data_viz/ex05
#   chmod +x start.sh
#   ./start.sh
#
#   cd ~/sgoinfre/.../piscine_pedago_data_science/data_science_2_data_viz/ex05
#   chmod +x start.sh; ./start.sh
# ============================================================

set -u

RESET=$'\033[0m'
BOLD=$'\033[1m'
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'
MAGENTA=$'\033[0;35m'
WHITE=$'\033[1;37m'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MODULE2_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONTAINER_NAME="postgres_piscineds"
CLUSTER_PY="$SCRIPT_DIR/Clustering.py"

print_header()
{
    clear
    echo
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}║  Module 2 – Data Viz – EX05 Clustering                     ║${RESET}"
    echo -e "${CYAN}${BOLD}║  sternero – 42 Málaga                                      ║${RESET}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${WHITE}  $SCRIPT_DIR${RESET}"
    echo
}

ask_yes_no()
{
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

section()
{
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

find_module0()
{
    local c
    for c in \
        "$MODULE2_DIR/../data_science_0_creation_db" \
        "$MODULE2_DIR/../../data_science_0_creation_db" \
        "$HOME/sgoinfre/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db" \
        "$HOME/sgoinfre/students/$(id -un)/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db"
    do
        if [[ -f "$c/ex00/.env" ]] || [[ -f "$c/ex00/docker-compose.yml" ]]; then
            echo "$(cd -- "$c" && pwd)"
            return 0
        fi
    done
    return 1
}

MODULE0_DIR="$(find_module0 || true)"
ENV_FILE=""
[[ -n "$MODULE0_DIR" && -f "$MODULE0_DIR/ex00/.env" ]] && ENV_FILE="$MODULE0_DIR/ex00/.env"

read_env()
{
    POSTGRES_USER=""
    POSTGRES_DB=""
    [[ -n "$ENV_FILE" && -f "$ENV_FILE" ]] || return 1
    POSTGRES_USER="$(sed -n 's/^POSTGRES_USER=//p' "$ENV_FILE" | head -n 1)"
    POSTGRES_DB="$(sed -n 's/^POSTGRES_DB=//p' "$ENV_FILE" | head -n 1)"
    [[ -n "$POSTGRES_USER" && -n "$POSTGRES_DB" ]]
}

db_user() { if read_env; then echo "$POSTGRES_USER"; else id -un 2>/dev/null || whoami; fi; }
db_name() { if read_env; then echo "$POSTGRES_DB"; else echo "piscineds"; fi; }

container_up()
{
    command -v docker >/dev/null 2>&1 \
        && docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER_NAME"
}

status_env()
{
    section "📊  Estado"
    if [[ -n "$MODULE0_DIR" ]]; then ok "Module 0: $MODULE0_DIR"; else warn "Module 0 no localizado"; fi
    if read_env; then ok ".env USER=$POSTGRES_USER DB=$POSTGRES_DB"; else warn "Sin .env"; fi
    if container_up; then ok "Contenedor $CONTAINER_NAME Up"; else warn "Contenedor parado (opción 2)"; fi
    if [[ -f "$CLUSTER_PY" ]]; then ok "Clustering.py presente"; else err "Falta Clustering.py"; fi
    if python3 -c "import sklearn" 2>/dev/null; then ok "scikit-learn importable"; else warn "Falta scikit-learn (Clustering.py intentará instalar)"; fi
    [[ -n "${DISPLAY:-}" ]] && info "DISPLAY=$DISPLAY" || info "Sin DISPLAY → Agg / solo PNG"
}

start_postgres()
{
    section "🐘  PostgreSQL (Module 0)"
    if [[ -z "$MODULE0_DIR" || ! -f "$MODULE0_DIR/ex00/docker-compose.yml" ]]; then
        err "No hay docker-compose de Module 0"; return 1
    fi
    if container_up; then ok "Ya Up"; return 0; fi
    if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER_NAME"; then
        ask_yes_no "¿docker start $CONTAINER_NAME?" "s" && docker start "$CONTAINER_NAME" && sleep 2
        return 0
    fi
    if ask_yes_no "¿docker compose up -d?" "s"; then
        if command -v docker-compose >/dev/null 2>&1; then
            ( cd "$MODULE0_DIR/ex00" && docker-compose up -d )
        else
            ( cd "$MODULE0_DIR/ex00" && docker compose up -d )
        fi
        sleep 3
    fi
}

sql_buyers()
{
    section "👥  Compradores (base RFM)"
    if ! container_up; then err "Sin contenedor"; return 1; fi
    docker exec -i "$CONTAINER_NAME" psql -U "$(db_user)" -d "$(db_name)" -c \
        "SELECT COUNT(DISTINCT user_id) AS buyers
         FROM customers
         WHERE event_type = 'purchase';"
}

run_elbow()
{
    section "📐  Ejecutar Clustering.py"
    if [[ ! -f "$CLUSTER_PY" ]]; then err "Falta $CLUSTER_PY"; return 1; fi
    chmod +x "$CLUSTER_PY" 2>/dev/null || true
    echo -e "  ${BOLD}1)${RESET} ventana   ${BOLD}2)${RESET} solo PNG (Agg)"
    local c
    read -r -p "$(echo -e "${YELLOW}[1/2] → ${RESET}")" c
    case "$c" in
        2) ( cd "$SCRIPT_DIR" && MPLBACKEND=Agg python3 "$CLUSTER_PY" ) ;;
        *) ( cd "$SCRIPT_DIR" && python3 "$CLUSTER_PY" ) ;;
    esac
    local rc=$?
    [[ -f "$SCRIPT_DIR/customers_per_cluster.png" ]] && ok "customers_per_cluster.png"
    [[ $rc -eq 0 ]] && ok "Clustering.py OK" || err "código $rc"
}

open_psql()
{
    section "💻  psql"
    if ! container_up; then err "Sin contenedor"; return 1; fi
    docker exec -it "$CONTAINER_NAME" psql -U "$(db_user)" -d "$(db_name)"
}

check_delivery()
{
    section "📋  Entrega Clustering.*"
    if ls "$SCRIPT_DIR"/Clustering.* >/dev/null 2>&1; then
        ok "Clustering.* en ex05/"
        ls -la "$SCRIPT_DIR"/Clustering.* 2>/dev/null || true
    else
        err "Falta Clustering.*"
    fi
}

show_docs()
{
    section "📘  Documentación"
    echo "  README:  $SCRIPT_DIR/README.md"
    echo "  Guía:    $SCRIPT_DIR/python.md"
    echo "  Module:  $MODULE2_DIR/README.md"
    if [[ -f "$SCRIPT_DIR/python.md" ]] && ask_yes_no "¿Mostrar índice de python.md?" "n"; then
        grep -E '^## |^### ' "$SCRIPT_DIR/python.md" 2>/dev/null | head -n 40
    fi
}

show_menu()
{
    echo
    echo -e "${CYAN}${BOLD}  MENÚ EX05 – Clustering${RESET}"
    echo
    echo -e "  ${BOLD}1)${RESET}  Estado del entorno"
    echo -e "  ${BOLD}2)${RESET}  Levantar PostgreSQL (Module 0)"
    echo -e "  ${BOLD}3)${RESET}  SQL: compradores (RFM)"
    echo -e "  ${BOLD}4)${RESET}  Ejecutar Clustering.py ${WHITE}(recomendado)${RESET}"
    echo -e "  ${BOLD}5)${RESET}  Abrir psql"
    echo -e "  ${BOLD}6)${RESET}  Verificar Clustering.*"
    echo -e "  ${BOLD}7)${RESET}  Documentación"
    echo -e "  ${BOLD}p)${RESET}  chmod +x Clustering.py / start.sh"
    echo -e "  ${RED}${BOLD}q)${RESET}  ${RED}Salir${RESET}"
    echo
}

menu_loop()
{
    local choice
    echo -e "Subject: ${BOLD}Clustering (KMeans + etiquetas)${RESET} → ≥ 4 grupos de clientes (RFM + KMeans)."
    echo -e "Entrega: ${BOLD}Clustering.*${RESET}  ${WHITE}(este menú NO sustituye Clustering.*)${RESET}"
    echo
    echo -e "  ${WHITE}Idea:${RESET} resumir cada cliente en Recency / Frequency / Monetary,"
    echo -e "  crear k=5 grupos (new, inactive, silver, gold, platinum) y dibujarlos."
    while true; do
        show_menu
        read -r -p "$(echo -e "${YELLOW}Opción → ${RESET}")" choice
        echo
        case "$choice" in
            1) status_env; pause ;;
            2) start_postgres; pause ;;
            3) sql_buyers; pause ;;
            4) run_elbow; pause ;;
            5) open_psql; pause ;;
            6) check_delivery; pause ;;
            7) show_docs; pause ;;
            p|P) chmod +x "$SCRIPT_DIR/start.sh" "$CLUSTER_PY" 2>/dev/null; ok "chmod +x"; pause ;;
            q|Q) echo -e "${GREEN}Hasta luego.${RESET}"; exit 0 ;;
            *) warn "Opción no válida" ;;
        esac
    done
}

main()
{
    print_header
    info "Asistente EX04 (Module 2) · RFM + KMeans + grupos de negocio · fuente: customers"
    echo
    if ask_yes_no "¿Ver estado al arrancar?" "s"; then status_env; fi
    menu_loop
}

main "$@"
