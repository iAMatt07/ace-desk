<?php

namespace App\Http\Controllers;

use App\Models\Device;
use App\Models\Setting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Str;
use Illuminate\View\View;

/**
 * ACE Desk "Energia": per-computer hibernate rules (idle time, daily
 * hibernate / wake times). The rules are stored in the settings table and
 * read every minute by the small helper installed on the computer
 * (public/ace-energia/ace-energia.ps1), which applies them.
 */
class PowerController extends Controller
{
    public const DEFAULTS = [
        'enabled' => false,
        'idle_minutes' => 0,
        'sleep_time' => '',
        'wake_time' => '',
        'days' => [1, 2, 3, 4, 5, 6, 7],
    ];

    public static function settingsFor(string $id): array
    {
        $raw = Setting::get('ace_power.'.$id);
        $data = $raw ? (json_decode($raw, true) ?: []) : [];

        return array_merge(self::DEFAULTS, array_intersect_key($data, self::DEFAULTS));
    }

    public function index(Request $request): View
    {
        $devices = Device::query()
            ->visibleTo($request->user())
            ->orderByDesc('last_online_at')
            ->get()
            ->map(function (Device $d) {
                $id = (string) $d->rustdesk_id;
                $seen = Setting::get('ace_power_seen.'.$id);

                return [
                    'id' => $id,
                    'name' => $d->alias ?: ($d->hostname ?: $id),
                    'settings' => self::settingsFor($id),
                    'helper_seen' => $seen ? \Carbon\Carbon::parse($seen) : null,
                ];
            });

        return view('power', ['devices' => $devices]);
    }

    public function update(Request $request, string $id): RedirectResponse
    {
        $this->device($request, $id);
        $v = $request->validate([
            'enabled' => ['nullable'],
            'idle_minutes' => ['nullable', 'integer', 'min:0', 'max:1440'],
            'sleep_time' => ['nullable', 'date_format:H:i'],
            'wake_time' => ['nullable', 'date_format:H:i'],
            'days' => ['nullable', 'array'],
            'days.*' => ['integer', 'between:1,7'],
        ]);
        $data = [
            'enabled' => $request->boolean('enabled'),
            'idle_minutes' => (int) ($v['idle_minutes'] ?? 0),
            'sleep_time' => (string) ($v['sleep_time'] ?? ''),
            'wake_time' => (string) ($v['wake_time'] ?? ''),
            'days' => array_values(array_unique(array_map('intval', $v['days'] ?? []))),
        ];
        sort($data['days']);
        Setting::put('ace_power.'.$id, json_encode($data));

        return redirect()->route('power')->with('saved', $id);
    }

    /** Installer for the helper, with this computer's ID and secret filled in. */
    public function installer(Request $request, string $id): Response
    {
        $this->device($request, $id);
        $token = Setting::get('ace_power_token.'.$id);
        if (! $token) {
            $token = Str::random(40);
            Setting::put('ace_power_token.'.$id, $token);
        }
        $tpl = file_get_contents(public_path('ace-energia/instalar-template.bat'));
        $bat = strtr($tpl, [
            '__ACE_URL__' => 'https://'.$request->getHost(),
            '__ACE_ID__' => $id,
            '__ACE_TOKEN__' => $token,
        ]);
        $bat = str_replace(["\r\n", "\n"], ["\n", "\r\n"], $bat);

        return response($bat, 200, [
            'Content-Type' => 'application/octet-stream',
            'Content-Disposition' => 'attachment; filename="ACE-Desk-Energia-instalar.bat"',
        ]);
    }

    /** Read by the helper on the computer (token auth, no session). */
    public function api(Request $request, string $id): JsonResponse
    {
        $token = Setting::get('ace_power_token.'.$id);
        if (! $token || ! hash_equals($token, (string) $request->query('t', ''))) {
            return response()->json(['error' => 'unauthorized'], 403);
        }
        Setting::put('ace_power_seen.'.$id, now()->toIso8601String());

        return response()->json(self::settingsFor($id) + ['server_time' => now()->toIso8601String()]);
    }

    private function device(Request $request, string $id): Device
    {
        return Device::query()->visibleTo($request->user())->where('rustdesk_id', $id)->firstOrFail();
    }
}
