<?php
// app/Models/Sale.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Sale extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'customer_id',
        'buy_phone_id',
        'total_amount',
        'discount_amount',
        'grand_total',
        'payment_status',
        'payment_method',
        'notes',
        'created_by',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'total_amount' => 'decimal:2',
        'discount_amount' => 'decimal:2',
        'grand_total' => 'decimal:2',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    /**
     * Payment status constants
     */
    const PAYMENT_PENDING = 'pending';
    const PAYMENT_PARTIAL = 'partial';
    const PAYMENT_PAID = 'paid';
    const PAYMENT_CANCELLED = 'cancelled';


    
    /**
     * Get the customer associated with the sale.
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    /**
     * Get the user who created the sale.
     */
    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * Get the sale items for the sale.
     */
    public function saleItems(): HasMany
    {
        return $this->hasMany(SaleItem::class);
    }

    public function buy_phones(): BelongsTo
    {
        return $this->belongsTo(BuyPhone::class,'buy_phone_id');
    }

    /**
     * Get the exchange record if this sale has an exchange.
     */
    public function exchange(): HasMany
    {
        return $this->hasMany(Exchange::class);
    }
    public function items()
    {
        return $this->hasMany(SaleItem::class); // or SaleDetail depending on your table name
    }

    /**
     * Recalculate totals from sale items.
     */
    public function recalculateTotals(): void
    {
        $total = $this->saleItems()->sum('total_price');
        $grandTotal = $total - $this->discount_amount + $this->tax_amount;
        
        $this->updateQuietly([
            'total_amount' => $total,
            'grand_total' => $grandTotal,
        ]);
    }

    /**
     * Update payment status based on paid amount.
     */
    public function updatePaymentStatus(): void
    {
        if ($this->paid_amount >= $this->grand_total) {
            $status = self::PAYMENT_PAID;
        } elseif ($this->paid_amount > 0) {
            $status = self::PAYMENT_PARTIAL;
        } else {
            $status = self::PAYMENT_PENDING;
        }
        
        $this->updateQuietly(['payment_status' => $status]);
    }

    /**
     * Update inventory quantities and buy_phone status.
     */
    public function updateInventory(): void
    {
        foreach ($this->saleItems as $item) {
            // Update product quantity
            if ($item->product) {
                $item->product->decrement('quantity', $item->quantity);
            }

            // Update buy_phone status if applicable
            if ($item->buy_phone) {
                $item->buy_phone->markAsSold($this->customer_id);
            }
        }
    }

    /**
     * Restore inventory quantities and buy_phone status.
     */
    public function restoreInventory(): void
    {
        foreach ($this->saleItems as $item) {
            // Restore product quantity
            if ($item->product) {
                $item->product->increment('quantity', $item->quantity);
            }

            // Restore buy_phone status if applicable
            if ($item->buy_phone) {
                $item->buy_phone->update([
                    'status' => BuyPhone::STATUS_LISTED,
                    'sold_to' => null,
                    'sold_date' => null,
                ]);
            }
        }
    }

    /**
     * Calculate change amount.
     */
    public function calculateChange(): float
    {
        return max(0, $this->paid_amount - $this->grand_total);
    }

    /**
     * Calculate remaining balance.
     */
    public function getBalanceAttribute(): float
    {
        return max(0, $this->grand_total - $this->paid_amount);
    }

    /**
     * Check if sale is fully paid.
     */
    public function getIsPaidAttribute(): bool
    {
        return $this->payment_status === self::PAYMENT_PAID;
    }

    /**
     * Check if sale is pending payment.
     */
    public function getIsPendingAttribute(): bool
    {
        return $this->payment_status === self::PAYMENT_PENDING;
    }

    /**
     * Check if sale has partial payment.
     */
    public function getIsPartialAttribute(): bool
    {
        return $this->payment_status === self::PAYMENT_PARTIAL;
    }

    /**
     * Check if sale is cancelled.
     */
    public function getIsCancelledAttribute(): bool
    {
        return $this->payment_status === self::PAYMENT_CANCELLED;
    }

    /**
     * Calculate total profit for this sale.
     */
    public function getProfitAttribute(): float
    {
        $profit = 0;
        
        foreach ($this->saleItems as $item) {
            if ($item->cost_price) {
                $profit += ($item->unit_price - $item->cost_price) * $item->quantity;
            }
        }
        
        return $profit;
    }

    /**
     * Calculate profit margin.
     */
    public function getProfitMarginAttribute(): float
    {
        if ($this->total_amount == 0) {
            return 0;
        }
        
        return ($this->profit / $this->total_amount) * 100;
    }

    /**
     * Get total items count.
     */
    public function getTotalItemsAttribute(): int
    {
        return $this->saleItems()->sum('quantity');
    }

    /**
     * Get total unique products count.
     */
    public function getUniqueProductsCountAttribute(): int
    {
        return $this->saleItems()->distinct('product_id')->count('product_id');
    }

    /**
     * Add payment to sale.
     */
    public function addPayment(float $amount, string $method = null): bool
    {
        $data = ['paid_amount' => $this->paid_amount + $amount];
        
        if ($method) {
            $data['payment_method'] = $method;
        }
        
        return $this->update($data);
    }

    /**
     * Mark sale as cancelled.
     */
    public function markAsCancelled(): bool
    {
        return $this->update(['payment_status' => self::PAYMENT_CANCELLED]);
    }

    /**
     * Scope a query to only include paid sales.
     */
    public function scopePaid($query)
    {
        return $query->where('payment_status', self::PAYMENT_PAID);
    }

    /**
     * Scope a query to only include pending sales.
     */
    public function scopePending($query)
    {
        return $query->where('payment_status', self::PAYMENT_PENDING);
    }

    /**
     * Scope a query to search sales by sale number or customer.
     */
    public function scopeSearch($query, $searchTerm)
    {
        return $query->where('notes', 'like', '%' . $searchTerm . '%')
                     ->orWhereHas('customer', function ($q) use ($searchTerm) {
                         $q->where('name', 'like', '%' . $searchTerm . '%')
                           ->orWhere('phone', 'like', '%' . $searchTerm . '%');
                     });
    }

    /**
     * Scope a query by date range.
     */
    public function scopeDateRange($query, $startDate, $endDate = null)
    {
        $endDate = $endDate ?: $startDate;
        
        return $query->whereBetween('created_at', [$startDate, $endDate]);
    }

    /**
     * Scope a query by customer.
     */
    public function scopeByCustomer($query, $customerId)
    {
        return $query->where('customer_id', $customerId);
    }

    /**
     * Get sales summary statistics.
     */
    public static function getSummaryStatistics($period = 'day')
    {
        $query = self::paid();
        
        if ($period === 'day') {
            $query->whereDate('created_at', today());
        } elseif ($period === 'week') {
            $query->where('created_at', '>=', now()->subWeek());
        } elseif ($period === 'month') {
            $query->where('created_at', '>=', now()->subMonth());
        }
        
        $totalSales = $query->count();
        $totalRevenue = $query->sum('grand_total');
        
        return [
            'total_sales' => $totalSales,
            'total_revenue' => $totalRevenue,
            'average_sale' => $totalSales > 0 ? $totalRevenue / $totalSales : 0,
            'total_items_sold' => $query->withSum('saleItems as total_items', 'quantity')->get()->sum('total_items'),
        ];
    }

    /**
     * Generate receipt data.
     */
    
}
