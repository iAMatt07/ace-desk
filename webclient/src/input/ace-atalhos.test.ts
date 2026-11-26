import { describe, expect, it } from 'vitest';
import { XKEY_PAGES, xkeyCommands, ModifierLatches } from './extra-keys';

const atalhos = XKEY_PAGES[0]!;
const key = (id: string) => atalhos.keys.find((k) => k.id === id)!;

describe('ACE Desk — página Atalhos', () => {
  it('é a primeira página da barra', () => {
    expect(atalhos.id).toBe('atalhos');
    expect(atalhos.label).toBe('Atalhos');
  });

  it('começa pelas teclas-chave (sempre à vista) e depois os atalhos, na ordem', () => {
    expect(atalhos.keys.map((k) => k.label)).toEqual([
      'Ctrl', 'Shift', 'Alt', 'Win',
      'Copiar', 'Colar', 'Desfazer', 'Sel. tudo', 'Salvar', 'Alt+Tab', 'Área de trab.',
      'Esc', 'Enter', 'Del', 'Ctrl+Alt+Del',
      'Monitor', 'Bloquear PC', 'Tela preta',
    ]);
  });

  it('Salvar manda Ctrl apertado, S, e solta o Ctrl', () => {
    const cmds = xkeyCommands(key('a-save'), [], 'windows');
    const downs = cmds.filter((c) => c.c === 'key').map((c) => (c as { down: boolean }).down);
    expect(cmds.length).toBe(4);
    expect(downs).toEqual([true, true, false, false]);
  });

  it('Ctrl + Shift travados + Esc vira Ctrl+Shift+Esc (Gerenciador de Tarefas)', () => {
    const l = new ModifierLatches();
    l.tap('ctrl', 0);
    l.tap('shift', 1000);
    const cmds = xkeyCommands(key('a-esc'), l.active(), 'windows');
    expect(cmds.length).toBe(6); // ctrl↓ shift↓ esc↓ esc↑ shift↑ ctrl↑
    expect(l.consume()).toBe(true);
    expect(l.active()).toEqual([]);
  });

  it('Ctrl+Alt+Del usa o comando especial', () => {
    expect(xkeyCommands(key('a-cad'), [], 'windows')).toEqual([{ c: 'ctrlAltDel' }]);
  });
});
