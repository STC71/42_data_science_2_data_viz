#!/usr/bin/env bash
set -u
RESET='\033[0m'; BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; RED='\033[0;31m'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MODULE2_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONTAINER_NAME="postgres_piscineds"
PY="$SCRIPT_DIR/Building.py"

pause(){ echo; read -r -p "$(echo -e "${CYAN}Pulsa Enter...${RESET}")"; }
find_env(){
  for c in "$MODULE2_DIR/../data_science_0_creation_db/ex00/.env" \
    "$HOME/sgoinfre/students/$(id -un)/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db/ex00/.env"
  do [[ -f "$c" ]] && { echo "$c"; return; }; done
}
ENV_FILE="$(find_env || true)"
db_user(){ [[ -n "$ENV_FILE" ]] && sed -n 's/^POSTGRES_USER=//p' "$ENV_FILE" | head -1 || id -un; }
db_name(){ [[ -n "$ENV_FILE" ]] && sed -n 's/^POSTGRES_DB=//p' "$ENV_FILE" | head -1 || echo piscineds; }

echo -e "${CYAN}${BOLD}Module 2 – EX03 – Highest Building${RESET}"
while true; do
  echo
  echo -e "  ${BOLD}1)${RESET} SQL: usuarios con purchase"
  echo -e "  ${BOLD}2)${RESET} Ejecutar Building.py"
  echo -e "  ${BOLD}3)${RESET} psql"
  echo -e "  ${RED}${BOLD}q)${RESET} Salir"
  read -r -p "$(echo -e "${YELLOW}→ ${RESET}")" c
  case "$c" in
    1)
      docker exec -i "$CONTAINER_NAME" psql -U "$(db_user)" -d "$(db_name)" -c \
        "SELECT COUNT(DISTINCT user_id) AS buyers FROM customers WHERE event_type='purchase';"
      pause ;;
    2)
      echo -e "  ${BOLD}1)${RESET} ventana  ${BOLD}2)${RESET} Agg"
      read -r -p "$(echo -e "${YELLOW}[1/2] → ${RESET}")" m
      if [[ "$m" == "2" ]]; then ( cd "$SCRIPT_DIR" && MPLBACKEND=Agg python3 "$PY" )
      else ( cd "$SCRIPT_DIR" && python3 "$PY" ); fi
      pause ;;
    3) docker exec -it "$CONTAINER_NAME" psql -U "$(db_user)" -d "$(db_name)"; pause ;;
    q|Q) exit 0 ;;
  esac
done
