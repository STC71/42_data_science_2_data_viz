#!/usr/bin/env bash
set -u
RESET='\033[0m'; BOLD='\033[1m'; RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MODULE2_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONTAINER_NAME="postgres_piscineds"
PY="$SCRIPT_DIR/mustache.py"

ok(){ echo -e "${GREEN}✓ $1${RESET}"; }
warn(){ echo -e "${YELLOW}⚠ $1${RESET}"; }
err(){ echo -e "${RED}✗ $1${RESET}"; }
pause(){ echo; read -r -p "$(echo -e "${CYAN}Pulsa Enter...${RESET}")"; }
section(){ echo; echo -e "${MAGENTA}━━━ $1 ━━━${RESET}"; echo; }

find_env(){
  local c
  for c in "$MODULE2_DIR/../data_science_0_creation_db/ex00/.env" \
    "$HOME/sgoinfre/students/$(id -un)/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db/ex00/.env"
  do [[ -f "$c" ]] && { echo "$c"; return; }; done
}
ENV_FILE="$(find_env || true)"
db_user(){ [[ -n "$ENV_FILE" ]] && sed -n 's/^POSTGRES_USER=//p' "$ENV_FILE" | head -1 || id -un; }
db_name(){ [[ -n "$ENV_FILE" ]] && sed -n 's/^POSTGRES_DB=//p' "$ENV_FILE" | head -1 || echo piscineds; }

echo -e "${CYAN}${BOLD}Module 2 – EX02 – mustache${RESET}"
while true; do
  echo
  echo -e "  ${BOLD}1)${RESET} SQL: describe prices"
  echo -e "  ${BOLD}2)${RESET} Ejecutar mustache.py"
  echo -e "  ${BOLD}3)${RESET} psql"
  echo -e "  ${RED}${BOLD}q)${RESET} Salir"
  read -r -p "$(echo -e "${YELLOW}→ ${RESET}")" c
  case "$c" in
    1)
      docker exec -i "$CONTAINER_NAME" psql -U "$(db_user)" -d "$(db_name)" -c \
        "SELECT COUNT(*) AS n, ROUND(AVG(price)::numeric,4) AS mean,
                ROUND(MIN(price)::numeric,4) AS min, ROUND(MAX(price)::numeric,4) AS max
         FROM customers WHERE event_type='purchase' AND price IS NOT NULL;"
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
