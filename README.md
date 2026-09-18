# Case — Lista Nominal de Hipertensão

Pipeline de dados em SQLite para construção de uma lista nominal de acompanhamento de pessoas com hipertensão, com foco em regras de negócio, qualidade de dados, rastreabilidade e validação.

> **Dados nominais:** este repositório contém apenas código e documentação. Dados reais de saúde não são disponibilizados.

## Visão geral

O projeto implementa um pipeline de dados em quatro camadas:

**RAW → STAGING → INTERMEDIATE → MART**

A solução parte de conjuntos de dados brutos, mantém a camada RAW sem transformação, realiza tipagem e deduplicação em STAGING, aplica regras de elegibilidade e janelas temporais em INTERMEDIATE e entrega uma tabela final orientada ao uso operacional em MART.

## O que foi desenvolvido

- Modelagem de dados em camadas usando SQL
- Deduplicação pela transmissão mais recente
- Tipagem e tratamento de dados originalmente textuais
- Parsing de campos JSON
- Quarentena de registros com datas futuras
- Aplicação de regras de elegibilidade para hipertensão
- Filtros por CBO e regras temporais para práticas de cuidado
- Construção da tabela final `mart_lista_nominal_hipertensao`
- Validações associadas aos critérios de aceite
- Contadores finais para acompanhamento dos resultados
- Documentação técnica, de produto e das decisões de implementação

## Arquitetura

```text
Dados brutos
    ↓
RAW
    ↓
STAGING
    ↓
INTERMEDIATE
    ↓
MART
    ↓
Lista nominal de hipertensão
Tecnologias

SQL · SQLite · PowerShell · Bash · Modelagem de dados · ETL/ELT · Data Quality · Regras de negócio · Validação · Documentação técnica
