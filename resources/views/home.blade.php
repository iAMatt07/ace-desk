<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#000000">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="ACE Desk">
<link rel="manifest" href="/rdclient/manifest.webmanifest">
<link rel="apple-touch-icon" href="/rdclient/logo.png">
<link rel="icon" href="/favicon.ico">
<title>ACE Desk</title>
<style>
  :root { color-scheme: dark; --red:#ff3d14; --card:#1c1c1e; --card2:#2c2c2e; --muted:#8e8e93; }
  * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
  body { margin:0; background:#000; color:#fff; font-family:-apple-system,BlinkMacSystemFont,"SF Pro Text","Segoe UI",Roboto,sans-serif;
         padding: max(16px, env(safe-area-inset-top)) max(16px, env(safe-area-inset-right)) 24px max(16px, env(safe-area-inset-left)); }
  header { display:flex; align-items:center; gap:12px; max-width:960px; margin:0 auto 20px; }
  header img { width:40px; height:40px; border-radius:10px; }
  header h1 { font-size:22px; font-weight:700; margin:0; flex:1; letter-spacing:-.02em; }
  header h1 span { color:var(--red); }
  .menu { position:relative; }
  .menu > button { background:var(--card); color:#fff; border:0; width:40px; height:40px; border-radius:20px; font-size:22px; line-height:1; cursor:pointer; }
  .menu-list { display:none; position:absolute; right:0; top:46px; background:var(--card2); border-radius:14px; min-width:180px; overflow:hidden; box-shadow:0 10px 30px rgba(0,0,0,.6); z-index:5; }
  .menu.open .menu-list { display:block; }
  .menu-list a, .menu-list button { display:block; width:100%; text-align:left; padding:14px 16px; color:#fff; text-decoration:none; background:none; border:0; font-size:16px; cursor:pointer; }
  .menu-list a + a, .menu-list form { border-top:1px solid #3a3a3c; }
  main { max-width:960px; margin:0 auto; }
  h2 { font-size:13px; text-transform:uppercase; color:var(--muted); font-weight:600; letter-spacing:.06em; margin:0 0 10px 4px; }
  .grid { display:grid; grid-template-columns:repeat(auto-fill, minmax(150px, 1fr)); gap:14px; }
  .tile { display:flex; flex-direction:column; align-items:center; justify-content:center; gap:10px; aspect-ratio:1/1; background:var(--card);
          border-radius:22px; color:#fff; text-decoration:none; padding:14px; position:relative; transition:transform .12s, background .12s; }
  .tile:active { transform:scale(.96); background:var(--card2); }
  .tile svg { width:56%; max-width:96px; height:auto; }
  .tile .name { font-size:16px; font-weight:600; text-align:center; line-height:1.2; word-break:break-word; }
  .tile .sub { font-size:12px; color:var(--muted); }
  .dot { position:absolute; top:12px; right:12px; width:12px; height:12px; border-radius:6px; background:#48484a; }
  .dot.on { background:#30d158; box-shadow:0 0 8px #30d158; }
  .tile.add { background:transparent; border:2px dashed #3a3a3c; color:var(--muted); }
  .tile.add .plus { font-size:44px; line-height:1; color:var(--red); }
  .empty { color:var(--muted); font-size:14px; margin:8px 4px 18px; }
</style>
</head>
<body>
<header>
  <img src="/rdclient/logo.png" alt="">
  <h1>ACE <span>Desk</span></h1>
  <div class="menu" id="menu">
    <button type="button" aria-label="Menu" onclick="document.getElementById('menu').classList.toggle('open')">⋯</button>
    <div class="menu-list">
      <a href="{{ route('power') }}">Energia (hibernar)</a>
      <a href="{{ route('overview') }}">Painel</a>
      <a href="{{ route('devices') }}">Dispositivos</a>
      <a href="{{ route('account') }}">Minha conta</a>
      <form method="post" action="{{ route('logout') }}">@csrf<button type="submit">Sair</button></form>
    </div>
  </div>
</header>
<main>
  <h2>Meus computadores</h2>
  @if (count($devices) === 0)
    <p class="empty">Nenhum computador ainda. Instale o ACE Desk no PC e ele aparece aqui.</p>
  @endif
  <div class="grid">
    @foreach ($devices as $d)
      <a class="tile" href="{{ route('webclient', ['id' => $d['id']]) }}">
        <span class="dot {{ $d['online'] ? 'on' : '' }}" title="{{ $d['online'] ? 'Online' : 'Offline' }}"></span>
        <svg viewBox="0 0 64 56" fill="none" stroke="#D6DBDF" stroke-width="4" stroke-linecap="round"><rect x="4" y="4" width="56" height="36" rx="6"/><path d="M24 52h16M32 40v12"/><circle cx="32" cy="22" r="5" fill="#ff3d14" stroke="none"/></svg>
        <span class="name">{{ $d['name'] }}</span>
        <span class="sub">{{ ctype_digit((string) $d['id']) ? strrev(trim(chunk_split(strrev((string) $d['id']), 3, ' '))) : $d['id'] }}</span>
      </a>
    @endforeach
    <a class="tile add" href="{{ route('webclient') }}">
      <span class="plus">+</span>
      <span class="name">Outro computador</span>
      <span class="sub">Conectar por ID</span>
    </a>
  </div>
</main>
<script>
  document.addEventListener('click', function (e) {
    var m = document.getElementById('menu');
    if (!m.contains(e.target)) m.classList.remove('open');
  });
</script>
</body>
</html>
