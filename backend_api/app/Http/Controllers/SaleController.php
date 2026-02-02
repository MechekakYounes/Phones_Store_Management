<?php

namespace App\Http\Controllers;

use App\Models\Sale;
use App\Models\Customer;
use App\Models\Product;
use App\Models\BuyPhone;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use App\Http\Controllers\Controller;


class SaleController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        //
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'buyer_name'      => 'required|string|max:255',
            'buyer_phone'     => 'nullable|string|max:50',
            'buyer_address'   => 'nullable|string|max:500',
            'total_amount'    => 'required|numeric|min:0',
            'discount_amount' => 'nullable|numeric|min:0',
            'notes'           => 'nullable|string',
            'buy_phone_id'    => 'required|exists:buy_phones,id', // ✅ IMPORTANT
        ]);
    
        return DB::transaction(function () use ($request) {
    
            // 1️⃣ Create or reuse customer
            $customer = Customer::firstOrCreate(
                ['phone' => $request->buyer_phone],
                [
                    'name'    => $request->buyer_name,
                    'address' => $request->buyer_address,
                ]
            );
    
            // 2️⃣ Create Sale
            $sale = Sale::create([
                'customer_id'     => $customer->id,
                'total_amount'    => $request->total_amount,
                'discount_amount' => $request->discount_amount ?? 0,
                'payment_status'  => 'paid',
                'notes'           => $request->notes,
                'created_by'      => auth()->id(),
            ]);
    
            // 3️⃣ Mark BuyPhone as SOLD
            $phone = BuyPhone::find($request->buy_phone_id);
    
            if (!$phone) {
                return response()->json([
                    'success' => false,
                    'message' => 'BuyPhone not found'
                ], 404);
            }
    
            $phone->status = BuyPhone::STATUS_SOLD;
            $phone->sold_date = now();
            $phone->save();
    
            return response()->json([
                'success'  => true,
                'message'  => 'Sale completed successfully',
                'sale'     => [
                    'id'            => $sale->id,
                    'buyer_name'    => $customer->name,
                    'buyer_phone'   => $customer->phone,
                    'buyer_address' => $customer->address,
                    'model'         => $phone->model,
                    'imei'          => $phone->imei,
                    'storage'       => $phone->storage,
                    'color'         => $phone->color,
                    'price'         => $sale->total_amount,
                    'discount'      => $sale->discount_amount,
                    'total'         => $sale->total_amount - $sale->discount_amount,
                    'created_at'    => $sale->created_at->format('Y-m-d H:i:s'),
                ],
                // We keep these for debugging or other uses if needed, 
                // but the MAIN 'sale' object above is what InvoicePage uses.
                'raw_sale'     => $sale,
                'raw_customer' => $customer,
            ]);
        });
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }
}
