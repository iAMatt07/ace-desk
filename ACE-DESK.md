# ACE Desk

Acesso remoto da ACE (aaccessbr.com), feito para substituir o AnyDesk.
Fork do [CortenDesk](https://github.com/marcpope/cortendesk), que usa o [RustDesk](https://github.com/rustdesk/rustdesk). Licença **AGPL-3.0**, e este código continua público.

## O que muda em relação ao CortenDesk
- Barra de teclas do celular: a primeira página é **Atalhos** (Copiar, Colar, Desfazer, Sel. tudo, Salvar, Alt+Tab, Área de trab., Esc, Enter, Del, Ctrl+Alt+Del + Ctrl/Shift/Alt/Win travados para montar qualquer combinação) — `webclient/src/input/extra-keys.ts`
- Visual no estilo Apple, com o vermelho da ACE (#FF3D14) — `webclient/src/ui/app.css`
- Nome, ícone e logo do ACE Desk
- Kit de instalação em português para a Oracle Cloud Free — `acedesk-deploy/`
