param(
  [string]$WorkDir = (Split-Path -Parent $MyInvocation.MyCommand.Path),
  [string]$CsvDir = $null,
  [switch]$SkipValidation
)

$sqlite3 = "C:\Users\jeess\AppData\Local\Microsoft\WinGet\Packages\SQLite.SQLite_Microsoft.Winget.Source_8wekyb3d8bbwe\sqlite3.exe"
$db = "$WorkDir\lista_nominal.db"

# Se csv_dir nao foi passado, procura no caminho conhecido (sem acentuado)
if ([string]::IsNullOrWhiteSpace($CsvDir)) {
  $base = $WorkDir.Replace("\entregaveis\2-sql", "")
  $CsvDir = "$base\dados"
}

if (-not (Test-Path $sqlite3)) {
  Write-Host "ERRO: sqlite3.exe nao encontrado" -ForegroundColor Red
  exit 1
}

if (-not (Test-Path $CsvDir)) {
  Write-Host "ERRO: Diretorio de dados nao encontrado: $CsvDir" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "CONSTRUINDO LISTA NOMINAL DE HIPERTENSAO" -ForegroundColor Cyan
Write-Host "Db: $db" -ForegroundColor Gray
Write-Host "Csv: $CsvDir" -ForegroundColor Gray
Write-Host ""

if (Test-Path $db) {
  Remove-Item $db -Force
  Write-Host "[OK] Banco anterior limpo" -ForegroundColor Green
}

function Run-Sql {
  param([string]$Script, [string]$Label)
  Write-Host ""
  Write-Host ">> $Label" -ForegroundColor Yellow
  $sql_file = "$WorkDir\$Script"
  if (-not (Test-Path $sql_file)) {
    Write-Host "ERRO: $sql_file nao encontrado" -ForegroundColor Red
    exit 1
  }
  $sql_content = Get-Content $sql_file -Raw -Encoding UTF8
  $sql_content | & $sqlite3 -batch $db 2>&1 | Where-Object { $_ -notmatch '^\s*$' } | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
  Write-Host "[OK]" -ForegroundColor Green
}

function Import-Csv-To-Db {
  param([string]$Table, [string]$Csv)
  Write-Host ""
  Write-Host ">> Importando $Csv >> $Table" -ForegroundColor Yellow
  $csv_path = "$CsvDir\$Csv"
  if (-not (Test-Path $csv_path)) {
    Write-Host "ERRO: $csv_path nao encontrado" -ForegroundColor Red
    exit 1
  }
  $cmd = ".mode csv`n.import --skip 1 `"$csv_path`" $Table`n"
  $cmd | & $sqlite3 -batch $db 2>&1 | Where-Object { $_ -notmatch '^\s*$' } | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
  $count = & $sqlite3 $db "SELECT COUNT(*) FROM $Table;" 2>&1
  Write-Host "[OK] $count linhas" -ForegroundColor Green
}

# FASE 0: PARAMETROS
Run-Sql "00_param.sql" "Fase 0: Parametros globais"

# FASE 1: RAW
Run-Sql "10_raw.sql" "Fase 1: Criando tabelas raw"
Import-Csv-To-Db "raw_cidadao_pec" "cidadao_pec.csv"
Import-Csv-To-Db "raw_atendimento_individual" "atendimento_individual.csv"
Import-Csv-To-Db "raw_procedimentos" "procedimentos.csv"

# FASE 2: STAGING
Run-Sql "20_staging.sql" "Fase 2: Staging (dedup, tipagem, quarentena)"

# FASE 3: INTERMEDIATE
Run-Sql "30_intermediate.sql" "Fase 3: Intermediate (elegibilidade, janelas)"

# FASE 4: MART
Run-Sql "40_mart.sql" "Fase 4: Mart (tabela final STRICT)"

# FASE 6: NUMEROS
Write-Host ""
Write-Host "NUMEROS FINAIS" -ForegroundColor Cyan
Run-Sql "60_numeros.sql" "Fase 6: Numeros finais"

Write-Host ""
Write-Host "PIPELINE COMPLETO" -ForegroundColor Green
Write-Host "Banco: $db" -ForegroundColor Gray
Write-Host ""
