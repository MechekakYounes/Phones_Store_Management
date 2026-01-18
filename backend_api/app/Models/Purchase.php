<?php
// app/Models/Purchase.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Purchase extends Model
{
    use HasFactory, SoftDeletes;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'supplier_id',
        'total_amount',
        'notes',
        'invoice_number',
        'status',
        'purchase_date',
        'created_by',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'total_amount' => 'decimal:2',
        'purchase_date' => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    /**
     * Status constants
     */
    const STATUS_PENDING = 'pending';
    const STATUS_COMPLETED = 'completed';
    const STATUS_CANCELLED = 'cancelled';

    /**
     * Boot the model.
     */
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($purchase) {
            // Generate invoice number if not provided
            if (!$purchase->invoice_number) {
                $purchase->invoice_number = 'PUR-' . date('Ymd') . '-' . str_pad(Purchase::count() + 1, 4, '0', STR_PAD_LEFT);
            }

            // Set purchase date to today if not provided
            if (!$purchase->purchase_date) {
                $purchase->purchase_date = now()->toDateString();
            }

            // Set created_by if not provided and user is authenticated
            if (!$purchase->created_by && auth()->check()) {
                $purchase->created_by = auth()->id();
            }
        });

        static::saved(function ($purchase) {
            // Recalculate total amount when purchase items change
            if ($purchase->wasChanged() || $purchase->wasRecentlyCreated) {
                $purchase->recalculateTotal();
            }
        });
    }

    /**
     * Get the supplier associated with the purchase.
     */
    public function supplier(): BelongsTo
    {
        return $this->belongsTo(Supplier::class);
    }

    /**
     * Get the user who created the purchase.
     */
    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * Get the purchase items for the purchase.
     */
    public function purchaseItems(): HasMany
    {
        return $this->hasMany(PurchaseItem::class);
    }

    /**
     * Get the products purchased.
     */
    public function products()
    {
        return $this->hasManyThrough(Product::class, PurchaseItem::class, 'purchase_id', 'id', 'id', 'product_id');
    }

    /**
     * Recalculate total amount from purchase items.
     */
    public function recalculateTotal(): void
    {
        $total = $this->purchaseItems()->sum('total_price');
        $this->updateQuietly(['total_amount' => $total]);
    }

    /**
     * Check if purchase is pending.
     */
    public function getIsPendingAttribute(): bool
    {
        return $this->status === self::STATUS_PENDING;
    }

    /**
     * Check if purchase is completed.
     */
    public function getIsCompletedAttribute(): bool
    {
        return $this->status === self::STATUS_COMPLETED;
    }

    /**
     * Check if purchase is cancelled.
     */
    public function getIsCancelledAttribute(): bool
    {
        return $this->status === self::STATUS_CANCELLED;
    }

    /**
     * Mark purchase as completed.
     */
    public function markAsCompleted(): bool
    {
        return $this->update(['status' => self::STATUS_COMPLETED]);
    }

    /**
     * Mark purchase as cancelled.
     */
    public function markAsCancelled(): bool
    {
        return $this->update(['status' => self::STATUS_CANCELLED]);
    }

    /**
     * Get purchase date formatted.
     */
    public function getFormattedDateAttribute(): string
    {
        return $this->purchase_date ? $this->purchase_date->format('d M Y') : $this->created_at->format('d M Y');
    }

    /**
     * Get total items count.
     */
    public function getTotalItemsAttribute(): int
    {
        return $this->purchaseItems()->sum('quantity');
    }

    /**
     * Get total unique products count.
     */
    public function getUniqueProductsCountAttribute(): int
    {
        return $this->purchaseItems()->distinct('product_id')->count('product_id');
    }

    /**
     * Scope a query to only include completed purchases.
     */
    public function scopeCompleted($query)
    {
        return $query->where('status', self::STATUS_COMPLETED);
    }

    /**
     * Scope a query to only include pending purchases.
     */
    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    /**
     * Scope a query to only include cancelled purchases.
     */
    public function scopeCancelled($query)
    {
        return $query->where('status', self::STATUS_CANCELLED);
    }

    /**
     * Scope a query to search purchases by invoice number.
     */
    public function scopeSearch($query, $searchTerm)
    {
        return $query->where('invoice_number', 'like', '%' . $searchTerm . '%')
                     ->orWhereHas('supplier', function ($q) use ($searchTerm) {
                         $q->where('name', 'like', '%' . $searchTerm . '%');
                     });
    }

    /**
     * Scope a query by date range.
     */
    public function scopeDateRange($query, $startDate, $endDate = null)
    {
        $endDate = $endDate ?: $startDate;
        
        return $query->whereBetween('purchase_date', [$startDate, $endDate])
                     ->orWhereBetween('created_at', [$startDate, $endDate]);
    }

    /**
     * Scope a query by supplier.
     */
    public function scopeBySupplier($query, $supplierId)
    {
        return $query->where('supplier_id', $supplierId);
    }

    /**
     * Get purchase summary statistics.
     */
    public static function getSummaryStatistics($period = 'month')
    {
        $query = self::completed();
        
        if ($period === 'month') {
            $query->where('purchase_date', '>=', now()->subMonth());
        } elseif ($period === 'year') {
            $query->where('purchase_date', '>=', now()->subYear());
        }
        
        return [
            'total_purchases' => $query->count(),
            'total_amount' => $query->sum('total_amount'),
            'average_purchase' => $query->count() > 0 ? $query->sum('total_amount') / $query->count() : 0,
        ];
    }
}