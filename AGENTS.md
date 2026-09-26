# riff_room

Antes de mudar a sala, leia `docs/prd.md`, o spec em `openspec/specs/room/spec.md` e a lista fechada em `docs/engineering.md`.

`bin/verify` é o critério de pronto: RSpec do domínio e o system test da página.

Controllers chamam `RoomGateway`. O código em `packages/*/lib` não importa Rails.
