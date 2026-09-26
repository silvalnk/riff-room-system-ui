---
name: room-ui
description: Traduz o desenho .pen da sala riff_room para ERB, CSS e Stimulus. Use ao alterar a página da sala, o canvas ou o player.
---

# Room UI

A sala é uma página escura. O vídeo do YouTube fica atrás, em tela cheia, via IFrame API. O canvas das letras fica no centro. O chrome (fila, DJ, votos, URL) fica à direita.

Implemente em ERB, `app/assets/stylesheets/application.css` e nos controllers Stimulus `youtube` e `highway`. Não use React. Não extraia áudio do YouTube. O teclado só conta quando o id do usuário na meta `current-user-id` é o `data-dj-id` da sala.
