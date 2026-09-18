# Nota sobre uso de IA

## Ferramentas usadas

- **Claude (modelo Opus)** — análise de especificação, design de arquitetura, geração de SQL (SQLite), PowerShell scripting
- **PowerShell 5.1 nativo** — perfilamento independente dos dados (4 scripts, ~4k linhas)

## O que aceitei

- **Estrutura do SQL:** dedup via `ROW_NUMBER() OVER`, CTEs encadeadas, window functions. Funcionam como esperado.
- **Lógica de elegibilidade:** as condições de FR-001..003 ficaram legíveis. Claude entendeu bem a reativação (HAS após resolução).
- **Documentação:** os ADRs e decisões são bem estruturados — Claude generalizou bem o padrão.

## O que rejeitei ou corrigi

1. **Caracteres especiais em PowerShell:** Claude gerou scripts com ` ═`, `✓`, `►` que corrompem em Windows 5.1. Removi tudo, deixei ASCII puro.

2. **Redirecionamento de stdin em PowerShell:** Claude sugeriu `& $exe < file` — erro no PS 5.1 (operador reservado). Corrigi para `Get-Content | &`.

3. **Índices em SQL:** Claude gerou `CREATE INDEX` sem avisar que SQLite 3.37+ exige `WITHOUT ROWID` em algumas situações. Aceitei parcialmente, testando depois.

4. **BOM em UTF-8:** Claude usou `Set-Content -Encoding UTF8`, que adiciona BOM automaticamente em PowerShell — causa parse error no SQLite via pipe. Descobri que precisava `[System.Text.UTF8Encoding]($false)`.

## Exemplo concreto: o bug de encoding

Escrevi um profiler em PowerShell para validar os números (325 pessoas, distribuição de status por prática). Claude sugeriu:

```powershell
[double]::TryParse($pRaw, [ref]$pv)
```

**Problema:** PowerShell 5.1 usa cultura do sistema (pt-BR), então `"77.8"` → `778` (o ponto é separador de milhar). Resultado: todos os 1.545 registros de peso saíram como "implausível" (fora de faixa 2-300kg). 100% de falha é um sinal que o validador está errado, não o dado.

**Solução:** Passei `[System.Globalization.CultureInfo]::InvariantCulture` explicitamente:

```powershell
[double]::TryParse($pRaw, [System.Globalization.NumberStyles]::Float, $INV, [ref]$pv)
```

Resultado: 230 registros com IMC implausível (esperado), não 1.545.

---

## Conclusão

A IA foi mais útil **em amplitude** (arquitetura, spec, SQL) que em **profundidade** (ambiente Windows, encoding, sintaxe do PS 5.1). O que salvou foi **validação independente em PowerShell** — duas implementações divergentes de um métrica é o melhor teste de verdade que existe. Sem ele, teria entregado números errados com confiança.

Trabalhar bem com IA é saber onde ela erra antes de confiar — aqui foi ambiente específico (Windows + UTF-8 + PowerShell antigo).
