<?php

namespace App\Http\Controllers;

use App\Models\Exchange;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use App\Models\Customer;
use App\Models\BuyPhone;
use App\Models\Sale;

class ExchangesController extends Controller
{
    /**
     * List all exchanges
     */
    public function index()
    {
        $exchanges = Exchange::with([
                'sale',
                'buyPhone',
                'customer',
                'processor'
            ])
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $exchanges,
        ]);
    }

    /**
     * Store a new exchange
     */
     public function store(Request $request)
    {
        $request->validate([
            // Customer
            'customer_name'   => 'required|string|max:255',
            'customer_phone'  => 'required|string|max:50',

            // Received phone (customer → shop)
            'received.brand_id'  => 'required|exists:brands,id',
            'received.model'     => 'required|string',
            'received.color'     => 'nullable|string',
            'received.storage'   => 'nullable|string',
            'received.imei'      => 'required|string|unique:buy_phones,imei',
            'received.condition' => 'required|string',
            'received.buy_price' => 'required|numeric|min:0',
            'received.resell_price' => 'nullable|numeric|min:0',

            // Sold phone (shop → customer)
            'sold.buy_phone_id' => 'required|exists:buy_phones,id',
            'sold.price'        => 'required|numeric|min:0',
        ]);

        return DB::transaction(function () use ($request) {

            
            $customer = Customer::firstOrCreate(
                ['phone' => $request->customer_phone],
                ['name' => $request->customer_name]
            );

            $receivedPhone = BuyPhone::create([
                'seller_name'   => $customer->name,
                'seller_phone'  => $customer->phone,
                'brand_id'      => $request->received['brand_id'],
                'model'         => $request->received['model'],
                'color'         => $request->received['color'] ?? null,
                'storage'       => $request->received['storage'] ?? null,
                'imei'          => $request->received['imei'],
                'condition'     => $request->received['condition'],
                'buy_price'     => $request->received['buy_price'],
                'resell_price'  => $request->received['resell_price'] ?? $request->received['buy_price'],
                'received_date' => now(),
                'received_by'   => auth()->id(),
                'created_by'    => auth()->id(),
                'status'        => BuyPhone::STATUS_RECEIVED,
            ]);


            $soldPhone = BuyPhone::findOrFail($request->sold['buy_phone_id']);

            $sale = Sale::create([
                'customer_id'     => $customer->id,
                'total_amount'    => $request->sold['price'],
                'discount_amount' => 0,
                'tax_amount'      => 0,
                'paid_amount'     => max(0, $request->sold['price'] - $request->received['buy_price']),
                'payment_status'  => Sale::PAYMENT_PAID,
                'created_by'      => auth()->id(),
            ]);


            $soldPhone->update([
                'status'    => BuyPhone::STATUS_SOLD,
                'sold_date' => now(),
                'sold_to'   => $customer->id,
            ]);

            $difference = $request->sold['price'] - $request->received['buy_price'];
            $exchange = Exchange::create([
                'sale_id'           => $sale->id,
                'buy_phone_id'      => $receivedPhone->id, // received phone
                'customer_id'       => $customer->id,
                'difference_amount' => $difference,
                'status'            => Exchange::STATUS_COMPLETED,
                'processed_by'      => auth()->id(),
            ]);

            return response()->json([
                'success'  => true,
                'message'  => 'Exchange completed successfully',
                'exchange' => $exchange->load(['customer', 'sale', 'buyPhone', 'processor']),
            ], 201);
        });
    }
    /**
     * Mark exchange as completed
     */
    public function complete($id)
    {
        $exchange = Exchange::findOrFail($id);
        $exchange->markAsCompleted();

        return response()->json([
            'success' => true,
            'message' => 'Exchange completed successfully',
            'data' => $exchange->fresh(),
        ]);
    }

    /**
     * Cancel exchange
     */
    public function cancel($id)
    {
        $exchange = Exchange::findOrFail($id);
        $exchange->markAsCancelled();

        return response()->json([
            'success' => true,
            'message' => 'Exchange cancelled successfully',
            'data' => $exchange->fresh(),
        ]);
    }

    /**
     * Delete exchange
     */
    public function destroy($id)
    {
        $exchange = Exchange::findOrFail($id);
        $exchange->delete();

        return response()->json([
            'success' => true,
            'message' => 'Exchange deleted successfully',
        ]);
    }
}
