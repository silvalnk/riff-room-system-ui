# Runbook

Na pasta `riff_room_system_ui`, com Ruby 3.4.8:

```bash
bundle install
bin/rails db:prepare
bin/rails server
```

Redis só é necessário se `ANYCABLE=1`. Sem isso, o desenvolvimento usa o adapter async do Action Cable. Testes usam o adapter `test` e não abrem Redis.

`bin/verify` prepara a expectativa de pronto. Produção aponta o cable para AnyCable e lê `REDIS_URL`.
