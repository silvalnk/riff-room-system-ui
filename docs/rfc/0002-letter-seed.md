# RFC 0002 — Seed das letras

Contexto: as notas não seguem a batida do vídeo.
Decisão: letras `A S D F G`, uma a cada 800 ms, índice `(seed + i * 17) % 5`. A janela de acerto é 400 ms. O relógio chega no `HitWindow`.
Pacotes: performance e booth.
Riscos: cliente e servidor precisam da mesma fórmula. Os dois arquivos repetem a conta de propósito.
Prova: spec de `Performance::Chart` e `HitWindow` no `bin/verify`.
