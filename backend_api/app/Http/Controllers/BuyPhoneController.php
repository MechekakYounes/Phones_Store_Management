<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\BuyPhone;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class BuyPhoneController extends Controller
{
    // GET /api/buy-phones
    public function index(Request $request)
{
    $query = BuyPhone::with(['brand', 'receiver', 'buyer', 'exchange']);

    // 🔹 Default: exclude sold phones
    if (!$request->filled('status')) {
        $query->where('status', '!=', BuyPhone::STATUS_SOLD)
              ->orWhereNull('status');
    }

    // 🔍 Search
    if ($request->filled('search')) {
        $query->search($request->search);
    }

    // 🔎 Filters
    if ($request->filled('status')) {
        if ($request->status === 'sold') {
            $query->sold();
        } elseif ($request->status === 'available') {
            $query->available();
        } elseif ($request->status === 'needs_testing') {
            $query->needsTesting();
        }
    }

    if ($request->filled('condition')) {
        $query->byCondition($request->condition);
    }

    if ($request->filled('brand_id')) {
        $query->byBrand($request->brand_id);
    }

    if ($request->filled('start_date')) {
        $query->dateRange($request->start_date, $request->end_date);
    }

    $phones = $query->latest()->paginate(20);

    return response()->json([
        'success' => true,
        'data' => $phones
    ]);
}


    // GET /api/buy-phones/{id}
    public function show($id)
    {
        $phone = BuyPhone::findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $phone
        ]);
    }

    // POST /api/buy-phones
    public function store(Request $request)
    {
        try {
            // Check IMEI existence with error handling
            try {
                if (BuyPhone::imeiExists($request->imei)) {
                    return response()->json([
                        'success' => false,
                        'message' => 'IMEI already exists in inventory'
                    ], 422);
                }
            } catch (\Exception $e) {
                \Log::warning('Error checking IMEI existence: ' . $e->getMessage());
                // Continue if IMEI check fails (might be due to missing Product model)
            }

            $validated = $request->validate([
                'seller_name'   => 'required|string|max:255',
                'seller_phone'  => 'nullable|string|max:50',
                'brand_id'      => 'required|exists:brands,id',
                'model'         => 'required|string|max:255',
                'color'         => 'nullable|string|max:100',
                'storage'       => 'nullable|string|max:50',
                'imei'          => 'required|string|size:15',
                'condition'     => 'required|string|in:excellent,very_good,good,fair,damaged,broken',
                'buy_price'     => 'required|numeric|min:0',
                'resell_price'  => 'nullable|numeric|min:0',
                'received_date' => 'nullable|date',
                'received_by'   => 'nullable|exists:users,id',
                'status'        => 'nullable|string',
                'notes'         => 'nullable|string',
                'issues'        => 'nullable|string',
            ]);

            // Set received_by to authenticated user if not provided
            if (!isset($validated['received_by']) && auth()->check()) {
                $validated['received_by'] = auth()->id();
            }

            // Set received_date to current date if not provided
            if (!isset($validated['received_date'])) {
                $validated['received_date'] = now()->toDateString();
            }

            // Ensure condition is set (required for resell price calculation)
            if (empty($validated['condition'])) {
                $validated['condition'] = 'good'; // Default condition
            }
            if (empty($validated['status'])) {
                $validated['status'] = 'received'; // Default condition
            }

            // The model's boot method will auto-calculate resell_price if not provided
            $phone = BuyPhone::create($validated);
            
            // Refresh to get any auto-calculated values
            $phone->refresh();

            return response()->json([
                'success' => true,
                'message' => 'Phone bought and added successfully',
                'data' => $phone
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Illuminate\Database\QueryException $e) {
            \Log::error('Database error creating buy phone: ' . $e->getMessage());
            \Log::error('SQL: ' . $e->getSql());
            \Log::error('Bindings: ' . json_encode($e->getBindings()));
            
            return response()->json([
                'success' => false,
                'message' => 'Database error: ' . $e->getMessage()
            ], 500);
        } catch (\Exception $e) {
            \Log::error('Error creating buy phone: ' . $e->getMessage());
            \Log::error('Stack trace: ' . $e->getTraceAsString());
            \Log::error('Request data: ' . json_encode($request->all()));
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to create phone: ' . $e->getMessage()
            ], 500);
        }
    }

    // PUT /api/buy-phones/{id}
    public function update(Request $request, $id)
    {
        $phone = BuyPhone::findOrFail($id);

        $validated = $request->validate([
            'seller_name'   => 'sometimes|required|string|max:255',
            'seller_phone'  => 'nullable|string|max:50',
            'brand_id'      => 'sometimes|required|exists:brands,id',
            'model'         => 'sometimes|required|string|max:255',
            'color'         => 'nullable|string|max:100',
            'storage'       => 'nullable|string|max:50',
            'imei'          => [
                'sometimes','required','string','size:15',
                Rule::unique('buy_phones','imei')->ignore($phone->id)
            ],
            'condition'     => 'sometimes|required',
            'buy_price'     => 'sometimes|required|numeric|min:0',
            'resell_price'  => 'nullable|numeric|min:0',
            'status'        => 'sometimes|required',
            'notes'         => 'nullable|string',
            'issues'        => 'nullable|string',
        ]);

        $phone->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Phone updated successfully',
            'data' => $phone
        ]);
    }
    // POST /api/buy-phones/{id}/sell
    public function sell(Request $request, $id)
{
    $phone = BuyPhone::findOrFail($id);

    if ($phone->status === 'sold') {
        return response()->json([
            'success' => false,
            'message' => 'Phone already sold'
        ], 400);
    }

    $phone->status = 'sold';
    $phone->sold_price = $request->sold_price;
    $phone->sold_at = now();
    $phone->sold_by = auth()->user()->name ?? 'System';
    $phone->save();

    return response()->json([
        'success' => true,
        'message' => 'Phone sold successfully',
        'data' => $phone
    ]);
}

    // POST /api/buy-phones/{id}/mark-returned
    public function markReturned($id)
    {
        BuyPhone::findOrFail($id)->markAsReturned();

        return response()->json([
            'success' => true,
            'message' => 'Phone marked as returned'
        ]);
    }

    // GET /api/buy-phones/stats
    public function stats(Request $request)
    {
        $period = $request->get('period', 'month');

        return response()->json([
            'success' => true,
            'data' => BuyPhone::getStatistics($period)
        ]);
    }

    // DELETE /api/buy-phones/{id}
    public function destroy($id)
    {
        BuyPhone::findOrFail($id)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Phone deleted successfully'
        ]);
    }
}
