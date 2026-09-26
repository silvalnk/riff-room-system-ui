# C4 — Componentes

```mermaid
flowchart LR
  http[RoomsController]
  gate[RoomGateway]
  booth[booth]
  perf[performance]
  vote[appreciation]
  http --> gate
  gate --> booth
  gate --> perf
  gate --> vote
```
