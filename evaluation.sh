#!/usr/bin/env bash
###############################################################################
# DATA SCIENCE 2 – Data Viz · evaluation.sh
#
# Guía interactiva basada en en.subject.pdf / evaluation_en_2.pdf.
# Verifica entregables, entorno, código, artefactos y demostración visual.
#
# sternero – 42 Málaga – Octubre 2026
#
###############################################################################

set -u

readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[1;33m'
readonly CYAN=$'\033[0;36m'
readonly MAGENTA=$'\033[0;35m'
readonly BOLD=$'\033[1m'
readonly DIM=$'\033[2m'
readonly RESET=$'\033[0m'

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

declare -A RESULT
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
LAST_RESULT_KIND="info"
LAST_RESULT_TEXT="Evaluación iniciada"
STOP_EVAL=false
EX04_K=""

CONTAINER_NAME="${DS_CONTAINER_NAME:-postgres_piscineds}"
DB_NAME="${POSTGRES_DB:-piscineds}"
DB_USER="${POSTGRES_USER:-$(id -un 2>/dev/null || whoami)}"

header() {
  clear 2>/dev/null || true
  echo -e "${BOLD}${YELLOW}DATA SCIENCE 2 – Data Viz · DEFENSA / EVALUATION${RESET}"
  echo "╔══════════════════════════════════════════════════════════════════╗"
  echo "║  DATA SCIENCE 2 – Data Viz · DEFENSA / EVALUATION                ║"
  echo "║  Escala: /PROJECTS/DATA-SCIENCE-2                                ║"
  echo "╚══════════════════════════════════════════════════════════════════╝"
  echo
  echo -e "  ${DIM}Repo: $SCRIPT_DIR${RESET}"
  echo -e "  ${DIM}Login: $(id -un 2>/dev/null || whoami) · $(date '+%Y-%m-%d %H:%M')${RESET}"
  echo
}

section() { echo; echo -e "${BOLD}${CYAN}▶ $1${RESET}"; echo -e "${CYAN}────────────────────────────────────────────────────────────────${RESET}"; echo; }
subsection() { echo -e "  ${MAGENTA}├─ $1${RESET}"; }
ctx() { echo -e "  ${DIM}$1${RESET}"; }
info() { echo -e "    ${CYAN}ℹ${RESET} $1"; }
requirement() { echo -e "    ${MAGENTA}▸ Criterio para la evaluación:${RESET} $1"; }
note() { echo -e "    ${DIM}→ $1${RESET}"; }
show_cmd() { echo -e "    ${DIM}${BOLD}\$${RESET} ${YELLOW}$1${RESET}"; }
show_code_reference() {
  local file="$1" line="${2:-}"
  if [[ -n "$line" ]]; then
    echo -e "    ${DIM}Código: ${file##*/}, línea $line${RESET}"
  else
    echo -e "    ${DIM}Archivo: ${file##*/}${RESET}"
  fi
}
ok() { LAST_RESULT_KIND=success; LAST_RESULT_TEXT="$1"; echo -e "    ${GREEN}✓${RESET} $1"; ((PASS_COUNT++)) || true; }
fail() { LAST_RESULT_KIND=error; LAST_RESULT_TEXT="$1"; echo -e "    ${RED}✗${RESET} $1"; ((FAIL_COUNT++)) || true; }
warn() { LAST_RESULT_KIND=warning; LAST_RESULT_TEXT="$1"; echo -e "    ${YELLOW}⚠${RESET} $1"; ((WARN_COUNT++)) || true; }

show_last_result() {
  case "$LAST_RESULT_KIND" in
    success) echo -e "  ${GREEN}${BOLD}✅ Último resultado: éxito${RESET}" ;;
    error) echo -e "  ${RED}${BOLD}❌ Último resultado: error${RESET}" ;;
    warning) echo -e "  ${YELLOW}${BOLD}⚠ Último resultado: advertencia${RESET}" ;;
    *) echo -e "  ${CYAN}${BOLD}ℹ Último resultado${RESET}" ;;
  esac
  echo -e "  ${DIM}$LAST_RESULT_TEXT${RESET}"
  echo -e "  ${DIM}Acumulado: OK=$PASS_COUNT · Errores=$FAIL_COUNT · Avisos=$WARN_COUNT${RESET}"
  echo
}

redraw_after_continue() {
  header
  show_last_result
}

pause() {
  read -r -p "$(echo -e "${CYAN}Pulsa Enter para continuar…${RESET}")"
  redraw_after_continue
}

ask_yes_no() {
  local prompt="$1" default="${2:-n}" answer
  if [[ "$default" == s ]]; then
    read -r -p "  $prompt [S/n] → " answer
    answer="${answer:-s}"
  else
    read -r -p "  $prompt [s/N] → " answer
    answer="${answer:-n}"
  fi
  [[ "$answer" =~ ^[sSyY]$ ]]
}

find_module0() {
  local candidate
  for candidate in \
    "$SCRIPT_DIR/../data_science_0_creation_db" \
    "$SCRIPT_DIR/../../data_science_0_creation_db" \
    "$HOME/sgoinfre/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db" \
    "$HOME/sgoinfre/students/$(id -un 2>/dev/null || whoami)/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db"
  do
    [[ -f "$candidate/ex00/docker-compose.yml" ]] && (cd "$candidate" && pwd) && return 0
  done
  return 1
}

MODULE0_DIR="$(find_module0 || true)"
if [[ -n "$MODULE0_DIR" && -f "$MODULE0_DIR/ex00/.env" ]]; then
  DB_USER="$(sed -n 's/^POSTGRES_USER=//p' "$MODULE0_DIR/ex00/.env" | head -1)"
  DB_NAME="$(sed -n 's/^POSTGRES_DB=//p' "$MODULE0_DIR/ex00/.env" | head -1)"
fi

docker_psql() {
  docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -At -v ON_ERROR_STOP=1 -c "$1"
}

check_layout() {
  section "0 · Repositorio y entregables"
  local required=0 f
  for f in README.md start.sh ex00 ex01 ex02 ex03 ex04 ex05; do
    if [[ -e "$SCRIPT_DIR/$f" ]]; then ok "Encontrado: $f"; ((required++)) || true
    else fail "Falta en la raíz: $f"; fi
  done
  local pair dir stem
  for pair in "ex00:pie" "ex01:chart" "ex02:mustache" "ex03:Building" "ex04:elbow" "ex05:Clustering"; do
    dir="${pair%%:*}"; stem="${pair##*:}"
    if [[ -f "$SCRIPT_DIR/$dir/$stem.py" ]]; then
      ok "Entregable encontrado: $dir/$stem.py"
    else
      fail "Falta $dir/$stem.*"
    fi
  done
  [[ "$required" -eq 8 ]] && RESULT[layout]=yes || RESULT[layout]=no
}

check_environment() {
  section "1 · PostgreSQL y Data Warehouse del Module 1"
  if ! command -v docker >/dev/null 2>&1; then
    fail "docker no está disponible"
    RESULT[env]=no; STOP_EVAL=true; return
  fi
  show_cmd "docker ps -a --filter \"name=^/${CONTAINER_NAME}$\""
  if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    ok "$CONTAINER_NAME está ejecutándose"
  else
    fail "$CONTAINER_NAME no está ejecutándose"
    if [[ -n "$MODULE0_DIR" ]] && ask_yes_no "¿Intentar levantar PostgreSQL desde Module 0?" "s"; then
      show_cmd "cd \"$MODULE0_DIR/ex00\" && docker compose up -d"
      (cd "$MODULE0_DIR/ex00" && docker compose up -d) || true
    else
      note "Comando manual: cd \"$MODULE0_DIR/ex00\" && docker compose up -d"
    fi
  fi
  if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    fail "PostgreSQL sigue sin estar disponible"
    RESULT[env]=no; STOP_EVAL=true; return
  fi
  show_cmd "docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c '\\conninfo'"
  if docker_psql '\conninfo' >/dev/null 2>&1; then ok "Conexión a $DB_NAME operativa"; else fail "No se pudo conectar a $DB_NAME"; RESULT[env]=no; STOP_EVAL=true; return; fi
  show_cmd "SELECT to_regclass('public.customers');"
  local customers
  customers="$(docker_psql "SELECT to_regclass('public.customers');" 2>/dev/null || true)"
  if [[ "$customers" == "customers" ]]; then
    ok "Tabla customers disponible para Module 2"
    RESULT[customers]=yes
  else
    fail "Falta public.customers; completa Module 1 antes de Module 2"
    RESULT[customers]=no; STOP_EVAL=true
  fi
  [[ "$STOP_EVAL" == false ]] && RESULT[env]=yes
}

explain_match() {
  local match="$1" line="${match%%:*}" code="${match#*:}"
  echo -e "      ${YELLOW}${BOLD}Código · línea $line:${RESET} $code"
  case "$code" in
    *psycopg2.connect*) echo -e "      ${CYAN}↳ Función:${RESET} abre la conexión con PostgreSQL/Data Warehouse." ;;
    *GROUP\ BY\ event_type*) echo -e "      ${CYAN}↳ Función:${RESET} agrupa los eventos por tipo de acción." ;;
    *COUNT*DISTINCT*user_id*) echo -e "      ${CYAN}↳ Función:${RESET} cuenta clientes distintos, no filas repetidas." ;;
    *WHERE\ event_type*purchase*) echo -e "      ${CYAN}↳ Función:${RESET} limita el análisis exclusivamente a compras." ;;
    *date_trunc*) echo -e "      ${CYAN}↳ Función:${RESET} agrupa las compras por mes." ;;
    *SUM*price*) echo -e "      ${CYAN}↳ Función:${RESET} calcula el importe total de las compras." ;;
    *AVG*price*) echo -e "      ${CYAN}↳ Función:${RESET} calcula el precio medio por usuario." ;;
    *np.percentile*) echo -e "      ${CYAN}↳ Función:${RESET} calcula cuartiles para las estadísticas." ;;
    *ax.pie*) echo -e "      ${CYAN}↳ Función:${RESET} dibuja el gráfico de sectores." ;;
    *ax.boxplot*) echo -e "      ${CYAN}↳ Función:${RESET} dibuja un box plot." ;;
    *ax.bar*) echo -e "      ${CYAN}↳ Función:${RESET} dibuja barras para comparar categorías o intervalos." ;;
    *KMeans*) echo -e "      ${CYAN}↳ Función:${RESET} aplica el algoritmo KMeans." ;;
    *StandardScaler*) echo -e "      ${CYAN}↳ Función:${RESET} normaliza las variables antes de agrupar." ;;
    *inertia*) echo -e "      ${CYAN}↳ Función:${RESET} obtiene la inertia/WCSS usada por la curva elbow." ;;
    *savefig*) echo -e "      ${CYAN}↳ Función:${RESET} guarda el gráfico como archivo PNG." ;;
    *) echo -e "      ${CYAN}↳ Función:${RESET} aporta evidencia relacionada con el criterio revisado." ;;
  esac
}

dynamic_check() {
  local file="$1" pattern="$2" description="$3" matches first_line
  if [[ ! -f "$SCRIPT_DIR/$file" ]]; then fail "Falta $file"; return; fi
  echo -e "    ${BOLD}${CYAN}Archivo revisado: $SCRIPT_DIR/$file${RESET}"
  info "Qué debe comprobarse: $description"
  matches="$(grep -nE "$pattern" "$SCRIPT_DIR/$file" | grep -vE 'ax\.pie\(\[1, 2, 3\]' | head -10 || true)"
  if [[ -n "$matches" ]]; then
    info "Evidencia localizada en el código (amarillo = código, cian = función):"
    while IFS= read -r match; do
      explain_match "$match"
    done <<< "$matches"
    first_line="${matches%%:*}"
    show_code_reference "$file" "$first_line"
    ok "La implementación contiene la lógica necesaria"
  else
    fail "No se encontró la lógica esperada en $file"
  fi
}

review_exercise() {
  local exercise="$1" file="$2" pattern="$3" explanation="$4" scale_requirement="$5"
  section "$exercise · revisión dinámica del código"
  requirement "$scale_requirement"
  info "Objetivo: $explanation"
  info "Archivo que debe abrirse para la revisión:"
  show_code_reference "$file"
  dynamic_check "$file" "$pattern" "$explanation"
  if [[ "$LAST_RESULT_KIND" == error ]]; then
    RESULT[static]=no
  elif [[ "${RESULT[static]:-yes}" != no ]]; then
    RESULT[static]=yes
  fi
}

check_cluster_consistency() {
  section "3b · Coherencia EX04 → EX05"
  ctx "Esta comprobación se hace después de revisar EX04 y EX05: primero se observa"
  ctx "la curva elbow, después se explica la elección y finalmente se comprueba que"
  ctx "EX05 reutiliza exactamente el mismo número de clusters."
  info "El subject exige al menos 4 grupos para distinguir clientes nuevos, inactivos"
  info "y varios niveles de fidelidad (por ejemplo silver, gold y platinum)."
  info "Este proyecto elige k=5 porque la curva se suaviza en esa zona y permite"
  info "representar esos cinco segmentos de negocio: new, inactive, silver, gold y platinum."
  info "No significa que 5 sea una regla universal: debe defenderse observando la curva"
  info "y explicando el equilibrio entre separar perfiles y evitar grupos innecesarios."
  local ex04_k ex05_k
  ex04_k="$(sed -nE 's/^[[:space:]]*SELECTED_K[[:space:]]*=[[:space:]]*([0-9]+).*/\1/p' "$SCRIPT_DIR/ex04/elbow.py" | head -1)"
  ex05_k="$(sed -nE 's/^[[:space:]]*N_CLUSTERS[[:space:]]*=[[:space:]]*([0-9]+).*/\1/p' "$SCRIPT_DIR/ex05/Clustering.py" | head -1)"
  show_cmd "grep -nE 'SELECTED_K|N_CLUSTERS' ex04/elbow.py ex05/Clustering.py"
  if [[ -z "$ex04_k" || -z "$ex05_k" ]]; then
    fail "No se pudo localizar el k seleccionado en EX04 y EX05"
    RESULT[cluster_consistency]=no
  elif [[ "$ex04_k" == "$ex05_k" && "$ex04_k" -ge 4 ]]; then
    ok "EX04 y EX05 usan el mismo k=$ex04_k (y cumple el mínimo de 4)"
    RESULT[cluster_consistency]=yes
    EX04_K="$ex04_k"
  else
    fail "Incoherencia: EX04 usa k=$ex04_k y EX05 usa k=$ex05_k"
    RESULT[cluster_consistency]=no
  fi
}

run_exercise() {
  local exercise="$1" file="$2" outputs="$3" explanation="$4" command choice output
  section "$exercise · ejecución guiada"
  ctx "$explanation"
  show_cmd "cd \"$SCRIPT_DIR/$(dirname "$file")\" && MPLBACKEND=Agg python3 \"$(basename "$file")\""
  note "El modo Agg genera PNG sin exigir una ventana gráfica; el evaluador puede usar python3 sin MPLBACKEND si dispone de DISPLAY."
  IFS=',' read -r -a expected_outputs <<< "$outputs"
  for output in "${expected_outputs[@]}"; do
    show_cmd "ls -lh \"$SCRIPT_DIR/$(dirname "$file")/$output\""
  done
  if ! ask_yes_no "¿Ejecutar ahora $exercise?" "s"; then
    warn "$exercise omitido"
    RESULT[$exercise]=no
    return
  fi
  command="cd \"$SCRIPT_DIR/$(dirname "$file")\" && MPLBACKEND=Agg python3 \"$(basename "$file")\""
  show_cmd "$command"
  if (cd "$SCRIPT_DIR/$(dirname "$file")" && MPLBACKEND=Agg python3 "$(basename "$file")"); then
    local missing=0
    for output in "${expected_outputs[@]}"; do
      if [[ ! -s "$SCRIPT_DIR/$(dirname "$file")/$output" ]]; then
        fail "$exercise no generó $output"
        missing=1
      fi
    done
    if [[ "$missing" -eq 0 ]]; then
      ok "$exercise ejecutado y todos sus artefactos generados: ${outputs//,/ · }"
      RESULT[$exercise]=yes
    else
      RESULT[$exercise]=no
    fi
  else
    fail "$exercise falló al ejecutarse"
    RESULT[$exercise]=no
  fi
}

confirm_visual() {
  local exercise="$1" outputs="$2" question="$3" output
  section "$exercise · demostración visual y defensa"
  IFS=',' read -r -a expected_outputs <<< "$outputs"
  for output in "${expected_outputs[@]}"; do
    show_cmd "xdg-open \"$SCRIPT_DIR/$output\""
  done
  info "Abre todos los PNG o muestra las ventanas generadas y compáralos con el subject."
  if ask_yes_no "$question" "n"; then
    ok "$exercise demostrado visualmente"
    RESULT[${exercise}_visual]=yes
  else
    fail "$exercise no se ha demostrado visualmente"
    RESULT[${exercise}_visual]=no
  fi
}

run_pipeline() {
  section "3 · Ejecución opcional de entregables"
  ctx "Cada ejercicio se revisa, explica y ejecuta por separado, solo tras confirmación."
  review_exercise EX00 ex00/pie.py "psycopg2\\.connect|GROUP BY event_type|ax\\.pie|savefig" "Conexión al warehouse → agrupación de customers por event_type → pie chart → pie_chart.png." "Leer el código, comprobar la conexión al Data Warehouse y ejecutar el programa para que se genere un pie_chart.png"
  run_exercise EX00 ex00/pie.py pie_chart.png "Cuenta event_type en customers: cada porción representa una acción del sitio."
  pause
  review_exercise EX01 ex01/chart.py "COUNT\\(DISTINCT user_id\\)|event_type = 'purchase'|date_trunc|SUM\\(price\\)|savefig" "Filtro purchase → clientes distintos por día → ventas mensuales → gasto medio por cliente → tres PNG." "Comprobar que solo se recogen datos purchase y ejecutar el código para obtener 3 gráficos."
  run_exercise EX01 ex01/chart.py chart_customers_daily.png,chart_sales_monthly.png,chart_avg_spend_daily.png "Filtra solo purchase y produce clientes/día, ventas/mes y gasto medio."
  pause
  review_exercise EX02 ex02/mustache.py "SQL_ITEM_PRICES|SELECT user_id, AVG\\(price\\)|np\\.percentile|ax\\.boxplot|savefig" "Precios de artículos purchase → estadísticas y cuartiles → precio medio por usuario → dos box plots." "Comprobar purchase, estadísticas y box plot de precios; después, box plot de la cesta media por usuario y su explicación."
  run_exercise EX02 ex02/mustache.py mustache_item_price.png,mustache_basket.png "Calcula stats y box plots del precio de ítem y del precio medio de cesta por usuario."
  pause
  review_exercise EX03 ex03/Building.py "SQL_FREQUENCY|SQL_MONETARY|ax\\.bar|savefig" "Compras purchase → distribución de frecuencia → distribución monetaria → dos bar charts." "Comprobar que se han generado 2 bar charts con la misma información que el subject."
  run_exercise EX03 ex03/Building.py building_frequency.png,building_monetary.png "Produce barras de frecuencia de compras y gasto monetario por cliente."
  pause
  review_exercise EX04 ex04/elbow.py "K_MIN|K_MAX|KMeans|inertia_|SELECTED_K|savefig" "RFM → KMeans para varios k → inertia/WCSS → curva elbow → elección justificada de k." "Mostrar la curva elbow y explicar cuántos clusters se conservan y por qué."
  run_exercise EX04 ex04/elbow.py elbow_method.png "Calcula inertia para varios k; el evaluador debe justificar el codo elegido."
  pause
  review_exercise EX05 ex05/Clustering.py "SQL_RFM|StandardScaler|n_clusters=N_CLUSTERS|savefig" "RFM purchase → StandardScaler → KMeans con el k de EX04 → etiquetas de negocio → dos gráficos." "Explicar el algoritmo, usar el mismo número de clusters que EX04, mostrar al menos 2 gráficos y explicar cada grupo."
  run_exercise EX05 ex05/Clustering.py customers_per_cluster.png,clusters_frequency_monetary.png "Aplica RFM, StandardScaler y KMeans; debe mantener el k justificado en EX04."
  pause
  check_cluster_consistency
}

check_visual_and_explanations() {
  section "4 · Evidencias visuales y explicación"
  confirm_visual EX00 ex00/pie_chart.png "¿Se ha mostrado un pie chart funcional conectado a customers?" 
  confirm_visual EX01 ex01/chart_customers_daily.png,ex01/chart_sales_monthly.png,ex01/chart_avg_spend_daily.png "¿Se han mostrado los tres gráficos de EX01, con datos purchase y febrero incluido?"
  confirm_visual EX02 ex02/mustache_item_price.png,ex02/mustache_basket.png "¿Se han mostrado ambos box plots y explicado mean, mediana, cuartiles y outliers?"
  confirm_visual EX03 ex03/building_frequency.png,ex03/building_monetary.png "¿Se han mostrado los dos bar charts con la información del subject?"
  confirm_visual EX04 ex04/elbow_method.png "¿Se ha mostrado la curva elbow y explicado el número de clusters elegido?"
  confirm_visual EX05 ex05/customers_per_cluster.png,ex05/clusters_frequency_monetary.png "¿Se han mostrado al menos dos gráficos, el mismo número de clusters y el significado de cada grupo?"
}

summary() {
  section "5 · Resumen para Intra"
  printf "  %-22s %s\n" "Repositorio" "${RESULT[layout]:-—}"
  printf "  %-22s %s\n" "PostgreSQL/customers" "${RESULT[env]:-—}/${RESULT[customers]:-—}"
  printf "  %-22s %s\n" "Revisión de código" "${RESULT[static]:-—}"
  for exercise in EX00 EX01 EX02 EX03 EX04 EX05; do
    printf "  %-22s %s / visual %s\n" "$exercise" "${RESULT[$exercise]:-—}" "${RESULT[${exercise}_visual]:-—}"
  done
  echo
  echo -e "  ${GREEN}OK=$PASS_COUNT${RESET}  ${RED}Errores=$FAIL_COUNT${RESET}  ${YELLOW}Avisos=$WARN_COUNT${RESET}"
  echo
  if [[ "${RESULT[layout]:-}" == yes && "${RESULT[env]:-}" == yes \
    && "${RESULT[customers]:-}" == yes && "${RESULT[static]:-}" == yes \
    && "${RESULT[cluster_consistency]:-}" == yes \
    && "$STOP_EVAL" == false && "$FAIL_COUNT" -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}✅ RESULTADO FINAL: EVALUACIÓN SUPERADA${RESET}"
  else
    echo -e "  ${RED}${BOLD}❌ RESULTADO FINAL: EVALUACIÓN NO SUPERADA${RESET}"
  fi
  echo -e "  ${DIM}Resultado orientativo: la decisión oficial corresponde a la escala y al evaluador.${RESET}"
}

main() {
  header
  section "Guías oficiales"
  ctx "evaluation_en_2.pdf y en.subject.pdf son las fuentes de esta guía."
  ctx "La demostración visual y la explicación del evaluador son obligatorias; un PNG existente no basta por sí solo."
  pause
  check_layout
  pause
  check_environment
  [[ "$STOP_EVAL" == true ]] && { summary; exit 0; }
  pause
  run_pipeline
  pause
  check_visual_and_explanations
  summary
}

main "$@"
