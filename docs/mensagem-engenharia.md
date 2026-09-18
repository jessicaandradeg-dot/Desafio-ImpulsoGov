# Mensagem para o time de engenharia de dados

**Para:** @data-engineering  
**Assunto:** Problemas nos dados brutos — Lista Nominal de Hipertensão  
**Data:** 2026-08-29

---

Olá,

Identificamos três problemas nos dados brutos que impactam a qualidade da Lista Nominal de Hipertensão. Estou priorizando-os por severidade operacional — quanto acima, mais urgente.

## 🔴 **Prioridade 1: `dt_registro` diverge entre retransmissões da mesma PK**

**Problema:** A mesma consulta/procedimento (mesma PK) é retransmitida mensalmente, mas o `dt_registro` **muda** entre versões. Spread mediano de **150 dias**.

**Exemplos concretos:**
- `co_seq_fat_atd_ind = 4100855.HIPERTENSÃO`: transmissão 2026-05-01 → `dt = 2026-02-10` | transmissão 2026-06-01 → `dt = 2025-08-04` (190 dias de diferença)
- `co_seq_fat_proced = proc_8200511`: transmissão 2026-05-01 → `dt = 2026-02-26` | transmissão 2026-08-01 → `dt = 2025-10-29` (120 dias)

**Por que importa:** A mesma pessoa sai de "em dia" ou entra em "atrasada" dependendo de qual versão você usa. A janela de 6 meses é crítica; 8 registros cruzam essa janela entre versões.

**Ação sugerida:** Investigar por que a data do evento muda. É correção retroativa? Re-processamento de fila? Adicionar um campo `dt_evento_corrigido_em` para rastreabilidade.

---

## 🟠 **Prioridade 2: `qt_afericao_pressao_arterial` 100% vazia; valor está em JSON**

**Problema:** A coluna `qt_afericao_pressao_arterial` está **completamente vazia** (0/4252 valores). O valor real está no JSON em `propriedades`: `{"pressao_arterial": "140/72"}`.

**Por que importa:** O dicionário de dados documenta `qt_afericao_pressao_arterial` como fonte; produzimos a tela com dados do JSON. Contrato quebrado — qualquer consumidor que segue o dicionário erra.

**Ação sugerida:** 
- Opção A: Popular `qt_afericao_pressao_arterial` com o valor do JSON antes da transmissão
- Opção B: Atualizar o dicionário para indicar que a fonte é `propriedades`, não `qt_*`

---

## 🟡 **Prioridade 3: `no_equipe` instável + colisão de nomes**

**Problema:** O nome da equipe varia entre cargas (mesmo INE, nomes diferentes):
- `nu_ine = 0001234567`: `no_equipe` = `ESF 1` | `esf 1` | `E.S.F. 1` | `ESF  1 ` (espaços, caso)
- `no_equipe = 'ESF 5'` é nome de **dois INEs diferentes** (`0001234571` e `0001234572`)

**Por que importa:** Filtro de equipe na tela agrupa por nome — duas equipes físicamente distintas viram uma.

**Ação sugerida:** Normalizar `no_equipe` no e-SUS PEC (trim, upper, padronizar acrônimos). A chave estável é `nu_ine`, não o texto.

---

## Sem urgência, mas anotado

- **Falecidos com registros recentes:** 14 falecidos têm 17+ registros após 2026-02-01. Tipicamente entrada de dados errada, mas verificar sistema.
- **53 pessoas com "HIPERTENSÃO - CONDIÇÃO RESOLVIDA":** É esperado, mas 13 voltaram a ter HAS ativa depois — lógica de resolução merecia revisão.

---

Qualquer dúvida, chamar. O pipeline completo está pronto pra testar assim que conseguir os dados ajustados.

Abraço,  
Analytics
