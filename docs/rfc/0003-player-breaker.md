# RFC 0003 — Falha do player

Contexto: o IFrame pode recusar o vídeo.
Decisão: o controller Stimulus `youtube`, no `onError`, pede uma vez a mesma troca de DJ do fim de turno. Não há circuit breaker no servidor.
Pacotes: o edge Stimulus e o `interrupt` do gateway.
Riscos: vários clientes podem pedir a troca. A segunda encontra a sala já avançada e não faz nada.
Prova: `interrupt` com motivo fora da lista devolve erro; `ended` e `player_error` avançam.
