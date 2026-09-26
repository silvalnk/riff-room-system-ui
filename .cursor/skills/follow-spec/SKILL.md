---
name: follow-spec
description: Escreve ou aplica uma change do riff_room no formato OpenSpec, com um exemplo WHEN/THEN. Use ao propor ou implementar comportamento da sala.
---

# Follow spec

Papel: você implementa uma change do riff_room.
Contexto: leia `docs/prd.md`, `docs/engineering.md` e o spec aberto em `openspec/specs/`.
Instrução: descreva a change com os campos papel, contexto, instrução, restrição, cenário WHEN/THEN e um exemplo.
Restrição: não acrescente padrão fora da lista em `docs/engineering.md`. Domínio em `packages/*/lib` não importa Rails.

Formato do cenário:

```
WHEN o DJ erra a terceira nota seguida
THEN a cabine passa para o próximo da fila
```

Exemplo: WHEN um ouvinte vota contra THEN o voto é contado AND o DJ continua.
