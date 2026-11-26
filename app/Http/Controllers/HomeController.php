<?php

namespace App\Http\Controllers;

use App\Models\Device;
use Illuminate\Http\Request;
use Illuminate\View\View;

/**
 * ACE Desk start page ("Meus computadores"): one big tile per computer the
 * user can see. Tapping a tile opens the web client for that ID, which signs
 * straight in when this browser has the password saved.
 */
class HomeController extends Controller
{
    public function index(Request $request): View
    {
        $devices = Device::query()
            ->visibleTo($request->user())
            ->orderByDesc('last_online_at')
            ->get()
            ->map(fn (Device $d) => [
                'id' => (string) $d->rustdesk_id,
                'name' => $d->alias ?: ($d->hostname ?: (string) $d->rustdesk_id),
                'os' => (string) $d->os,
                'online' => $d->isOnline(),
            ]);

        return view('home', ['devices' => $devices]);
    }
}
