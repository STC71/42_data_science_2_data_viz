#!/usr/bin/env bash
###############################################################################
#  DATA SCIENCE 2 – Data Viz · evaluation.sh
#
#  Guía interactiva de defensa basada en:
#    · en.subject.pdf  (Training Piscine datascience - 2 · Data Viz)
#    · evaluation_en_2.pdf  (hoja de evaluación /PROJECTS/DATA-SCIENCE-2)
#
#  Este fichero NO es entregable del subject ni forma parte de la nota.
#  Solo ayuda a prepararse y a recorrer la defensa paso a paso.
#
#  Uso (desde la raíz del repo del evaluado):
#    chmod +x evaluation.sh
#    ./evaluation.sh
#
#  sternero – 42 Málaga – Octubre 2026
###############################################################################

set -u
# no set -e: un fallo de comprobación no debe abortar toda la defensa

# ============================================================================
# COLORES Y FORMATO
# ============================================================================
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[1;33m'
readonly BLUE=$'\033[0;34m'
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
STOP_EVAL=false
EX04_K=""
LAST_KIND="info"
LAST_TEXT="Evaluación iniciada"

CONTAINER_NAME="${DS_CONTAINER_NAME:-postgres_piscineds}"
DB_NAME="${POSTGRES_DB:-piscineds}"
DB_USER="${POSTGRES_USER:-$(id -un 2>/dev/null || whoami)}"

# ============================================================================
# SALIDA
# ============================================================================
header() {
  clear 2>/dev/null || true
  echo -e "${BOLD}${YELLOW}"
  echo "╔══════════════════════════════════════════════════════════════════╗"
  echo "║  DATA SCIENCE 2 – Data Viz · DEFENSA / EVALUACIÓN                ║"
  echo "║  Hoja : /PROJECTS/DATA-SCIENCE-2                                 ║"
  echo "║  Guía : evaluation.sh (NO es entregable ni parte de la nota)     ║"
  echo "║  Autor: sternero – 42 Málaga – Octubre 2026                      ║"
  echo "╚══════════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "  ${DIM}Repo: ${SCRIPT_DIR}${RESET}"
  echo -e "  ${DIM}Login: $(id -un 2>/dev/null || whoami) · $(date '+%Y-%m-%d %H:%M')${RESET}"
  echo
}

section() {
  echo
  echo
  echo -e "${BOLD}${CYAN}▶ $1${RESET}"
  echo -e "${CYAN}────────────────────────────────────────────────────────────────${RESET}"
  echo
}

subsection() { echo -e "  ${MAGENTA}├─ $1${RESET}"; }
ctx()        { echo -e "  ${DIM}$1${RESET}"; }
ctx_blank()  { echo; echo; }
ok()   { LAST_KIND=success; LAST_TEXT="$1"; echo -e "    ${GREEN}✓${RESET} $1"; ((PASS_COUNT++)) || true; }
fail() { LAST_KIND=error;   LAST_TEXT="$1"; echo -e "    ${RED}✗${RESET} $1"; ((FAIL_COUNT++)) || true; }
warn() { LAST_KIND=warning; LAST_TEXT="$1"; echo -e "    ${YELLOW}⚠${RESET} $1"; ((WARN_COUNT++)) || true; }
info() { echo -e "    ${CYAN}ℹ${RESET} $1"; }
note() { echo -e "    ${DIM}→ $1${RESET}"; }
requirement() { echo -e "    ${MAGENTA}▸ Criterio (hoja de evaluación):${RESET} $1"; }

# "$" literal del prompt (NO usar $$ → eso es el PID del proceso)
show_cmd() {
  echo -e "    ${DIM}${BOLD}\$${RESET} ${YELLOW}$1${RESET}"
}

pause() {
  echo
  read -r -p "$(echo -e "${CYAN}Pulsa Enter para continuar…${RESET}")"
  header
  case "$LAST_KIND" in
    success) echo -e "  ${GREEN}${BOLD}✅ Último: éxito${RESET}" ;;
    error)   echo -e "  ${RED}${BOLD}❌ Último: error${RESET}" ;;
    warning) echo -e "  ${YELLOW}${BOLD}⚠ Último: aviso${RESET}" ;;
    *)       echo -e "  ${CYAN}${BOLD}ℹ Continuación (no es un reinicio)${RESET}" ;;
  esac
  echo -e "  ${DIM}${LAST_TEXT}${RESET}"
  echo -e "  ${DIM}Acumulado: OK=$PASS_COUNT · Errores=$FAIL_COUNT · Avisos=$WARN_COUNT${RESET}"
  echo
}

# s = sí · n = no · k = omitir · Enter = sí si default=s, no si default=n
ask_yes_no() {
  local prompt="$1"
  local default="${2:-n}"
  local ans
  if [[ "$default" == "s" ]]; then
    read -r -p "$(echo -e "  ${prompt} ${GREEN}[S/n]${RESET} → ")" ans
    ans="${ans:-s}"
  else
    read -r -p "$(echo -e "  ${prompt} ${YELLOW}[s/N]${RESET} → ")" ans
    ans="${ans:-n}"
  fi
  [[ "$ans" =~ ^[sSyY]$ ]]
}

# Pregunta formal de la hoja (guarda en RESULT)
ask_scale() {
  local key="$1"
  local prompt="$2"
  local ans
  echo
  echo -e "  ${BOLD}${prompt}${RESET}"
  while true; do
    read -r -p "  ${GREEN}s${RESET}/${RED}n${RESET}  (${YELLOW}k${RESET}=omitir) → " ans
    case "${ans:-s}" in
      s|S|y|Y|sí|Sí|SI|si)
        RESULT["$key"]="yes"
        ok "Marcado SÍ en la hoja de evaluación"
        return 0
        ;;
      n|N|no|No|NO)
        RESULT["$key"]="no"
        fail "Marcado NO en la hoja de evaluación"
        return 1
        ;;
      k|K)
        RESULT["$key"]="skip"
        warn "Omitido por el evaluador"
        return 2
        ;;
      *)
        echo -e "    ${YELLOW}Responde s (sí), n (no) o k (omitir)${RESET}"
        ;;
    esac
  done
}

# ============================================================================
# ENTORNO: Module 0 / PostgreSQL / customers
# ============================================================================
find_module0() {
  local c
  for c in \
    "$SCRIPT_DIR/../data_science_0_creation_db" \
    "$SCRIPT_DIR/../../data_science_0_creation_db" \
    "$HOME/sgoinfre/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db" \
    "$HOME/sgoinfre/students/$(id -un 2>/dev/null || whoami)/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db"
  do
    if [[ -f "$c/ex00/docker-compose.yml" ]]; then
      (cd "$c" && pwd)
      return 0
    fi
  done
  return 1
}

MODULE0_DIR="$(find_module0 || true)"
if [[ -n "${MODULE0_DIR}" && -f "${MODULE0_DIR}/ex00/.env" ]]; then
  _u="$(sed -n 's/^POSTGRES_USER=//p' "${MODULE0_DIR}/ex00/.env" | head -1)"
  _d="$(sed -n 's/^POSTGRES_DB=//p' "${MODULE0_DIR}/ex00/.env" | head -1)"
  [[ -n "$_u" ]] && DB_USER="$_u"
  [[ -n "$_d" ]] && DB_NAME="$_d"
fi

find_pg_container() {
  docker ps --format '{{.Names}}' 2>/dev/null | grep -iE 'postgres|piscine' | head -1 || true
}

docker_psql() {
  docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -At -v ON_ERROR_STOP=1 -c "$1" 2>/dev/null
}

# ============================================================================
# PREÁMBULO
# ============================================================================
preamble() {
  section "0 · Antes de empezar (guidelines de la hoja)"

  echo -e "  ${BOLD}¿Qué es este módulo?${RESET}"
  ctx "El analista de datos traduce números en dibujos para que el equipo entienda el negocio."
  ctx "Analogía: el Module 1 dejó la despensa ordenada (tabla customers)."
  ctx "Aquí solo cocinamos gráficos: tartas, líneas, cajas, barras y grupos de clientes."
  ctx_blank

  echo -e "  ${BOLD}¿Qué es evaluation.sh?${RESET}"
  ctx "Es una GUÍA de defensa (checklist hablado). NO es entregable del subject."
  ctx "NO forma parte de la nota en Intra. Si menciona reglas, es para explicarlas."
  ctx "Solo se evalúa el trabajo en el Git del estudiante (ex00…ex05 y sus pie.*, chart.*, …)."
  ctx_blank

  echo -e "  ${BOLD}Recordatorio para el evaluador:${RESET}"
  note "Solo evaluar lo que está en el Git del estudiante"
  note "git clone en carpeta vacía; comprobar que el repo es el suyo"
  note "Revisar aliases raros si algo no cuadra"
  note "Si no has hecho este módulo, lee el subject completo antes"
  note "Flags: empty / incomplete / cheat / crash / concern / forbidden"
  note "El programa no debe morir de forma inesperada (crash → nota 0)"
  note "No editar ficheros del evaluado salvo config acordada por ambos"
  ctx_blank

  echo -e "  ${BOLD}Cómo usar esta guía${RESET}"
  info "En cada bloque: analogía → criterio de la hoja → comandos copiables → s/n"
  info "Tú marcas la nota final en Intra; el resumen final es solo orientativo."
  show_cmd "./evaluation.sh"
  pause
}

# ============================================================================
# 1 · ESTRUCTURA
# ============================================================================
check_layout() {
  section "1 · Estructura del repositorio"

  ctx "El subject exige carpetas ex00…ex05 y ficheros pie.*, chart.*, mustache.*,"
  ctx "Building.*, elbow.*, Clustering.*  (el asterisco = la extensión que elijáis)."
  ctx "README.md y start.sh de la raíz son ayuda extra: NO son entregables obligatorios."
  ctx_blank

  subsection "Carpetas y entregables del subject"
  show_cmd "ls -la"
  show_cmd "ls -d ex0*"

  local pair dir stem missing=0
  for pair in "ex00:pie" "ex01:chart" "ex02:mustache" "ex03:Building" "ex04:elbow" "ex05:Clustering"; do
    dir="${pair%%:*}"
    stem="${pair##*:}"
    if [[ -d "$SCRIPT_DIR/$dir" ]]; then
      ok "Carpeta $dir/"
    else
      fail "Falta carpeta $dir/"
      missing=1
    fi
    if ls "$SCRIPT_DIR/$dir/$stem".* >/dev/null 2>&1; then
      ok "Entrega: $dir/$stem.*"
    else
      fail "Falta $dir/$stem.* (nombre exigido por el subject)"
      missing=1
    fi
  done

  subsection "Extras (opcionales, no puntúan solos)"
  if [[ -f "$SCRIPT_DIR/README.md" ]]; then
    info "README.md presente (útil, no obligatorio en la hoja)"
  else
    warn "Sin README.md en la raíz (no es motivo de suspender por sí solo)"
  fi
  if [[ -f "$SCRIPT_DIR/start.sh" ]]; then
    info "start.sh presente (asistente; no sustituye pie.*/chart.*/…)"
  fi
  if [[ -f "$SCRIPT_DIR/evaluation.sh" ]]; then
    info "evaluation.sh = esta guía (no es parte de la nota)"
  fi

  [[ "$missing" -eq 0 ]] && RESULT[layout]=yes || RESULT[layout]=no
  pause
}

# ============================================================================
# 2 · ENTORNO
# ============================================================================
check_environment() {
  section "2 · PostgreSQL y Data Warehouse (Module 1)"

  ctx "Sin la tabla customers no hay gráficos con datos reales."
  ctx "Analogía: intentar hacer una tarta sin ingredientes en la nevera."
  ctx_blank

  if ! command -v docker >/dev/null 2>&1; then
    fail "docker no está disponible en este host"
    RESULT[env]=no
    STOP_EVAL=true
    return
  fi

  subsection "Contenedor en marcha"
  show_cmd "docker ps"
  show_cmd "docker-compose ps   # si evaluáis desde la carpeta del compose (Module 0)"
  local cname
  cname="$(find_pg_container)"
  if [[ -n "$cname" ]]; then
    CONTAINER_NAME="$cname"
    ok "Contenedor detectado: $CONTAINER_NAME"
    docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null | head -8 | sed 's/^/      /'
  else
    fail "No se ve contenedor Postgres/piscine en docker ps"
    if [[ -n "$MODULE0_DIR" ]]; then
      note "Puedes levantar desde Module 0:"
      show_cmd "cd \"$MODULE0_DIR/ex00\" && docker-compose up -d"
      if ask_yes_no "¿Intentar levantar PostgreSQL ahora?" "s"; then
        (cd "$MODULE0_DIR/ex00" && docker-compose up -d) || true
        sleep 2
        cname="$(find_pg_container)"
        [[ -n "$cname" ]] && CONTAINER_NAME="$cname" && ok "Contenedor: $CONTAINER_NAME"
      fi
    else
      warn "No se localizó Module 0 automáticamente"
    fi
  fi

  if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER_NAME"; then
    fail "PostgreSQL sigue sin estar disponible"
    RESULT[env]=no
    STOP_EVAL=true
    return
  fi

  subsection "Conexión a la BD"
  info "Usuario (login del sistema o POSTGRES_USER del .env): $DB_USER"
  info "Base de datos: $DB_NAME"
  show_cmd "docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c '\\conninfo'"
  if docker_psql '\conninfo' >/dev/null 2>&1; then
    ok "Conexión a $DB_NAME operativa"
  else
    fail "No se pudo conectar a $DB_NAME (¿usuario/password distintos?)"
    RESULT[env]=no
    STOP_EVAL=true
    return
  fi

  subsection "Tabla customers (Module 1)"
  show_cmd "docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c \"SELECT to_regclass('public.customers');\""
  local reg
  reg="$(docker_psql "SELECT to_regclass('public.customers');" || true)"
  if [[ "$reg" == "customers" ]]; then
    ok "Tabla public.customers disponible"
    show_cmd "docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c 'SELECT COUNT(*) FROM customers;'"
    local cnt
    cnt="$(docker_psql 'SELECT COUNT(*) FROM customers;' || true)"
    [[ -n "$cnt" ]] && info "Filas en customers: $cnt"
    RESULT[customers]=yes
  else
    fail "Falta public.customers → hay que completar Module 1 antes"
    RESULT[customers]=no
    STOP_EVAL=true
  fi

  [[ "$STOP_EVAL" == false ]] && RESULT[env]=yes
  pause
}

# ============================================================================
# AYUDAS: revisión de código + ejecución
# ============================================================================

# Filtra líneas de comentario / docstring basura / tests de humo de dependencias
_is_noise_line() {
  local code="$1"
  # Comentario Python/SQL puro
  if [[ "$code" =~ ^[[:space:]]*# ]]; then return 0; fi
  # Docstrings sueltas o viñetas de documentación
  if [[ "$code" =~ ^[[:space:]]*\"\"\" ]]; then return 0; fi
  if [[ "$code" =~ ^[[:space:]]*\'\'\' ]]; then return 0; fi
  if [[ "$code" =~ ^[[:space:]]*\* ]]; then return 0; fi
  # Texto tipo subject en comentarios ya filtrados; también líneas solo con strings de ayuda
  if [[ "$code" =~ You\ have\ to\ connect ]]; then return 0; fi
  if [[ "$code" =~ Garantiza\ psycopg2 ]]; then return 0; fi
  if [[ "$code" =~ pip\ install ]]; then return 0; fi
  if [[ "$code" =~ psycopg2-binary ]]; then return 0; fi
  # Tests de humo (no son el gráfico real del subject)
  if [[ "$code" =~ pie\(\[1,\ *2,\ *3\] ]]; then return 0; fi
  if [[ "$code" =~ boxplot\(\[1,\ *2,\ *3 ]]; then return 0; fi
  if [[ "$code" =~ bar\(\[1,\ *2,\ *3\] ]]; then return 0; fi
  if [[ "$code" =~ KMeans\(n_clusters=2 ]]; then return 0; fi
  return 1
}

explain_match() {
  local match="$1"
  local line="${match%%:*}"
  local code="${match#*:}"
  # recortar espacios extremos para mostrar
  code="${code#"${code%%[![:space:]]*}"}"
  echo -e "      ${YELLOW}${BOLD}línea $line:${RESET} ${DIM}${code:0:100}${RESET}"
  case "$code" in
    *psycopg2.connect*)
      echo -e "      ${CYAN}↳${RESET} Conexión real a PostgreSQL (Data Warehouse)."
      ;;
    *cur.execute*|*cursor*execute*)
      echo -e "      ${CYAN}↳${RESET} Ejecuta la consulta SQL en la BD."
      ;;
    *SELECT*|*FROM\ customers*|*FROM\ public.customers*)
      echo -e "      ${CYAN}↳${RESET} Consulta SQL sobre los datos del warehouse."
      ;;
    *GROUP\ BY*|*group\ by*)
      echo -e "      ${CYAN}↳${RESET} Agrupación SQL (conteos / totales por clave)."
      ;;
    *WHERE\ event_type*purchase*|*event_type\ =\ \'purchase\'*)
      echo -e "      ${CYAN}↳${RESET} Filtro solo compras (purchase)."
      ;;
    *date_trunc*)
      echo -e "      ${CYAN}↳${RESET} Agregación temporal (día/mes)."
      ;;
    *ax.pie*|*plt.pie*)
      echo -e "      ${CYAN}↳${RESET} Dibuja el pie chart con los datos obtenidos."
      ;;
    *boxplot*|*box\ plot*)
      echo -e "      ${CYAN}↳${RESET} Diagrama de caja (mustache) con datos reales."
      ;;
    *ax.bar*|*plt.bar*)
      echo -e "      ${CYAN}↳${RESET} Gráfico de barras (frecuencia / monetary / clusters)."
      ;;
    *KMeans*)
      echo -e "      ${CYAN}↳${RESET} Clustering K-Means (no el test de import)."
      ;;
    *StandardScaler*)
      echo -e "      ${CYAN}↳${RESET} Escalado de variables antes de agrupar."
      ;;
    *inertia*)
      echo -e "      ${CYAN}↳${RESET} Inertia/WCSS para la curva elbow."
      ;;
    *savefig*)
      echo -e "      ${CYAN}↳${RESET} Guarda el PNG del gráfico."
      ;;
    *import\ psycopg2*)
      echo -e "      ${CYAN}↳${RESET} Import del driver de PostgreSQL."
      ;;
    *)
      echo -e "      ${CYAN}↳${RESET} Evidencia de código ejecutable relacionada con el criterio."
      ;;
  esac
}

# dynamic_check FILE PATTERN1 [PATTERN2 ...]
# Cada patrón se busca por separado; se muestran solo líneas de CÓDIGO (no comentarios).
# Basta con que al menos un patrón tenga un hit de código real.
dynamic_check() {
  local file="$1"
  shift
  local description="$1"
  shift
  local patterns=("$@")

  if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
    fail "Falta $file"
    return 1
  fi
  echo -e "    ${BOLD}Archivo:${RESET} $file"
  info "Qué buscamos (solo código ejecutable, no comentarios): $description"

  local any=0
  local pat matches line code show_count
  for pat in "${patterns[@]}"; do
    matches="$(grep -nE "$pat" "$SCRIPT_DIR/$file" 2>/dev/null || true)"
    [[ -z "$matches" ]] && continue
    show_count=0
    while IFS= read -r match; do
      [[ -z "$match" ]] && continue
      line="${match%%:*}"
      code="${match#*:}"
      if _is_noise_line "$code"; then
        continue
      fi
      if [[ $show_count -eq 0 && $any -eq 0 ]]; then
        info "Evidencia en el código (se omiten comentarios y tests de humo):"
      fi
      explain_match "$match"
      any=1
      show_count=$((show_count + 1))
      # Máximo 3 hits útiles por patrón para no saturar
      [[ $show_count -ge 3 ]] && break
    done <<< "$matches"
  done

  if [[ $any -eq 1 ]]; then
    ok "El código contiene lógica alineada con el criterio"
    return 0
  else
    warn "No se encontró código ejecutable con esos patrones (¿otra API equivalente?)"
    note "Abrid el fichero y comprobad a mano el espíritu del subject"
    show_cmd "less -N $SCRIPT_DIR/$file"
    return 1
  fi
}


offer_run() {
  local title="$1"
  local ans
  RUN_CHOICE="manual"
  echo
  echo -e "  ${BOLD}${title}${RESET}"
  echo -e "  ${GREEN}a${RESET}) Automático: evaluation.sh intenta lanzarlo ahora"
  echo -e "  ${CYAN}m${RESET}) Manual: se muestran los comandos; el evaluado (o tú) los ejecuta"
  echo -e "  ${YELLOW}s${RESET}) Saltar ejecución"
  while true; do
    read -r -p "  → " ans
    case "${ans:-m}" in
      a|A) RUN_CHOICE="auto"; return 0 ;;
      m|M|"") RUN_CHOICE="manual"; return 0 ;;
      s|S) RUN_CHOICE="skip"; return 0 ;;
      *) echo -e "    ${YELLOW}Elige a, m o s${RESET}" ;;
    esac
  done
}

show_manual_python() {
  local file="$1"
  local dir base
  dir="$(dirname "$file")"
  base="$(basename "$file")"
  echo
  echo -e "  ${BOLD}Modo MANUAL – Python (copia en otra terminal)${RESET}"
  echo
  note "Paso 1 – Postgres y customers:"
  show_cmd "docker ps"
  show_cmd "docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c 'SELECT COUNT(*) FROM customers;'"
  echo
  note "Paso 2 – Ejecutar el script:"
  show_cmd "cd $SCRIPT_DIR/$dir"
  show_cmd "python3 $base"
  note "Si quieres solo PNG (sin ventana gráfica):"
  show_cmd "MPLBACKEND=Agg python3 $base"
  echo
  note "Paso 3 – Ver el resultado:"
  show_cmd "ls -lh $SCRIPT_DIR/$dir/*.png 2>/dev/null"
  show_cmd "xdg-open $SCRIPT_DIR/$dir/ALGUNO.png   # o ábrelo en el visor de imágenes"
  note "La hoja pide que el gráfico «aparezca»: ventana o abrir el PNG cuenta."
}

run_python_exercise() {
  local key="$1"
  local file="$2"
  local outputs_csv="$3"
  local dir base
  dir="$(dirname "$file")"
  base="$(basename "$file")"

  offer_run "¿Cómo ejecutamos $key ($base)?"
  case "$RUN_CHOICE" in
    auto)
      show_cmd "cd $SCRIPT_DIR/$dir && MPLBACKEND=Agg python3 $base"
      if (cd "$SCRIPT_DIR/$dir" && MPLBACKEND=Agg python3 "$base"); then
        local missing=0 out
        IFS=',' read -r -a outs <<< "$outputs_csv"
        for out in "${outs[@]}"; do
          if [[ -s "$SCRIPT_DIR/$dir/$out" ]]; then
            ok "Artefacto: $dir/$out"
          else
            fail "No se generó (o está vacío): $dir/$out"
            missing=1
          fi
        done
        [[ "$missing" -eq 0 ]] && RESULT["$key"]=yes || RESULT["$key"]=no
      else
        fail "$base terminó con error (crash → flag en Intra)"
        RESULT["$key"]=no
      fi
      ;;
    manual)
      show_manual_python "$file"
      IFS=',' read -r -a outs <<< "$outputs_csv"
      for out in "${outs[@]}"; do
        show_cmd "ls -lh $SCRIPT_DIR/$dir/$out"
      done
      echo
      read -r -p "$(echo -e "${CYAN}Cuando hayáis ejecutado y visto los gráficos, Enter…${RESET}")"
      if ask_yes_no "¿La ejecución manual de $key fue correcta?" "n"; then
        RESULT["$key"]=yes
        ok "$key marcado como ejecutado OK"
      else
        RESULT["$key"]=no
        fail "$key no se validó en ejecución"
      fi
      ;;
    skip)
      warn "Ejecución de $key omitida"
      RESULT["$key"]=skip
      ;;
  esac
}

confirm_visual() {
  local key="$1"
  local outputs_csv="$2"
  local question="$3"
  local dir out
  echo
  subsection "Demostración visual (obligatoria en la hoja)"
  ctx "Un PNG en el disco no basta: hay que ABRIRLO o mostrar la ventana y comentar."
  IFS=',' read -r -a outs <<< "$outputs_csv"
  for out in "${outs[@]}"; do
    if [[ -f "$SCRIPT_DIR/$out" ]]; then
      ok "Existe: $out"
      show_cmd "xdg-open \"$SCRIPT_DIR/$out\""
    else
      warn "Aún no existe: $out (ejecutad el script antes)"
    fi
  done
  ask_scale "$key" "$question"
}

# ============================================================================
# EX00 – Pie
# ============================================================================
check_ex00() {
  section "3 · EX00 – American apple Pie"

  ctx "Analogía: una tarta repartida en porciones = qué hacen los usuarios en la web"
  ctx "(mirar productos, meter en carrito, quitar, comprar…)."
  ctx_blank
  requirement "Leer el código, comprobar conexión al Data Warehouse (si usáis Docker: puertos)."
  requirement "Ejecutar el programa → debe aparecer un pie chart."
  ctx_blank

  subsection "Código"
  dynamic_check "ex00/pie.py" \
    "Conexión warehouse + SQL GROUP BY event_type + pie + savefig" \
    "psycopg2\.connect" \
    "cur\.execute" \
    "SELECT[[:space:]]+event_type" \
    "GROUP BY event_type" \
    "ax\.pie\(" \
    "savefig\("

  subsection "Docker (solo si aplica)"
  show_cmd "docker ps"
  show_cmd "docker-compose ps"
  note "La hoja: si usáis Docker, la conexión debe usar los puertos publicados (p. ej. 5432)."

  subsection "Ejecución"
  run_python_exercise "EX00" "ex00/pie.py" "pie_chart.png"

  confirm_visual "EX00_visual" "ex00/pie_chart.png" \
    "EX00 – ¿Se ha mostrado un pie chart funcional conectado a customers?"
  pause
}

# ============================================================================
# EX01 – Charts
# ============================================================================
check_ex01() {
  section "4 · EX01 – Initial data exploration"

  ctx "Analogía: solo miramos tickets de compra (purchase), no ventanas ni carritos."
  ctx "Tres fotos del negocio de oct 2022 a feb 2023: clientes/día, ventas/mes, gasto medio."
  ctx_blank
  requirement "Solo datos purchase de event_type."
  requirement "Ejecutar → 3 gráficos como en el subject (con febrero si el warehouse lo tiene)."
  ctx_blank

  subsection "Código"
  dynamic_check "ex01/chart.py" \
    "Filtro purchase + agregaciones + 3 savefig" \
    "event_type[[:space:]]*=[[:space:]]*'purchase'" \
    "psycopg2\.connect" \
    "cur\.execute" \
    "date_trunc|event_time::date" \
    "savefig\("

  subsection "Ejecución"
  run_python_exercise "EX01" "ex01/chart.py" \
    "chart_customers_daily.png,chart_sales_monthly.png,chart_avg_spend_daily.png"

  confirm_visual "EX01_visual" \
    "ex01/chart_customers_daily.png,ex01/chart_sales_monthly.png,ex01/chart_avg_spend_daily.png" \
    "EX01 – ¿Se han mostrado los 3 gráficos (solo purchase, periodo hasta febrero)?"
  pause
}

# ============================================================================
# EX02 – Mustache (2 partes en la hoja)
# ============================================================================
check_ex02() {
  section "5 · EX02 – My beautiful mustache"

  ctx "Analogía: el «bigote» del box plot son los bigotes (whiskers): de dónde a dónde"
  ctx "se estira el precio típico; los puntos sueltos son rarezas (outliers)."
  ctx_blank
  requirement "Part 1: solo purchase; imprimir mean, median, min, max, Q1, Q2, Q3; box de precios."
  requirement "Part 2: box de la cesta media por usuario + el estudiante EXPLICA los box plots."
  ctx_blank

  subsection "Código"
  dynamic_check "ex02/mustache.py" \
    "purchase + stats + boxplot real + savefig" \
    "event_type[[:space:]]*=[[:space:]]*'purchase'" \
    "psycopg2\.connect" \
    "cur\.execute" \
    "np\.percentile|quantile|median|\.mean\(" \
    "ax\.boxplot\(|boxplot\(" \
    "savefig\("

  subsection "Ejecución"
  run_python_exercise "EX02" "ex02/mustache.py" \
    "mustache_item_price.png,mustache_basket.png"

  echo
  subsection "Valoración hoja – Part 1"
  ask_scale "EX02_p1" \
    "EX02 Part 1 – ¿Stats (mean/median/min/max/cuartiles) + box plot de precios de ítems OK?"

  echo
  subsection "Valoración hoja – Part 2"
  ctx "El evaluado debe explicar: mediana, cuartiles, bigotes, outliers."
  ask_scale "EX02_p2" \
    "EX02 Part 2 – ¿Box de cesta media por usuario + explicación de los box plots OK?"
  pause
}

# ============================================================================
# EX03 – Building
# ============================================================================
check_ex03() {
  section "6 · EX03 – Highest Building"

  ctx "Analogía: edificios en el horizonte: muchos clientes con pocas compras (edificio bajo"
  ctx "y ancho a la izquierda) y pocos que compran o gastan muchísimo (a la derecha)."
  ctx_blank
  requirement "Dos bar charts con la misma información que el subject (frecuencia y monetary)."
  ctx_blank

  subsection "Código"
  dynamic_check "ex03/Building.py" \
    "purchase + barras frecuencia/monetary + savefig" \
    "event_type[[:space:]]*=[[:space:]]*'purchase'" \
    "psycopg2\.connect|cur\.execute" \
    "COUNT\(\*\)|SUM\(price\)" \
    "ax\.bar\(" \
    "savefig\("

  subsection "Ejecución"
  run_python_exercise "EX03" "ex03/Building.py" \
    "building_frequency.png,building_monetary.png"

  confirm_visual "EX03_visual" \
    "ex03/building_frequency.png,ex03/building_monetary.png" \
    "EX03 – ¿Dos bar charts generados con la información del subject?"
  pause
}

# ============================================================================
# EX04 – Elbow
# ============================================================================
check_ex04() {
  section "7 · EX04 – Elbow"

  ctx "Analogía: doblas el brazo y buscas el codo: a partir de ahí, añadir más pliegues"
  ctx "(más clusters) apenas reduce el «dolor» (inertia). Ese codo sugiere cuántos grupos."
  ctx_blank
  requirement "Mostrar la curva elbow."
  requirement "El estudiante explica cuántos clusters quiere conservar y POR QUÉ."
  ctx_blank

  subsection "Código"
  dynamic_check "ex04/elbow.py" \
    "RFM + StandardScaler + KMeans + inertia + savefig" \
    "psycopg2\.connect|cur\.execute" \
    "StandardScaler" \
    "KMeans\(" \
    "inertia_" \
    "SELECTED_K" \
    "savefig\("

  subsection "Ejecución"
  run_python_exercise "EX04" "ex04/elbow.py" "elbow_method.png"

  local k
  k="$(sed -nE 's/^[[:space:]]*SELECTED_K[[:space:]]*=[[:space:]]*([0-9]+).*/\1/p' \
    "$SCRIPT_DIR/ex04/elbow.py" 2>/dev/null | head -1)"
  if [[ -n "$k" ]]; then
    EX04_K="$k"
    info "En este código SELECTED_K=$k (elección del proyecto; hay que defenderla)"
    show_cmd "grep -n SELECTED_K ex04/elbow.py"
  else
    warn "No se leyó SELECTED_K automáticamente – preguntad en la defensa"
  fi

  confirm_visual "EX04_visual" "ex04/elbow_method.png" \
    "EX04 – ¿Curva elbow mostrada y justificado el número de clusters?"
  pause
}

# ============================================================================
# EX05 – Clustering
# ============================================================================
check_ex05() {
  section "8 · EX05 – Clustering"

  ctx "Analogía: el jefe quiere enviar emails distintos: bienvenida a nuevos, cupón a inactivos,"
  ctx "estatus gold/silver/platinum a los fieles. El algoritmo agrupa; vosotros etiquetáis."
  ctx_blank
  requirement "Explicar el algoritmo de clustering usado."
  requirement "Mismo número de clusters que en EX04."
  requirement "Al menos 2 gráficos."
  requirement "Explicar qué tipo de cliente hay en cada grupo (≥ 4 grupos de negocio en el subject)."
  ctx_blank

  subsection "Código"
  dynamic_check "ex05/Clustering.py" \
    "RFM + StandardScaler + KMeans\(k\) + ≥2 savefig" \
    "psycopg2\.connect|cur\.execute" \
    "StandardScaler" \
    "KMeans\(" \
    "N_CLUSTERS" \
    "savefig\("

  subsection "Ejecución"
  run_python_exercise "EX05" "ex05/Clustering.py" \
    "customers_per_cluster.png,clusters_frequency_monetary.png"

  subsection "Coherencia EX04 → EX05"
  local k5
  k5="$(sed -nE 's/^[[:space:]]*N_CLUSTERS[[:space:]]*=[[:space:]]*([0-9]+).*/\1/p' \
    "$SCRIPT_DIR/ex05/Clustering.py" 2>/dev/null | head -1)"
  show_cmd "grep -nE 'SELECTED_K|N_CLUSTERS' ex04/elbow.py ex05/Clustering.py"
  if [[ -n "$EX04_K" && -n "$k5" ]]; then
    if [[ "$EX04_K" == "$k5" && "$k5" -ge 4 ]]; then
      ok "Mismo k=$k5 en EX04 y EX05 (≥ 4 como pide el subject para grupos de negocio)"
      RESULT[cluster_consistency]=yes
    else
      fail "Incoherencia o k<4: EX04 k=${EX04_K:-?} · EX05 k=${k5:-?}"
      RESULT[cluster_consistency]=no
    fi
  else
    warn "No se pudo comparar k automáticamente – verificad a mano en defensa"
    RESULT[cluster_consistency]=skip
  fi
  ctx "k=4 es el mínimo de grupos de negocio del subject; el codo puede justificar 5 u otro."

  confirm_visual "EX05_visual" \
    "ex05/customers_per_cluster.png,ex05/clusters_frequency_monetary.png" \
    "EX05 – ¿Algoritmo explicado, mismo k, ≥2 gráficos y significado de cada grupo?"
  pause
}

# ============================================================================
# RESUMEN
# ============================================================================
summary() {
  section "9 · Resumen para Intra (orientativo)"

  ctx "Copia ideas al comentario (máx. 2048 caracteres). La nota oficial la marcas tú."
  ctx_blank

  printf "  %-28s %s\n" "Estructura subject" "${RESULT[layout]:-—}"
  printf "  %-28s %s\n" "PostgreSQL / customers" "${RESULT[env]:-—} / ${RESULT[customers]:-—}"
  printf "  %-28s %s\n" "EX00 ejecución" "${RESULT[EX00]:-—}"
  printf "  %-28s %s\n" "EX00 visual (hoja)" "${RESULT[EX00_visual]:-—}"
  printf "  %-28s %s\n" "EX01 ejecución" "${RESULT[EX01]:-—}"
  printf "  %-28s %s\n" "EX01 visual (hoja)" "${RESULT[EX01_visual]:-—}"
  printf "  %-28s %s\n" "EX02 Part 1 (hoja)" "${RESULT[EX02_p1]:-—}"
  printf "  %-28s %s\n" "EX02 Part 2 (hoja)" "${RESULT[EX02_p2]:-—}"
  printf "  %-28s %s\n" "EX03 ejecución" "${RESULT[EX03]:-—}"
  printf "  %-28s %s\n" "EX03 visual (hoja)" "${RESULT[EX03_visual]:-—}"
  printf "  %-28s %s\n" "EX04 ejecución" "${RESULT[EX04]:-—}"
  printf "  %-28s %s\n" "EX04 visual (hoja)" "${RESULT[EX04_visual]:-—}"
  printf "  %-28s %s\n" "EX05 ejecución" "${RESULT[EX05]:-—}"
  printf "  %-28s %s\n" "EX05 visual (hoja)" "${RESULT[EX05_visual]:-—}"
  printf "  %-28s %s\n" "Coherencia k EX04↔EX05" "${RESULT[cluster_consistency]:-—}"
  echo
  echo -e "  ${GREEN}OK=$PASS_COUNT${RESET}  ${RED}Errores=$FAIL_COUNT${RESET}  ${YELLOW}Avisos=$WARN_COUNT${RESET}"
  echo
  echo -e "  ${BOLD}Ratings (hoja de evaluación):${RESET}"
  note "Ok · Outstanding · Empty · Incomplete · Cheat · Crash · Concern · Forbidden"
  echo
  echo -e "  ${DIM}Este resumen NO sustituye tu juicio ni el resultado en Intra.${RESET}"
  echo -e "  ${DIM}evaluation.sh no forma parte de la nota del estudiante.${RESET}"
}

# ============================================================================
# MAIN
# ============================================================================
main() {
  header
  preamble
  check_layout
  check_environment
  if [[ "$STOP_EVAL" == true ]]; then
    warn "Entorno incompleto: la defensa de gráficos no puede cerrarse sin customers."
    summary
    exit 0
  fi
  check_ex00
  check_ex01
  check_ex02
  check_ex03
  check_ex04
  check_ex05
  summary
}

main "$@"
