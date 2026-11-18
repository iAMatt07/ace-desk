import type { GestureEvent, Pt } from './gesture';

/** Mouse output shared by the touch mappers: client coordinates in, host input out. */
export type TouchOutput = {
  /** MOVE / DOWN / UP at a client point (mask = buttonMask(type, buttons)). */
  mouse(type: 'move' | 'down' | 'up', button: number, at: Pt): void;
  /** Wheel steps (RustDesk sign convention: positive = up / left). */
  wheel(x: number, y: number): void;
  haptic(): void;
  /** Three-finger tap. */
  keyboard(): void;
  /** Local zoom: multiply by scale about center, then pan. */
  zoom(scale: number, center: Pt, pan: Pt): void;
  /** Is the local view zoomed in? (one-finger drag pans then, scrolls otherwise) */
  zoomed?(): boolean;
};

/** Turns gesture intents into input; one per touch mode. */
export type GestureMapper = { handle(e: GestureEvent): void };

export const LEFT = 0x01;
export const RIGHT = 0x02;

/** Finger travel per wheel step for two-finger scrolling. */
export const SCROLL_STEP_PX = 40;

/**
 * Two-finger scroll -> wheel steps. Natural scrolling: fingers moving down
 * reveal what is above, which is a wheel step UP (+1 in RustDesk's
 * convention). The remainder carries over so slow drags still scroll.
 */
export class ScrollAccumulator {
  private x = 0;
  private y = 0;
  constructor(private readonly stepPx = SCROLL_STEP_PX) {}

  add(dx: number, dy: number): { x: number; y: number } {
    this.x += dx;
    this.y += dy;
    const sx = Math.trunc(this.x / this.stepPx);
    const sy = Math.trunc(this.y / this.stepPx);
    this.x -= sx * this.stepPx;
    this.y -= sy * this.stepPx;
    return { x: sx, y: sy };
  }

  reset(): void {
    this.x = this.y = 0;
  }
}

/**
 * Touch (direct) mode ("Clicar"): the finger is the mouse, where it touches.
 * tap = click there, double tap = double click, two-finger tap = right click,
 * three-finger tap = keyboard, pinch = local zoom.
 * One-finger drag: pans the view when zoomed in, scrolls the page otherwise
 * (like a phone). Hold still for a moment then drag = left-button drag
 * (select text, move windows); hold and lift without moving = right click.
 * Two-finger drag = scroll.
 */
export class DirectTouchMapper {
  private readonly scroll = new ScrollAccumulator();
  /** What the current one-finger drag does. */
  private drag: 'none' | 'button' | 'pan' | 'scroll' = 'none';

  constructor(private readonly out: TouchOutput) {}

  handle(e: GestureEvent): void {
    const o = this.out;
    switch (e.g) {
      case 'tap':
        if (e.fingers === 3) {
          o.keyboard();
          return;
        }
        this.click(e.fingers === 2 ? RIGHT : LEFT, e.at);
        return;
      case 'longPress':
        // Wait: lifting now is a right click, moving is a button drag.
        o.haptic();
        return;
      case 'pressEnd':
        this.click(RIGHT, e.at);
        return;
      case 'dragStart':
        if (e.held) {
          o.mouse('move', 0, e.from);
          o.mouse('down', LEFT, e.from);
          o.mouse('move', 0, e.at);
          this.drag = 'button';
          return;
        }
        this.drag = o.zoomed?.() ? 'pan' : 'scroll';
        this.scroll.reset();
        this.moveBy(e.at.x - e.from.x, e.at.y - e.from.y, e.at);
        return;
      case 'dragMove':
        if (this.drag === 'button') o.mouse('move', 0, e.at);
        else this.moveBy(e.delta.x, e.delta.y, e.at);
        return;
      case 'dragEnd':
        if (this.drag === 'button') {
          if (!e.cancelled) o.mouse('move', 0, e.at);
          o.mouse('up', LEFT, e.at);
        }
        this.drag = 'none';
        return;
      case 'scroll': {
        const s = this.scroll.add(e.dx, e.dy);
        if (s.x || s.y) o.wheel(s.x, s.y);
        return;
      }
      case 'pinch':
        o.zoom(e.scale, e.center, e.pan);
        return;
      case 'idle':
        this.scroll.reset();
        return;
      case 'down':
        return;
    }
  }

  private moveBy(dx: number, dy: number, at: Pt): void {
    if (this.drag === 'pan') {
      this.out.zoom(1, at, { x: dx, y: dy });
      return;
    }
    if (this.drag === 'scroll') {
      const s = this.scroll.add(dx, dy);
      if (s.x || s.y) this.out.wheel(s.x, s.y);
    }
  }

  private click(button: number, at: Pt): void {
    this.out.mouse('move', 0, at);
    this.out.mouse('down', button, at);
    this.out.mouse('up', button, at);
  }
}
