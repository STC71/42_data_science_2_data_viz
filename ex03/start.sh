#!/usr/bin/env bash

# ============================================================
# PISCINE PEDAGO - DATA SCIENCE
# Module 2 – Data Viz – EX03 Highest Building
#
# sternero – 42 Málaga – Octubre 2026
#
# Asistente opcional (NO sustituye Building.*)
# - Estado del entorno (Module 0 .env, Docker, DISPLAY)
# - PostgreSQL: arranque si hace falta
# - SQL de control: frequency (bins) y monetary (tramos)
# - Ejecutar Building.py (ventana o solo PNG)
# - psql, verificar entrega Building.*, documentación
#
# Uso:
#   cd /ruta/a/data_science_2_data_viz/ex03
#   chmod +x start.sh
#   ./start.sh
#
#   # o en el monorepo del campus:
#   cd ~/sgoinfre/.../piscine_pedago_data_science/data_science_2_data_viz/ex03
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
BUILDING_PY="$SCRIPT_DIR/Building.py"

print_header()
{
    clear
    echo
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}║  Module 2 – Data Viz – EX03 – Highest Building             ║${RESET}"
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
    if read_env; then ok ".env USER=$POSTGRES_USER DB=$POSTGRES_DB"; else warn "Sin .env (defaults: login / piscineds)"; fi
    if container_up; then
        ok "Contenedor $CONTAINER_NAME Up"
    else
        warn "Contenedor no está corriendo (opción 2)"
    fi
    if [[ -f "$BUILDING_PY" ]]; then ok "Building.py presente"; else err "Falta Building.py"; fi
    if [[ -f "$SCRIPT_DIR/building_frequency.png" ]]; then ok "PNG frequency ya generado"; fi
    if [[ -f "$SCRIPT_DIR/building_monetary.png" ]]; then ok "PNG monetary ya generado"; fi
    if [[ -n "${DISPLAY:-}" ]]; then info "DISPLAY=$DISPLAY (posible ventana gráfica)"; else info "Sin DISPLAY → usa Agg / solo PNG"; fi
}

start_postgres()
{
    section "🐘  PostgreSQL (Module 0)"
    if [[ -z "$MODULE0_DIR" || ! -f "$MODULE0_DIR/ex00/docker-compose.yml" ]]; then
        err "No hay docker-compose de Module 0"
        return 1
    fi
    if container_up; then
        ok "Ya Up"
        return 0
    fi
    if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER_NAME"; then
        if ask_yes_no "¿docker start $CONTAINER_NAME?" "s"; then
            docker start "$CONTAINER_NAME" && sleep 2
            container_up && ok "Arrancado" || err "No arrancó"
        fi
        return 0
    fi
    if ask_yes_no "¿docker compose up -d en Module 0 ex00?" "s"; then
        if command -v docker-compose >/dev/null 2>&1; then
            ( cd "$MODULE0_DIR/ex00" && docker-compose up -d )
        else
            ( cd "$MODULE0_DIR/ex00" && docker compose up -d )
        fi
        sleep 3
        container_up && ok "Up" || err "Revisa docker logs"
    fi
}

sql_buyers()
{
    section "👥  Compradores distintos (purchase)"
    if ! container_up; then err "Sin contenedor"; return 1; fi
    docker exec -i "$CONTAINER_NAME" \
        psql -U "$(db_user)" -d "$(db_name)" -c \
        "SELECT COUNT(DISTINCT user_id) AS buyers
         FROM customers
         WHERE event_type = 'purchase';"
}

sql_frequency_preview()
{
    section "🔢  Frequency (muestra: bins 1–10 y 30+)"
    if ! container_up; then err "Sin contenedor"; return 1; fi
    docker exec -i "$CONTAINER_NAME" \
        psql -U "$(db_user)" -d "$(db_name)" -c \
        "WITH per_user AS (
             SELECT user_id, COUNT(*)::int AS freq
             FROM customers
             WHERE event_type = 'purchase'
             GROUP BY user_id
         ),
         capped AS (
             SELECT CASE WHEN freq >= 30 THEN 30 ELSE freq END AS freq_bin
             FROM per_user
         )
         SELECT freq_bin,
                COUNT(*) AS n_customers
         FROM capped
         WHERE freq_bin <= 10 OR freq_bin = 30
         GROUP BY freq_bin
         ORDER BY freq_bin;"
    info "La barra 30 agrupa frequency >= 30 (etiqueta 30+ en el gráfico)."
}

sql_monetary_preview()
{
    section "💰  Monetary (clientes por tramo de gasto total)"
    if ! container_up; then err "Sin contenedor"; return 1; fi
    docker exec -i "$CONTAINER_NAME" \
        psql -U "$(db_user)" -d "$(db_name)" -c \
        "WITH per_user AS (
             SELECT user_id, SUM(price) AS total_spent
             FROM customers
             WHERE event_type = 'purchase' AND price IS NOT NULL
             GROUP BY user_id
         ),
         binned AS (
             SELECT CASE
                 WHEN total_spent >= 0   AND total_spent < 50  THEN '0–50'
                 WHEN total_spent >= 50  AND total_spent < 100 THEN '50–100'
                 WHEN total_spent >= 100 AND total_spent < 150 THEN '100–150'
                 WHEN total_spent >= 150 AND total_spent < 200 THEN '150–200'
                 ELSE '200+'
             END AS tramo
             FROM per_user
         )
         SELECT tramo, COUNT(*) AS n_customers
         FROM binned
         GROUP BY tramo
         ORDER BY MIN(tramo);"
}

run_building()
{
    section "🏗️  Ejecutar Building.py"
    if [[ ! -f "$BUILDING_PY" ]]; then
        err "Falta $BUILDING_PY"
        return 1
    fi
    chmod +x "$BUILDING_PY" 2>/dev/null || true
    echo -e "  ${BOLD}1)${RESET}  Con ventana (si hay DISPLAY)"
    echo -e "  ${BOLD}2)${RESET}  Solo PNG (MPLBACKEND=Agg)"
    echo
    local choice
    read -r -p "$(echo -e "${YELLOW}[1/2] → ${RESET}")" choice
    case "$choice" in
        2)
            info "Backend Agg…"
            ( cd "$SCRIPT_DIR" && MPLBACKEND=Agg python3 "$BUILDING_PY" )
            ;;
        *)
            info "Backend por defecto…"
            ( cd "$SCRIPT_DIR" && python3 "$BUILDING_PY" )
            ;;
    esac
    local rc=$?
    echo
    if [[ -f "$SCRIPT_DIR/building_frequency.png" ]]; then ok "building_frequency.png"; else warn "Sin building_frequency.png"; fi
    if [[ -f "$SCRIPT_DIR/building_monetary.png" ]]; then ok "building_monetary.png"; else warn "Sin building_monetary.png"; fi
    [[ $rc -eq 0 ]] && ok "Building.py terminó (código 0)" || err "Building.py salió con código $rc"
}

open_psql()
{
    section "💻  psql interactivo"
    if ! container_up; then err "Sin contenedor"; return 1; fi
    info "Saliendo: \\q"
    docker exec -it "$CONTAINER_NAME" psql -U "$(db_user)" -d "$(db_name)"
}

check_delivery()
{
    section "📋  Entrega subject (Building.*)"
    local found=0
    if [[ -f "$BUILDING_PY" ]]; then
        ok "Building.py"
        found=1
    fi
    if ls "$SCRIPT_DIR"/Building.* >/dev/null 2>&1; then
        ls -la "$SCRIPT_DIR"/Building.* 2>/dev/null || true
        found=1
    fi
    if [[ $found -eq 0 ]]; then
        err "Falta Building.* en ex03/"
    else
        info "Subject: turn-in directory ex03/ · files Building.*"
    fi
}

show_docs()
{
    section "📘  Documentación"
    echo "  README:     $SCRIPT_DIR/README.md"
    echo "  Guía:       $SCRIPT_DIR/python.md"
    echo "  Script:     $BUILDING_PY"
    echo "  Module 2:   $MODULE2_DIR/README.md"
    echo
    if [[ -f "$SCRIPT_DIR/python.md" ]] && ask_yes_no "¿Mostrar el índice de python.md?" "n"; then
        grep -E '^## |^### |^\-\-\-$' "$SCRIPT_DIR/python.md" 2>/dev/null | head -n 40 || head -n 30 "$SCRIPT_DIR/python.md"
    fi
}

show_menu()
{
    echo
    echo -e "${CYAN}${BOLD}  EX03 – Highest Building · menú${RESET}"
    echo
    echo -e "  ${BOLD}1)${RESET}  Estado del entorno"
    echo -e "  ${BOLD}2)${RESET}  Levantar PostgreSQL (Module 0)"
    echo -e "  ${BOLD}3)${RESET}  SQL: compradores distintos"
    echo -e "  ${BOLD}4)${RESET}  SQL: frequency (preview bins)"
    echo -e "  ${BOLD}5)${RESET}  SQL: monetary (tramos de gasto)"
    echo -e "  ${BOLD}6)${RESET}  Ejecutar Building.py"
    echo -e "  ${BOLD}7)${RESET}  Abrir psql"
    echo -e "  ${BOLD}8)${RESET}  Verificar Building.*"
    echo -e "  ${BOLD}9)${RESET}  Documentación (README / python.md)"
    echo -e "  ${BOLD}p)${RESET}  chmod +x Building.py / start.sh"
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
            3) sql_buyers; pause ;;
            4) sql_frequency_preview; pause ;;
            5) sql_monetary_preview; pause ;;
            6) run_building; pause ;;
            7) open_psql; pause ;;
            8) check_delivery; pause ;;
            9) show_docs; pause ;;
            p|P)
                chmod +x "$SCRIPT_DIR/start.sh" "$BUILDING_PY" 2>/dev/null
                ok "chmod +x aplicado"
                pause
                ;;
            q|Q) echo -e "${GREEN}Hasta luego.${RESET}"; exit 0 ;;
            *) warn "Opción no válida" ;;
        esac
    done
}

main()
{
    print_header
    info "Asistente EX03 (Module 2) – frequency & monetary · fuente: customers (warehouse Module 1)"
    echo
    if ask_yes_no "¿Ver estado al arrancar?" "s"; then
        status_env
    fi
    menu_loop
}

main "$@"
