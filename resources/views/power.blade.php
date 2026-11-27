<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#000000">
<link rel="icon" href="/favicon.ico">
<title>Energia · ACE Desk</title>
<style>
  :root { color-scheme: dark; --red:#ff3d14; --card:#1c1c1e; --card2:#2c2c2e; --muted:#8e8e93; --line:#3a3a3c; }
  * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
  body { margin:0; background:#000; color:#fff; font-family:-apple-system,BlinkMacSystemFont,"SF Pro Text","Segoe UI",Roboto,sans-serif;
         padding: max(16px, env(safe-area-inset-top)) max(16px, env(safe-area-inset-right)) 32px max(16px, env(safe-area-inset-left)); }
  header { display:flex; align-items:center; gap:12px; max-width:640px; margin:0 auto 20px; }
  header a.back { color:var(--red); text-decoration:none; font-size:17px; }
  header h1 { font-size:22px; font-weight:700; margin:0; flex:1; text-align:center; padding-right:56px; }
  main { max-width:640px; margin:0 auto; }
  h2 { font-size:13px; text-transform:uppercase; color:var(--muted); font-weight:600; letter-spacing:.06em; margin:22px 0 8px 4px; }
  .card { background:var(--card); border-radius:16px; overflow:hidden; }
  .row { display:flex; align-items:center; justify-content:space-between; gap:12px; padding:14px 16px; min-height:52px; }
  .row + .row { border-top:1px solid var(--line); }
  .row label.t { font-size:16px; }
  .row small { display:block; color:var(--muted); font-size:13px; margin-top:2px; }
  select, input[type=time] { background:var(--card2); color:#fff; border:0; border-radius:10px; padding:9px 10px; font-size:16px; font-family:inherit; }
  input[type=time]::-webkit-calendar-picker-indicator { filter: invert(1); }
  .sw { position:relative; width:51px; height:31px; flex:none; }
  .sw input { opacity:0; width:0; height:0; }
  .sw span { position:absolute; inset:0; background:#39393d; border-radius:16px; transition:.2s; }
  .sw span:before { content:""; position:absolute; width:27px; height:27px; left:2px; top:2px; background:#fff; border-radius:50%; transition:.2s; }
  .sw input:checked + span { background:#30d158; }
  .sw input:checked + span:before { transform:translateX(20px); }
  .days { display:flex; gap:6px; flex-wrap:wrap; }
  .days label { position:relative; }
  .days input { position:absolute; opacity:0; }
  .days span { display:inline-flex; width:38px; height:38px; border-radius:19px; align-items:center; justify-content:center; background:var(--card2); color:var(--muted); font-size:14px; font-weight:600; }
  .days input:checked + span { background:var(--red); color:#fff; }
  button.save { display:block; width:100%; margin-top:14px; background:var(--red); color:#fff; border:0; border-radius:14px; padding:15px; font-size:17px; font-weight:600; font-family:inherit; }
  button.hib { background:var(--card2); color:#fff; margin-top:10px; }
  .note { color:var(--muted); font-size:13px; line-height:1.45; margin:10px 4px 0; }
  .ok { background:#0f2e1a; color:#30d158; border-radius:12px; padding:12px 14px; margin-bottom:12px; font-size:15px; }
  .helper { font-size:14px; }
  .helper.on { color:#30d158; } .helper.off { color:#ff9f0a; }
  a.inst { color:var(--red); }
</style>
</head>
<body>
<header>
  <a class="back" href="{{ route('home') }}">‹ Voltar</a>
  <h1>Energia</h1>
</header>
<main>
  @if (session('hibernating'))
    <div class="ok">Pedido enviado. Em até 1 minuto o PC mostra um aviso de 15 segundos e hiberna.</div>
  @endif
  @if (session('saved'))
    <div class="ok">Salvo. O PC aplica em até 1 minuto.</div>
  @endif
  @if (count($devices) === 0)
    <p class="note">Nenhum computador ainda.</p>
  @endif
  @foreach ($devices as $d)
    @php($s = $d['settings'])
    <form method="post" action="{{ route('power.update', ['id' => $d['id']]) }}">
      @csrf
      <h2>{{ $d['name'] }}</h2>
      <div class="card">
        <div class="row">
          <label class="t" for="en-{{ $d['id'] }}">Hibernar automaticamente<small>Liga ou desliga todas as regras abaixo</small></label>
          <label class="sw"><input type="checkbox" id="en-{{ $d['id'] }}" name="enabled" value="1" {{ $s['enabled'] ? 'checked' : '' }}><span></span></label>
        </div>
        <div class="row">
          <label class="t" for="idle-{{ $d['id'] }}">Parado por<small>Sem mouse/teclado e sem render</small></label>
          <select id="idle-{{ $d['id'] }}" name="idle_minutes">
            @foreach ([0 => 'Nunca', 15 => '15 min', 30 => '30 min', 45 => '45 min', 60 => '1 hora', 90 => '1h30', 120 => '2 horas', 180 => '3 horas', 240 => '4 horas', 360 => '6 horas'] as $m => $lbl)
              <option value="{{ $m }}" {{ (int) $s['idle_minutes'] === $m ? 'selected' : '' }}>{{ $lbl }}</option>
            @endforeach
          </select>
        </div>
        <div class="row">
          <label class="t" for="sleep-{{ $d['id'] }}">Hibernar às<small>Vazio = sem horário</small></label>
          <input type="time" id="sleep-{{ $d['id'] }}" name="sleep_time" value="{{ $s['sleep_time'] }}">
        </div>
        <div class="row">
          <label class="t" for="wake-{{ $d['id'] }}">Ligar às<small>Acorda da hibernação</small></label>
          <input type="time" id="wake-{{ $d['id'] }}" name="wake_time" value="{{ $s['wake_time'] }}">
        </div>
        <div class="row">
          <span class="t">Dias dos horários</span>
          <div class="days">
            @foreach ([1 => 'S', 2 => 'T', 3 => 'Q', 4 => 'Q', 5 => 'S', 6 => 'S', 7 => 'D'] as $n => $lbl)
              <label title="{{ ['', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'][$n] }}"><input type="checkbox" name="days[]" value="{{ $n }}" {{ in_array($n, $s['days'], true) ? 'checked' : '' }}><span>{{ $lbl }}</span></label>
            @endforeach
          </div>
        </div>
        <div class="row">
          <span class="t">Ajudante no PC</span>
          @if ($d['helper_seen'] && $d['helper_seen']->gt(now()->subMinutes(3)))
            <span class="helper on">● Ativo</span>
          @elseif ($d['helper_seen'])
            <span class="helper off">Visto {{ $d['helper_seen']->locale('pt_BR')->diffForHumans() }}</span>
          @else
            <a class="inst helper" href="{{ route('power.installer', ['id' => $d['id']]) }}">Baixar instalador</a>
          @endif
        </div>
      </div>
      <button class="save" type="submit">Salvar</button>
    </form>
    @if ($d['helper_seen'])
      <form method="post" action="{{ route('power.hibernate', ['id' => $d['id']]) }}" onsubmit="return confirm('Hibernar o {{ $d['name'] }} agora? Você perde a conexão até ele ligar de novo.');">
        @csrf
        <button class="save hib" type="submit">Hibernar agora</button>
      </form>
    @endif
  @endforeach
  <p class="note">Antes de hibernar, o PC mostra um aviso de 1 minuto com o botão Cancelar. Se estiver renderizando ou exportando, ele espera terminar. Hibernado, o PC liga de novo no horário de ligar ou pelo desliga-e-liga da tomada.</p>
</main>
<script>
  // Mexeu em alguma regra? Liga a chave "Hibernar automaticamente" sozinho.
  document.querySelectorAll('form').forEach(function (f) {
    var sw = f.querySelector('input[name=enabled]');
    f.querySelectorAll('select, input[type=time], input[name="days[]"]').forEach(function (el) {
      el.addEventListener('change', function () { if (sw) sw.checked = true; });
    });
  });
</script>
</body>
</html>
