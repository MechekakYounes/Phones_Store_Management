<?php

namespace App\Http\Controllers;

use App\Models\Sale;
use App\Models\BuyPhone;

class HistoryController extends Controller
{
    public function index()
    {
        // SALES
        $sales = Sale::with(['customer', 'creator', 'buy_phones'])
            ->latest()
            ->get()
            ->map(function ($s) {
                $firstItem = $s->items->first(); // may be null

                return [
                    'type' => 'sale',
                    'title' => '' . ($s->buy_phones?->model ?? 'Phone'),
                    'subtitle' => 'To ' . ($s->customer?->name ?? 'Unknown') .
                                  ' • IMEI: ' . ($s->phone?->imei ?? 'N/A') .
                                  ' • By: ' . ($s->creator?->name ?? 'System') .
                                  ' • price: ' . ($s->total_amount ?? 0) . 'DA',
                    'amount' => $s->total_amount ?? 0,
                    'created_at' => $s->created_at,
                ];
            });

        // BUYS (Phones added)
        $buys = BuyPhone::with('brand')
            ->latest()
            ->get()
            ->map(function ($b) {
                return [
                    'type' => 'add',
                    'title' => '' . ($b->brand?->name ?? 'Brand') . ' ' . $b->model,
                    'subtitle' => 'From ' . ($b->seller_name ?? 'Unknown') . 
                                  ' • IMEI: ' . ($b->imei ?? 'N/A') .
                                  ' • By: ' . ($b->created_by ? $b->creator->name : 'System'),
                    'amount' => $b->buy_price ?? 0,
                    'created_at' => $b->created_at,
                ];
            });

        // Merge + sort
        $history = $sales->merge($buys)->sortByDesc('created_at')->values();

        return response()->json([
            'success' => true,
            'data' => $history,
        ]);
    }
}
