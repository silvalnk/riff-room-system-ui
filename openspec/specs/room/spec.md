# Sala

## Requirement: Ouvir sem conta

A sala SHALL abrir para quem não tem conta. Conta é exigida para entrar na fila, colar URL, ser DJ e votar.

### Scenario: Convidado

WHEN uma pessoa abre a raiz sem sessão
THEN a página mostra a cabine
AND o texto diz que a conta é necessária para tocar

## Requirement: Troca de DJ

O sistema SHALL passar a vez após 3 erros seguidos ou 8 erros no turno, ou quando o vídeo termina.

### Scenario: Três erros

WHEN o DJ erra a terceira nota seguida
THEN o próximo da fila vira DJ

### Scenario: Voto

WHEN um ouvinte troca o voto
THEN existe um voto daquele perfil na música
AND o DJ continua o mesmo
