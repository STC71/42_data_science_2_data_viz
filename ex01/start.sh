#!/usr/bin/env bash
# Module 2 – EX01 – chart.* assistant
set -u
RESET='\033[0m'; BOLD='\033[1m'; RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MODULE2_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONTAINER_NAME="postgres_piscineds"
CHART_PY="$SCRIPT_DIR/chart.py"

ok(){ echo -e "${GREEN}✓ $1${RESET}"; }
warn(){ echo -e "${YELLOW}⚠ $1${RESET}"; }
err(){ echo -e "${RED}✗ $1${RESET}"; }
info(){ echo -e "${CYAN}→ $1${RESET}"; }
pause(){ echo; read -r -p "$(echo -e "${CYAN}Pulsa Enter...${RESET}")"; }
section(){ echo; echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; echo -e "${BOLD}$1${RESET}"; echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; echo; }

ask_yes_no(){
  local p="$1" d="$2" a
  if [ "$d" = "s" ]; then read -r -p "$(echo -e "${YELLOW}${p} [S/n] → ${RESET}")" a; a=${a:-s}
  else read -r -p "$(echo -e "${YELLOW}${p} [s/N] → ${RESET}")" a; a=${a:-n}; fi
  [[ "$a" =~ ^[sS]$ ]]
}

find_module0(){
  local c
  for c in \
    "$MODULE2_DIR/../data_science_0_creation_db" \
    "$HOME/sgoinfre/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db" \
    "$HOME/sgoinfre/students/$(id -un)/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db"
  do
    [[ -f "$c/ex00/.env" ]] && { echo "$(cd -- "$c" && pwd)"; return 0; }
  done
  return 1
}

MODULE0_DIR="$(find_module0 || true)"
ENV_FILE=""
[[ -n "$MODULE0_DIR" && -f "$MODULE0_DIR/ex00/.env" ]] && ENV_FILE="$MODULE0_DIR/ex00/.env"

db_user(){
  if [[ -n "$ENV_FILE" ]]; then sed -n 's/^POSTGRES_USER=//p' "$ENV_FILE" | head -1
  else id -un; fi
}
db_name(){
  if [[ -n "$ENV_FILE" ]]; then sed -n 's/^POSTGRES_DB=//p' "$ENV_FILE" | head -1
  else echo piscineds; fi
}

status_env(){
  section "Estado"
  [[ -n "$MODULE0_DIR" ]] && ok "Module 0: $MODULE0_DIR" || warn "Module 0 no encontrado"
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER_NAME"; then ok "Docker Up"
  else warn "Contenedor parado"; fi
  [[ -f "$CHART_PY" ]] && ok "chart.py" || err "Falta chart.py"
}

sql_purchase_check(){
  section "SQL purchase (rango subject)"
  docker exec -i "$CONTAINER_NAME" psql -U "$(db_user)" -d "$(db_name)" -c \
    "SELECT COUNT(*) AS purchases FROM customers
     WHERE event_type = 'purchase'
       AND event_time >= TIMESTAMP '2022-10-01'
       AND event_time <  TIMESTAMP '2023-03-01';"
  docker exec -i "$CONTAINER_NAME" psql -U "$(db_user)" -d "$(db_name)" -c \
    "SELECT date_trunc('month', event_time)::date AS m, COUNT(*), ROUND(SUM(price)::numeric,2)
     FROM customers
     WHERE event_type = 'purchase'
       AND event_time >= TIMESTAMP '2022-10-01'
       AND event_time <  TIMESTAMP '2023-03-01'
     GROUP BY 1 ORDER BY 1;"
}

run_chart(){
  section "Ejecutar chart.py"
  chmod +x "$CHART_PY" 2>/dev/null || true
  echo -e "  ${BOLD}1)${RESET} Con ventana  ${BOLD}2)${RESET} Solo PNG (Agg)"
  local c; read -r -p "$(echo -e "${YELLOW}[1/2] → ${RESET}")" c
  case "$c" in
    2) ( cd "$SCRIPT_DIR" && MPLBACKEND=Agg python3 "$CHART_PY" ) ;;
    *) ( cd "$SCRIPT_DIR" && python3 "$CHART_PY" ) ;;
  esac
}

print_header(){
  clear
  echo -e "${CYAN}${BOLD}Module 2 – EX01 – initial data exploration${RESET}"
  echo -e "  ${SCRIPT_DIR}"
  echo
}

show_menu(){
  echo
  echo -e "${CYAN}${BOLD}  EX01 – menú${RESET}"
  echo -e "  ${BOLD}1)${RESET} Estado"
  echo -e "  ${BOLD}2)${RESET} SQL: purchase por mes"
  echo -e "  ${BOLD}3)${RESET} Ejecutar chart.py"
  echo -e "  ${BOLD}4)${RESET} psql"
  echo -e "  ${BOLD}5)${RESET} Docs"
  echo -e "  ${RED}${BOLD}q)${RESET} Salir"
  echo
}

main(){
  print_header
  while true; do
    show_menu
    local choice; read -r -p "$(echo -e "${YELLOW}Opción → ${RESET}")" choice
    case "$choice" in
      1) status_env; pause ;;
      2) sql_purchase_check; pause ;;
      3) run_chart; pause ;;
      4) docker exec -it "$CONTAINER_NAME" psql -U "$(db_user)" -d "$(db_name)"; pause ;;
      5) echo "README: $SCRIPT_DIR/README.md"; echo "Guía: $SCRIPT_DIR/python.md"; pause ;;
      q|Q) exit 0 ;;
      *) warn "Opción no válida" ;;
    esac
  done
}
main "$@"
