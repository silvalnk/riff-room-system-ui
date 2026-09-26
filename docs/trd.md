# TRD — riff_room

Rails 8, Ruby 3.4, Puma, Hotwire, importmap, Propshaft, SQLite, bcrypt. Redis e AnyCable só espalham a mensagem depois do commit. A verdade fica no SQLite, com um escritor.

Pacotes em `packages/`: presence, booth, performance, appreciation. O domínio mora em `lib` e não vê ActiveRecord. `RoomGateway` é a porta: transação, `lock_version`, outbox e Turbo Stream.

O broadcast manda `videoId`, `startedAt` e `seed`. O Stimulus `youtube` usa a IFrame API, dá `seekTo` pelo tempo decorrido e, se o player falha, pede a mesma troca de DJ. O `highway` desenha as letras e só envia tecla de quem é o DJ.

`bin/verify` roda a suíte.
