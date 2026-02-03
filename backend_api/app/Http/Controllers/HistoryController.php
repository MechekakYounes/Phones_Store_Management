<?php

namespace App\Http\Controllers;

use App\Models\Sale;
use App\Models\BuyPhone;

class HistoryController extends Controller
{
    public function index()
    {
        // SALES
        $sales = Sale::with(['customer', 'creator', 'items.product'])
            ->latest()
            ->get()
            ->map(function ($s) {
                $firstItem = $s->items->first(); // may be null

                return [
                    'type' => 'sale',
                    'title' => 'Sold ' . ($firstItem?->product?->model ?? 'Phone'),
                    'subtitle' => 'To ' . ($s->customer?->name ?? 'Unknown'),
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
                    'title' => 'Added ' . ($b->brand?->name ?? 'Brand') . ' ' . $b->model,
                    'subtitle' => 'From ' . ($b->seller_name ?? 'Unknown'),
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
