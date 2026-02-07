<?php

namespace App\Http\Controllers;

use App\Models\Sale;
use App\Models\BuyPhone;
use App\Models\Exchange;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class DashboardController extends Controller
{
    /**
     * Get dashboard statistics
     */
    public function statistics()
    {
        // Today's sales
        $todaySales = Sale::whereDate('created_at', today())
            ->where('payment_status', 'paid')
            ->sum('total_amount');

        $todayDiscount = Sale::whereDate('created_at', today())
            ->where('payment_status', 'paid')
            ->sum('discount_amount');

        $todaySalesNet = $todaySales - $todayDiscount;

        // Calculate today's profit (sales - buy prices)
        $todayProfit = 0;
        $todaySalesRecords = Sale::with('buy_phones')
            ->whereDate('created_at', today())
            ->where('payment_status', 'paid')
            ->get();

        foreach ($todaySalesRecords as $sale) {
            if ($sale->buy_phones) {
                $profit = ($sale->total_amount - $sale->discount_amount) - $sale->buy_phones->buy_price;
                $todayProfit += $profit;
            }
        }

        // Calculate percentage change from yesterday
        $yesterdaySales = Sale::whereDate('created_at', today()->subDay())
            ->where('payment_status', 'paid')
            ->sum('total_amount');

        $yesterdayDiscount = Sale::whereDate('created_at', today()->subDay())
            ->where('payment_status', 'paid')
            ->sum('discount_amount');

        $yesterdaySalesNet = $yesterdaySales - $yesterdayDiscount;

        $salesChangePercent = 0;
        if ($yesterdaySalesNet > 0) {
            $salesChangePercent = (($todaySalesNet - $yesterdaySalesNet) / $yesterdaySalesNet) * 100;
        } elseif ($todaySalesNet > 0) {
            $salesChangePercent = 100;
        }

        // Weekly sales overview
        $weeklySales = Sale::where('created_at', '>=', now()->subWeek())
            ->where('payment_status', 'paid')
            ->sum('total_amount');

        $weeklyDiscount = Sale::where('created_at', '>=', now()->subWeek())
            ->where('payment_status', 'paid')
            ->sum('discount_amount');

        $weeklySalesNet = $weeklySales - $weeklyDiscount;

        // Calculate weekly change
        $previousWeekSales = Sale::whereBetween('created_at', [
                now()->subWeeks(2),
                now()->subWeek()
            ])
            ->where('payment_status', 'paid')
            ->sum('total_amount');

        $previousWeekDiscount = Sale::whereBetween('created_at', [
                now()->subWeeks(2),
                now()->subWeek()
            ])
            ->where('payment_status', 'paid')
            ->sum('discount_amount');

        $previousWeekSalesNet = $previousWeekSales - $previousWeekDiscount;

        $weeklyChangePercent = 0;
        if ($previousWeekSalesNet > 0) {
            $weeklyChangePercent = (($weeklySalesNet - $previousWeekSalesNet) / $previousWeekSalesNet) * 100;
        } elseif ($weeklySalesNet > 0) {
            $weeklyChangePercent = 100;
        }

        // Recent transactions (last 4)
        $recentTransactions = [];

        // Get recent sales
        $recentSales = Sale::with(['customer', 'buy_phones', 'creator'])
            ->latest()
            ->take(4)
            ->get()
            ->map(function ($sale) {
                return [
                    'type' => 'sale',
                    'title' => 'Sale: ' . ($sale->buy_phones?->model ?? 'Phone'),
                    'amount' => $sale->total_amount - $sale->discount_amount,
                    'created_at' => $sale->created_at->toIso8601String(),
                ];
            });

        $recentTransactions = $recentSales->toArray();

        return response()->json([
            'success' => true,
            'data' => [
                'today_sales' => [
                    'amount' => round($todaySalesNet, 2),
                    'change_percent' => round($salesChangePercent, 1),
                ],
                'total_profit' => [
                    'amount' => round($todayProfit, 2),
                ],
                'weekly_sales' => [
                    'amount' => round($weeklySalesNet, 2),
                    'change_percent' => round($weeklyChangePercent, 1),
                ],
                'recent_transactions' => $recentTransactions,
            ],
        ]);
    }
}
