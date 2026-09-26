# Engenharia

Três camadas. `packages/*/lib/domain` não importa Rails: agregado `Booth::Room`, value object da URL, `HitWindow`, `FailurePolicy`, `Ballot`, `Notice`. `packages/*/lib/application` são os casos de uso (`EnqueueSong`, `PressKey`, `InterruptTurn`, `SyncPlayback`, `CastVote`, `EnterRoom`). A infraestrutura fica em `packages/*/lib/infrastructure`: a cabine guarda `Room`, `QueueEntry`, `Keypress` e o outbox; o voto guarda `Vote`; a presença guarda `User` e `RoomPresence`. `ApplicationRecord`, `ApplicationJob`, `ApplicationMailer`, `PasswordsMailer` e `Current` ficam em `packages/shared_kernel`. `Session` fica em presence, ao lado de `User`. A conexão do cabo também fica em presence, porque identifica a sessão. O `RoomGateway` fica em `packages/room` e depende de booth, appreciation e presence. A autenticação do cookie fica em presence. Views, CSS, Stimulus, helpers e controllers ficam em `app/`.

Padrões em uso: monólito modular com fachada, onion, agregado e repositório, estado idle/playing/handoff, strategy da falha, specification `HitWindow` com relógio injetado, CQRS leve (comando grava, Turbo lê o snapshot, o canvas deriva as letras), transação do ActiveRecord como unit of work, eventos de turno e voto, outbox, lock otimista, tecla idempotente por índice, notification só em entrar/URL/voto, circuit breaker só no controller do YouTube.

Configuração por ambiente: `REDIS_URL` e o banco. Puma não guarda a sala. Log vai para stdout.

Não entram: event sourcing, saga, circuit breaker no servidor, LLM, RAG, feature flag, Factory, Singleton, Decorator, Chain, Mediator, Builder e Command com undo.
