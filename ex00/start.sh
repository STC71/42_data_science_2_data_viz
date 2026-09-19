#!/usr/bin/env bash

# ============================================================
# Module 2 – Data Viz – EX00 (American apple Pie)
# Asistente local: entorno, pie.py, comprobaciones
# sternero - 42 Málaga - Octubre 2026
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
PIE_PY="$SCRIPT_DIR/pie.py"

print_header()
{
    clear
    echo
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}║  Module 2 – Data Viz – EX00 – American apple Pie           ║${RESET}"
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

status_env()
{
    section "📊  Estado"
    if [[ -n "$MODULE0_DIR" ]]; then ok "Module 0: $MODULE0_DIR"; else warn "Module 0 no localizado"; fi
    if read_env; then ok ".env USER=$POSTGRES_USER DB=$POSTGRES_DB"; else warn "Sin .env"; fi
    if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER_NAME"; then
        ok "Contenedor $CONTAINER_NAME Up"
    else
        warn "Contenedor no está corriendo"
    fi
    if [[ -f "$PIE_PY" ]]; then ok "pie.py presente"; else err "Falta pie.py"; fi
}

start_postgres()
{
    section "🐘  PostgreSQL (Module 0)"
    if [[ -z "$MODULE0_DIR" || ! -f "$MODULE0_DIR/ex00/docker-compose.yml" ]]; then
        err "No hay docker-compose de Module 0"
        return 1
    fi
    if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        ok "Ya Up"
        return 0
    fi
    if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        ask_yes_no "¿docker start $CONTAINER_NAME?" "s" && docker start "$CONTAINER_NAME" && sleep 2
        return 0
    fi
    if ask_yes_no "¿docker-compose up -d?" "s"; then
        if command -v docker-compose >/dev/null 2>&1; then
            ( cd "$MODULE0_DIR/ex00" && docker-compose up -d )
        else
            ( cd "$MODULE0_DIR/ex00" && docker compose up -d )
        fi
        sleep 2
    fi
}

sql_event_counts()
{
    section "🔢  COUNT por event_type"
    if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        err "Sin contenedor"
        return 1
    fi
    docker exec -i "$CONTAINER_NAME" \
        psql -U "$(db_user)" -d "$(db_name)" -c \
        "SELECT event_type, COUNT(*) AS n FROM customers GROUP BY event_type ORDER BY n DESC;"
}

run_pie()
{
    section "🥧  Ejecutar pie.py"
    if [[ ! -f "$PIE_PY" ]]; then
        err "Falta $PIE_PY"
        return 1
    fi
    if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        err "Contenedor parado — opción 2"
        return 1
    fi
    chmod +x "$PIE_PY" 2>/dev/null || true
    echo -e "  ${BOLD}1)${RESET} Con ventana (plt.show)  ${BOLD}2)${RESET} Solo PNG (MPLBACKEND=Agg)"
    local c
    read -r -p "$(echo -e "${YELLOW}Elige [1/2] → ${RESET}")" c
    case "$c" in
        2)
            ( cd "$SCRIPT_DIR" && MPLBACKEND=Agg python3 "$PIE_PY" )
            ;;
        *)
            ( cd "$SCRIPT_DIR" && python3 "$PIE_PY" )
            ;;
    esac
    if [[ -f "$SCRIPT_DIR/pie_chart.png" ]]; then
        ok "Generado pie_chart.png"
    fi
}

open_psql()
{
    section "💻  psql"
    docker exec -it "$CONTAINER_NAME" psql -U "$(db_user)" -d "$(db_name)"
}

check_delivery()
{
    section "📋  Entrega subject"
    if [[ -f "$PIE_PY" ]] || ls "$SCRIPT_DIR"/pie.* >/dev/null 2>&1; then
        ok "pie.* en ex00/"
        ls -la "$SCRIPT_DIR"/pie.* 2>/dev/null || true
    else
        err "Falta pie.*"
    fi
}

show_docs()
{
    section "📘  Documentación"
    echo "  README:    $SCRIPT_DIR/README.md"
    echo "  Guía:      $SCRIPT_DIR/python.md"
    echo "  Module 2:  $MODULE2_DIR/README.md"
    if ask_yes_no "¿Mostrar las primeras líneas de python.md?" "n"; then
        head -n 40 "$SCRIPT_DIR/python.md" 2>/dev/null || warn "No hay python.md"
    fi
}

show_menu()
{
    echo
    echo -e "${CYAN}${BOLD}  EX00 – menú${RESET}"
    echo
    echo -e "  ${BOLD}1)${RESET}  Estado del entorno"
    echo -e "  ${BOLD}2)${RESET}  Levantar PostgreSQL (Module 0)"
    echo -e "  ${BOLD}3)${RESET}  SQL: COUNT por event_type"
    echo -e "  ${BOLD}4)${RESET}  Ejecutar pie.py"
    echo -e "  ${BOLD}5)${RESET}  Abrir psql"
    echo -e "  ${BOLD}6)${RESET}  Verificar pie.*"
    echo -e "  ${BOLD}7)${RESET}  Documentación (README / python.md)"
    echo -e "  ${BOLD}p)${RESET}  chmod +x pie.py / start.sh"
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
            3) sql_event_counts; pause ;;
            4) run_pie; pause ;;
            5) open_psql; pause ;;
            6) check_delivery; pause ;;
            7) show_docs; pause ;;
            p|P)
                chmod +x "$SCRIPT_DIR/start.sh" "$PIE_PY" 2>/dev/null
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
    info "Asistente EX00 – pie chart event_type (Data Warehouse Module 1)"
    echo
    if ask_yes_no "¿Ver estado al arrancar?" "s"; then
        status_env
    fi
    menu_loop
}

main "$@"
