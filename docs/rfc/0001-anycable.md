# RFC 0001 — AnyCable só espalha

Contexto: uma sala, um processo Puma, SQLite.
Decisão: AnyCable e Redis entregam o Turbo Stream. Não são a fonte da fila nem do voto.
Pacotes: booth, via outbox no `RoomGateway`.
Riscos: dois Pumas escrevendo o mesmo arquivo SQLite quebram o modelo. Aí o banco muda.
Prova: `bin/verify` passa com o adapter de teste, sem Redis.
