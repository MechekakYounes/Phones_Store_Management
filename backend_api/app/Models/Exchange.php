<?php
// app/Models/Exchange.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;


class Exchange extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'sale_id',
        'buy_phone_id',
        'customer_id',
        'difference_amount',
        'reason',
        'status',
        'exchange_date',
        'processed_by',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'difference_amount' => 'decimal:2',
        'exchange_date' => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    
    const STATUS_PENDING = 'pending';
    const STATUS_COMPLETED = 'completed';
    const STATUS_CANCELLED = 'cancelled';



    /**
     * Get the sale associated with the exchange.
     */
    public function sale(): BelongsTo
    {
        return $this->belongsTo(Sale::class);
    }

    /**
     * Get the buy phone associated with the exchange.
     */
    public function buyPhone(): BelongsTo
    {
        return $this->belongsTo(BuyPhone::class);
    }

    /**
     * Get the customer associated with the exchange.
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    /**
     * Get the user who processed the exchange.
     */
    public function processor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'processed_by');
    }

    

    /**
     * Update buy_phone status to reserved.
     */
    public function updateBuyPhoneStatus(): void
    {
        $this->buyPhone->update([
            'status' => BuyPhone::STATUS_RECEIVED, // Mark as reserved for exchange
            'notes' => ($this->buyPhone->notes ?? '') . "\nReserved for exchange #{$this->exchange_number}",
        ]);
    }

    /**
     * Restore buy_phone status to available.
     */
    public function restoreBuyPhoneStatus(): void
    {
        $this->buyPhone->update([
            'status' => BuyPhone::STATUS_LISTED,
            'notes' => str_replace("Reserved for exchange #{$this->exchange_number}", '', $this->buyPhone->notes ?? ''),
        ]);
    }

    /**
     * Process the exchange (mark as completed).
     */
    public function processExchange(): void
    {
        DB::transaction(function () {
            // Mark buy_phone as sold
            $this->buyPhone->markAsSold($this->customer_id);

            // Create a new sale for the exchanged phone
            $newSale = Sale::create([
                'customer_id' => $this->customer_id,
                'total_amount' => $this->buyPhone->resell_price ?? $this->buyPhone->buy_price,
                'discount_amount' => 0,
                'tax_amount' => 0,
                'paid_amount' => abs(min(0, $this->difference_amount)), // If downgrade, shop pays back
                'payment_status' => $this->difference_amount >= 0 ? Sale::PAYMENT_PARTIAL : Sale::PAYMENT_PAID,
                'payment_method' => 'exchange',
                'notes' => "Exchange from sale #{$this->sale->sale_number}. {$this->reason}",
                'created_by' => $this->processed_by,
            ]);

            // Add buy_phone to the new sale
            $newSale->saleItems()->create([
                'buy_phone_id' => $this->buy_phone_id,
                'quantity' => 1,
                'unit_price' => $this->buyPhone->resell_price ?? $this->buyPhone->buy_price,
                'cost_price' => $this->buyPhone->buy_price,
            ]);

            // Update the original sale to mark as exchanged
            $this->sale->update([
                'notes' => ($this->sale->notes ?? '') . "\nExchanged for phone #{$this->buy_phone_id} via exchange #{$this->exchange_number}",
            ]);

            // Store reference to the new sale
            $this->updateQuietly(['new_sale_id' => $newSale->id]);
        });
    }

    /**
     * Reverse a completed exchange.
     */
    public function reverseExchange(): void
    {
        DB::transaction(function () {
            // Reverse buy_phone status
            $this->buyPhone->update([
                'status' => BuyPhone::STATUS_LISTED,
                'sold_to' => null,
                'sold_date' => null,
            ]);

            // Delete the new sale created during exchange
            if ($this->new_sale_id) {
                Sale::find($this->new_sale_id)->delete();
            }

            // Remove exchange reference from original sale
            $notes = str_replace(
                "\nExchanged for phone #{$this->buy_phone_id} via exchange #{$this->exchange_number}",
                '',
                $this->sale->notes ?? ''
            );
            $this->sale->updateQuietly(['notes' => $notes]);
        });
    }

    /**
     * Get the original phone from sale (for comparison).
     */
    public function getOriginalPhoneAttribute()
    {
        // Assuming sale has phone items
        return $this->sale->saleItems()
            ->whereNotNull('product_id')
            ->orWhereNotNull('buy_phone_id')
            ->first();
    }

    /**
     * Calculate value of original phone.
     */
    public function getOriginalPhoneValueAttribute(): ?float
    {
        if ($originalPhone = $this->original_phone) {
            return $originalPhone->unit_price;
        }
        return null;
    }

    /**
     * Calculate value of exchanged phone.
     */
    public function getExchangedPhoneValueAttribute(): float
    {
        return $this->buyPhone->resell_price ?? $this->buyPhone->buy_price;
    }

    /**
     * Check if customer needs to pay extra.
     */
    public function getCustomerPaysAttribute(): bool
    {
        return $this->difference_amount > 0;
    }

    /**
     * Check if shop needs to pay back.
     */
    public function getShopPaysAttribute(): bool
    {
        return $this->difference_amount < 0;
    }

    /**
     * Get formatted difference amount.
     */
    public function getFormattedDifferenceAttribute(): string
    {
        if ($this->difference_amount == 0) {
            return 'No Exchange';
        }
        
        $sign = $this->difference_amount > 0 ? '+' : '-';
        $amount = abs($this->difference_amount);
        
        return $sign . number_format($amount, 2);
    }

    /**
     * Get exchange description.
     */
    public function getDescriptionAttribute(): string
    {
        $original = $this->original_phone ? $this->original_phone->description : 'Unknown Phone';
        $exchanged = $this->buyPhone->description;
        
        return "Exchange from {$original} to {$exchanged}";
    }

    /**
     * Check if exchange is pending.
     */
    public function getIsPendingAttribute(): bool
    {
        return $this->status === self::STATUS_PENDING;
    }

    /**
     * Check if exchange is completed.
     */
    public function getIsCompletedAttribute(): bool
    {
        return $this->status === self::STATUS_COMPLETED;
    }

    /**
     * Check if exchange is cancelled.
     */
    public function getIsCancelledAttribute(): bool
    {
        return $this->status === self::STATUS_CANCELLED;
    }

    /**
     * Mark exchange as completed.
     */
    public function markAsCompleted(): bool
    {
        return $this->update(['status' => self::STATUS_COMPLETED]);
    }

    /**
     * Mark exchange as cancelled.
     */
    public function markAsCancelled(): bool
    {
        return $this->update(['status' => self::STATUS_CANCELLED]);
    }

    /**
     * Scope a query to only include pending exchanges.
     */
    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    /**
     * Scope a query to only include completed exchanges.
     */
    public function scopeCompleted($query)
    {
        return $query->where('status', self::STATUS_COMPLETED);
    }

    /**
     * Scope a query to only include cancelled exchanges.
     */
    public function scopeCancelled($query)
    {
        return $query->where('status', self::STATUS_CANCELLED);
    }

    /**
     * Scope a query by exchange type.
     */
    public function scopeByType($query, $type)
    {
        return $query->where('exchange_type', $type);
    }

    /**
     * Scope a query by customer.
     */
    public function scopeByCustomer($query, $customerId)
    {
        return $query->where('customer_id', $customerId);
    }

    /**
     * Scope a query to search exchanges.
     */
    public function scopeSearch($query, $searchTerm)
    {
        return $query->where('exchange_number', 'like', '%' . $searchTerm . '%')
                     ->orWhereHas('customer', function ($q) use ($searchTerm) {
                         $q->where('name', 'like', '%' . $searchTerm . '%')
                           ->orWhere('phone', 'like', '%' . $searchTerm . '%');
                     })
                     ->orWhereHas('buyPhone', function ($q) use ($searchTerm) {
                         $q->where('imei', 'like', '%' . $searchTerm . '%')
                           ->orWhere('model', 'like', '%' . $searchTerm . '%');
                     });
    }

    /**
     * Scope a query by date range.
     */
    public function scopeDateRange($query, $startDate, $endDate = null)
    {
        $endDate = $endDate ?: $startDate;
        
        return $query->whereBetween('exchange_date', [$startDate, $endDate]);
    }

    /**
     * Get exchange statistics.
     */
    public static function getStatistics($period = 'month')
    {
        $query = self::completed();
        
        if ($period === 'month') {
            $query->where('exchange_date', '>=', now()->subMonth());
        } elseif ($period === 'year') {
            $query->where('exchange_date', '>=', now()->subYear());
        }
        
        $totalExchanges = $query->count();
        $totalUpgrades = $query->clone()->byType(self::TYPE_UPGRADE)->count();
        $totalDowngrades = $query->clone()->byType(self::TYPE_DOWNGRADE)->count();
        $totalEqual = $query->clone()->byType(self::TYPE_EQUAL)->count();
        
        $totalCustomerPayments = $query->clone()->where('difference_amount', '>', 0)->sum('difference_amount');
        $totalShopPayments = abs($query->clone()->where('difference_amount', '<', 0)->sum('difference_amount'));
        
        return [
            'total_exchanges' => $totalExchanges,
            'by_type' => [
                'upgrades' => $totalUpgrades,
                'downgrades' => $totalDowngrades,
                'equal' => $totalEqual,
            ],
            'financial' => [
                'total_customer_payments' => $totalCustomerPayments,
                'total_shop_payments' => $totalShopPayments,
                'net_balance' => $totalCustomerPayments - $totalShopPayments,
            ],
            'averages' => [
                'average_difference' => $totalExchanges > 0 ? ($totalCustomerPayments + $totalShopPayments) / $totalExchanges : 0,
            ],
        ];
    }

    /**
     * Generate exchange receipt data.
     */
    public function generateReceiptData(): array
    {
        $originalPhone = $this->original_phone;
        
        return [
            'exchange' => [
                'id' => $this->id,
                'exchange_number' => $this->exchange_number,
                'exchange_date' => $this->exchange_date->format('d M Y'),
                'exchange_type' => $this->exchange_type,
                'status' => $this->status,
                'reason' => $this->reason,
                'difference_amount' => $this->difference_amount,
                'formatted_difference' => $this->formatted_difference,
            ],
            'customer' => $this->customer ? [
                'id' => $this->customer->id,
                'name' => $this->customer->name,
                'phone' => $this->customer->phone,
                'address' => $this->customer->address,
            ] : null,
            'original_sale' => [
                'sale_number' => $this->sale->sale_number,
                'date' => $this->sale->created_at->format('d M Y'),
                'phone' => $originalPhone ? $originalPhone->description : 'Unknown',
                'value' => $this->original_phone_value,
            ],
            'exchanged_phone' => [
                'id' => $this->buy_phone_id,
                'description' => $this->buyPhone->description,
                'imei' => $this->buyPhone->imei,
                'condition' => $this->buyPhone->condition,
                'value' => $this->exchanged_phone_value,
                'buy_price' => $this->buyPhone->buy_price,
                'resell_price' => $this->buyPhone->resell_price,
            ],
            'financial' => [
                'customer_pays' => $this->customer_pays,
                'shop_pays' => $this->shop_pays,
                'amount' => abs($this->difference_amount),
                'description' => $this->difference_amount > 0 
                    ? "Customer pays {$this->formatted_difference}" 
                    : ($this->difference_amount < 0 
                        ? "Shop pays {$this->formatted_difference}" 
                        : "No money exchange"),
            ],
            'processor' => $this->processor ? [
                'id' => $this->processor->id,
                'name' => $this->processor->name,
            ] : null,
            'dates' => [
                'created_at' => $this->created_at->format('d M Y H:i'),
                'updated_at' => $this->updated_at->format('d M Y H:i'),
            ],
        ];
    }
}