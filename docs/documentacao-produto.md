# Documentação para o time de produto — Lista Nominal de Hipertensão

**Data de referência:** 2026-08-01  
**Coorte:** 325 pessoas

---

## 1. As regras adotadas (linguagem de negócio)

A lista mostra pessoas com hipertensão diagnosticada que precisam de acompanhamento. Cada pessoa tem três boas práticas registradas:

### Quem entra na lista
- Ter pelo menos uma consulta com médico ou enfermeiro que registrou "hipertensão" como condição
- Não estar falecido (11 pessoas excluídas)
- Não ter a condição registrada como "resolvida" (com exceção abaixo)

### Quem sai da lista
- Falecidos
- Quem teve a condição registrada como "resolvida" — **exceto** pessoas que voltaram a ter hipertensão ativa depois disso (13 pessoas reativadas)

### As três boas práticas
Cada pessoa mostra situação em:

| Prática | Regra | Profissionais que contam |
|---|---|---|
| **Consulta** | Pelo menos um atendimento nos últimos 6 meses | Médicos e enfermeiros |
| **Aferição de PA** | Pelo menos um registro nos últimos 6 meses | Médicos, enfermeiros e técnicos de enfermagem |
| **Peso + Altura** | Pelo menos um registro nos últimos 12 meses | Médicos, enfermeiros, técnicos e agentes comunitários |

### Os três status

Para cada prática:
- **Em dia** → registro mais recente está dentro da janela
- **Atrasada** → existe registro, mas o mais recente está fora da janela
- **Nunca realizada** → nenhum registro no histórico

---

## 2. Decisões ambíguas e impacto

Sete pontos em que havia mais de um caminho defensável. Aqui está o que foi escolhido, o que foi descartado, e **por quê**.

### Decisão 1: Técnico de enfermagem não conta para "Consulta"

**Escolhido:** Apenas médicos e enfermeiros contam para a boa prática "Consulta"

**Descartado:** Aceitar também técnicos de enfermagem (atendimento registrado por técnico = "em dia")

**Por quê:** O dicionário de dados diz que a tabela de atendimentos contém *"apenas atendimentos realizados por médicos e enfermeiros"*. Na verdade, 54 registros têm CBO de técnico, todos em 2026. Sem o filtro, **44 pessoas sairiam indevidamente da lista de ação** — foram consideradas "em dia" porque tiveram atendimento de técnico, que não é profissional habilitado para "Consulta". Erro com custo operacional alto.

**Impacto:** 44 pessoas → lista pode ficar 14% menor e perder quem realmente precisa de consulta com médico/enfermeiro.

---

### Decisão 2: Pessoas com condição "resolvida" entram novamente se voltam a ter hipertensão

**Escolhido:** Excluir quem tem "condição resolvida", **exceto** se tiveram hipertensão ativa registrada **depois** da resolução

**Descartado:** Excluir completamente (interpretação literal da regra)

**Por quê:** Uma pessoa pode ser marcada como "curada" em 2020 e voltar a ter hipertensão em 2026. A ordem temporal importa: se a pessoa está com hipertensão ativa agora, deve estar na lista, independentemente do histórico.

**Impacto:** 13 pessoas reativadas. Exemplo: cidadão resolvido em 2020-03-15, com HAS ativa em 2026-07-29. Sem reativação, sairia da lista apesar de hipertenso ativo.

---

### Decisão 3: Datas no futuro não contam

**Escolhido:** Atendimentos/procedimentos com data `> 2026-08-01` não entram no cálculo de janelas

**Descartado:** Manter (viraria "em dia" falso)

**Por quê:** 46 registros têm data futura, e todos têm `data_transmissão` anterior (erro evidente, não "consulta marcada pro futuro"). Manter viraria "em dia" falso em ~11 pessoas por prática.

**Impacto:** 3–4% a menos por prática, mas elimina erros óbvios.

---

### Decisão 4: Microárea sempre nula (sem fonte)

**Escolhido:** Coluna `nu_microarea` no resultado é **sempre nula**, documentado

**Descartado:** Derivar de equipe ou criar synthetic

**Por quê:** O protótipo pede "Microárea 02" como coluna e filtro. Nenhuma das 51 colunas nas três tabelas tem microárea. É lacuna de fonte genuína. Deixar NULL comunica transparência.

**Impacto:** Filtro de microárea indisponível na tela até ter fonte de dado. Recomendação: capturar microárea no e-SUS PEC.

---

### Decisão 5: Peso/altura conta por existência, não por plausibilidade

**Escolhido:** Registros com peso/altura contam para status mesmo que IMC seja implausível

**Descartado:** Invalidar por faixa (ex.: IMC < 12 ou > 60)

**Por quê:** A regra pede "registro", não "registro válido". Interpretar validade é reescrever. Mas: 230 de 1.545 registros têm IMC fora de faixa; altura varia >20cm pra mesmo cidadão em alguns casos.

**Impacto:** Nenhum no status de "peso e altura" hoje (a regra é "registrado", não "confiável"). Recomendação: auditar altura (pode indicar erro de entrada).

---

## 3. Limitações

- **9 pessoas sem nome** — limite de identificação na equipe
- **2 pessoas com idade negativa** (nascimento registrado no futuro) — impossível na tela, dados inválidos
- **Altura não é confiável** — 422 registros < 140cm; 95 cidadãos com variação > 20cm. Não use para IMC sem validação
- **Nenhuma informação de microárea** — filtro "Microárea" indisponível
- **Equipe: nomes variam** (espaços, caso, acrônimos) — solução: filtrar por código (nu_ine), exibir nome normalizado

---

## 4. Recomendações

### Para o produto
1. **Adicionar filtro de equipe por código (nu_ine), não por nome** — nomes variam entre cargas; mesmo nome (`ESF 5`) está em dois INEs distintos
2. **Adicionar campo de "Data prevista da próxima consulta"** — ajuda a priorizar ação
3. **Capturar microárea no e-SUS PEC** — hoje está faltando; bloqueia um filtro aprovado do protótipo

### Para os dados
1. **Validar altura** — 422 registros < 140cm; 95 cidadãos com variação > 20cm em mesma pessoa → suspeita de erro de entrada
2. **Auditar datas futuras** — 46 registros com `dt_registro > data_transmissao` indicam regressão ou re-processamento
3. **Validar CBO em atendimento_individual** — tabela documentada como "só médico/enfermeiro" contém 54 registros de técnico

### Para próximas iterações
- **Lista de Diabetes** — base já tem classificações e flag. Usar mesmo pipeline
- **Padrão de "boas práticas" por condição** — permite reutilizar arquitetura para outras crônicas (asma, DPOC, etc.)

---

## Números finais

| | Em dia | Atrasada | Nunca realizada | Total |
|---|---|---|---|---|
| **Consulta** (6m) | 171 | 141 | 0 | **312** |
| **Aferição PA** (6m) | 155 | 114 | 43 | **312** |
| **Peso + Altura** (12m) | 123 | 115 | 74 | **312** |

**Filtro "Pelo menos uma a fazer":** 278 pessoas com ≥1 prática pendente · 34 com tudo em dia

---

**Notas:**
- "Nunca realizada = 0" em Consulta é consequência lógica: todo mundo entrou por ter tido atendimento
- Números refletem deduplicação (mesma consulta chega em múltiplas cargas; usamos versão mais recente) e exclusão de datas futuras
- Coorte de 312 refere-se a elegibilidade; a tabela final tem 325 com reativação (13 extras que foram resolvidos mas voltaram)
