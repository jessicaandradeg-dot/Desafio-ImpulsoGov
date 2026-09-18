@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "SQLITE=C:\Users\jeess\AppData\Local\Microsoft\WinGet\Packages\SQLite.SQLite_Microsoft.Winget.Source_8wekyb3d8bbwe\sqlite3.exe"
set "DB=lista_nominal.db"
set "CSV=..\..\dados"

echo.
echo PIPELINE SQL - Lista Nominal de Hipertensao
echo.

if exist %DB% (
  echo [OK] Removendo banco anterior
  del %DB%
)

echo [1] Fase 0 - Parametros
%SQLITE% %DB% ".read 00_param.sql"

echo [2] Fase 1 - Raw DDL
%SQLITE% %DB% ".read 10_raw.sql"

echo [3] Fase 1b - Imports CSV
%SQLITE% %DB% ".mode csv" ".import --skip 1 %CSV%\cidadao_pec.csv raw_cidadao_pec"
%SQLITE% %DB% ".mode csv" ".import --skip 1 %CSV%\atendimento_individual.csv raw_atendimento_individual"
%SQLITE% %DB% ".mode csv" ".import --skip 1 %CSV%\procedimentos.csv raw_procedimentos"

echo [4] Fase 2 - Staging
%SQLITE% %DB% ".read 20_staging.sql"

echo [5] Fase 3 - Intermediate
%SQLITE% %DB% ".read 30_intermediate.sql"

echo [6] Fase 4 - Mart
%SQLITE% %DB% ".read 40_mart.sql"

echo [7] Fase 6 - Numeros
echo.
%SQLITE% %DB% ".read 60_numeros.sql"

echo.
echo [OK] PIPELINE COMPLETO
echo Banco: %DB%
echo.
