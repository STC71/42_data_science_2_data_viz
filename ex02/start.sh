#!/usr/bin/env bash

# ============================================================
# PISCINE PEDAGO - DATA SCIENCE
# Module 2 – Data Viz – EX02 My beautiful mustache
#
# sternero – 42 Málaga – Octubre2026
#
# Asistente opcional (NO sustituye mustache.*)
# - Estado del entorno (Module 0 .env, Docker, DISPLAY)
# - PostgreSQL: arranque si hace falta
# - SQL de control: stats de price y nº de cestas
# - Ejecutar mustache.py (ventana o solo PNG)
# - psql, verificar entrega mustache.*, documentación
#
# Uso:
#   cd /ruta/a/data_science_2_data_viz/ex02
#   chmod +x start.sh
#   ./start.sh
#
#   # o en el monorepo del campus:
#   cd ~/sgoinfre/.../piscine_pedago_data_science/data_science_2_data_viz/ex02
#   chmod +x start.sh; ./start.sh
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
MODULE2_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONTAINER_NAME="postgres_piscineds"
MUSTACHE_PY="$SCRIPT_DIR/mustache.py"

print_header()
{
    clear
    echo
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}║  Module 2 – Data Viz – EX02 – My beautiful mustache        ║${RESET}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${WHITE}  ${SCRIPT_DIR}${RESET}"
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
        if [[ -f "$c/ex00/docker-compose.yml" ]] || [[ -f "$c/ex00/.env" ]]; then
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
    if [[ -f "$MUSTACHE_PY" ]]; then ok "mustache.py presente"; else err "Falta mustache.py"; fi
    [[ -f "$SCRIPT_DIR/mustache_item_price.png" ]] && ok "PNG item price"
    [[ -f "$SCRIPT_DIR/mustache_basket.png" ]] && ok "PNG basket"
    if [[ -n "${DISPLAY:-}" ]]; then info "DISPLAY=$DISPLAY"; else info "Sin DISPLAY → Agg / solo PNG"; fi
}

start_postgres()
{
    section "🐘  PostgreSQL (Module 0)"
    if [[ -z "$MODULE0_DIR" || ! -f "$MODULE0_DIR/ex00/docker-compose.yml" ]]; then
        err "No hay docker-compose de Module 0"
        return 1
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

sql_price_stats()
{
    section "📈  Stats SQL de price (purchase)"
    if ! container_up; then err "Sin contenedor"; return 1; fi
    docker exec -i "$CONTAINER_NAME" \
        psql -U "$(db_user)" -d "$(db_name)" -c \
        "SELECT COUNT(*) AS n,
                ROUND(AVG(price)::numeric, 4) AS mean,
                ROUND(STDDEV_SAMP(price)::numeric, 4) AS std,
                ROUND(MIN(price)::numeric, 4) AS min,
                ROUND(MAX(price)::numeric, 4) AS max
         FROM customers
         WHERE event_type = 'purchase' AND price IS NOT NULL;"
}

sql_basket_count()
{
    section "🛒  Usuarios con al menos una compra (cestas)"
    if ! container_up; then err "Sin contenedor"; return 1; fi
    docker exec -i "$CONTAINER_NAME" \
        psql -U "$(db_user)" -d "$(db_name)" -c \
        "SELECT COUNT(*) AS baskets
         FROM (
             SELECT user_id
             FROM customers
             WHERE event_type = 'purchase' AND price IS NOT NULL
             GROUP BY user_id
         ) t;"
}

run_mustache()
{
    section "📦  Ejecutar mustache.py"
    if [[ ! -f "$MUSTACHE_PY" ]]; then err "Falta $MUSTACHE_PY"; return 1; fi
    chmod +x "$MUSTACHE_PY" 2>/dev/null || true
    echo -e "  ${BOLD}1)${RESET}  Con ventana  ${BOLD}2)${RESET}  Solo PNG (Agg)"
    local choice
    read -r -p "$(echo -e "${YELLOW}[1/2] → ${RESET}")" choice
    case "$choice" in
        2) ( cd "$SCRIPT_DIR" && MPLBACKEND=Agg python3 "$MUSTACHE_PY" ) ;;
        *) ( cd "$SCRIPT_DIR" && python3 "$MUSTACHE_PY" ) ;;
    esac
    local rc=$?
    [[ -f "$SCRIPT_DIR/mustache_item_price.png" ]] && ok "mustache_item_price.png"
    [[ -f "$SCRIPT_DIR/mustache_basket.png" ]] && ok "mustache_basket.png"
    [[ $rc -eq 0 ]] && ok "mustache.py OK" || err "código $rc"
}

open_psql()
{
    section "💻  psql"
    if ! container_up; then err "Sin contenedor"; return 1; fi
    docker exec -it "$CONTAINER_NAME" psql -U "$(db_user)" -d "$(db_name)"
}

check_delivery()
{
    section "📋  Entrega mustache.*"
    if ls "$SCRIPT_DIR"/mustache.* >/dev/null 2>&1; then
        ok "mustache.* en ex02/"
        ls -la "$SCRIPT_DIR"/mustache.* 2>/dev/null || true
    else
        err "Falta mustache.*"
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
    echo -e "${CYAN}${BOLD}  EX02 – mustache · menú${RESET}"
    echo
    echo -e "  ${BOLD}1)${RESET}  Estado del entorno"
    echo -e "  ${BOLD}2)${RESET}  Levantar PostgreSQL"
    echo -e "  ${BOLD}3)${RESET}  SQL: stats de price"
    echo -e "  ${BOLD}4)${RESET}  SQL: nº de cestas (user_id)"
    echo -e "  ${BOLD}5)${RESET}  Ejecutar mustache.py"
    echo -e "  ${BOLD}6)${RESET}  Abrir psql"
    echo -e "  ${BOLD}7)${RESET}  Verificar mustache.*"
    echo -e "  ${BOLD}8)${RESET}  Documentación"
    echo -e "  ${BOLD}p)${RESET}  chmod +x"
    echo -e "  ${RED}${BOLD}q)${RESET}  Salir"
    echo
}

menu_loop()
{
    local choice
    while true; do
        show_menu
        read -r -p "$(echo -e "${YELLOW}Opción → ${RESET}")" choice
        echo
        case "$choice" in
            1) status_env; pause ;;
            2) start_postgres; pause ;;
            3) sql_price_stats; pause ;;
            4) sql_basket_count; pause ;;
            5) run_mustache; pause ;;
            6) open_psql; pause ;;
            7) check_delivery; pause ;;
            8) show_docs; pause ;;
            p|P) chmod +x "$SCRIPT_DIR/start.sh" "$MUSTACHE_PY" 2>/dev/null; ok "chmod +x"; pause ;;
            q|Q) echo -e "${GREEN}Hasta luego.${RESET}"; exit 0 ;;
            *) warn "Opción no válida" ;;
        esac
    done
}

main()
{
    print_header
    info "Asistente EX02 (Module 2) – box plots · fuente: customers (warehouse Module 1)"
    echo
    if ask_yes_no "¿Ver estado al arrancar?" "s"; then status_env; fi
    menu_loop
}

main "$@"
