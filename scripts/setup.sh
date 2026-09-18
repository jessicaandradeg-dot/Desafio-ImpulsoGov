#!/bin/bash
# ============================================================================
# Script para rodar o pipeline SQLite em bash/git-bash/wsl
# ============================================================================

SQLITE3="sqlite3"
DB="lista_nominal.db"
CSV_DIR="../../dados"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$SCRIPT_DIR"

echo ""
echo "CONSTRUINDO LISTA NOMINAL DE HIPERTENSAO"
echo "Db: $DB"
echo ""

# Remover DB anterior
if [ -f "$DB" ]; then
  rm -f "$DB"
  echo "[OK] Banco anterior limpo"
fi

# Função para rodar script
run_sql() {
  local script="$1"
  local label="$2"
  echo ""
  echo ">> $label"
  if [ ! -f "$script" ]; then
    echo "ERRO: $script nao encontrado"
    exit 1
  fi
  "$SQLITE3" -batch "$DB" < "$script" 2>&1 | sed 's/^/   /'
  if [ $? -ne 0 ]; then
    echo "ERRO ao executar $script"
    exit 1
  fi
  echo "[OK]"
}

# Função para importar CSV
import_csv() {
  local table="$1"
  local csv="$2"
  echo ""
  echo ">> Importando $csv >> $table"
  local csv_path="$CSV_DIR/$csv"
  if [ ! -f "$csv_path" ]; then
    echo "ERRO: $csv_path nao encontrado"
    exit 1
  fi
  # Usar printf para evitar BOM
  printf ".mode csv\n.import --skip 1 %s %s\n" "$csv_path" "$table" | "$SQLITE3" -batch "$DB" 2>&1 | sed 's/^/   /'
  local count=$("$SQLITE3" "$DB" "SELECT COUNT(*) FROM $table;" 2>&1)
  echo "[OK] $count linhas"
}

# FASE 0
run_sql "00_param.sql" "Fase 0: Parametros globais"

# FASE 1
run_sql "10_raw.sql" "Fase 1: Criando tabelas raw"
import_csv "raw_cidadao_pec" "cidadao_pec.csv"
import_csv "raw_atendimento_individual" "atendimento_individual.csv"
import_csv "raw_procedimentos" "procedimentos.csv"

# FASE 2
run_sql "20_staging.sql" "Fase 2: Staging"

# FASE 3
run_sql "30_intermediate.sql" "Fase 3: Intermediate"

# FASE 4
run_sql "40_mart.sql" "Fase 4: Mart"

# FASE 6
echo ""
echo "NUMEROS FINAIS"
run_sql "60_numeros.sql" "Fase 6: Numeros finais"

echo ""
echo "PIPELINE COMPLETO"
echo "Banco: $DB"
echo ""
