<?php
// app/Models/BuyPhone.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class BuyPhone extends Model
{
    use HasFactory, SoftDeletes;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'seller_name',
        'seller_phone',
        'brand_id',
        'model',
        'color',
        'storage',
        'imei',
        'condition',
        'buy_price',
        'resell_price',
        'status',
        'notes',
        'issues',
        'received_date',
        'sold_date',
        'received_by',
        'sold_to',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'buy_price' => 'decimal:2',
        'resell_price' => 'decimal:2',
        'received_date' => 'date',
        'sold_date' => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    /**
     * Condition constants
     */
    const CONDITION_EXCELLENT = 'excellent';
    const CONDITION_VERY_GOOD = 'very_good';
    const CONDITION_GOOD = 'good';
    const CONDITION_FAIR = 'fair';
    const CONDITION_DAMAGED = 'damaged';
    const CONDITION_BROKEN = 'broken';

    /**
     * Status constants
     */
    const STATUS_RECEIVED = 'received';
    const STATUS_TESTED = 'tested';
    const STATUS_LISTED = 'listed';
    const STATUS_SOLD = 'sold';
    const STATUS_RETURNED = 'returned';
    const STATUS_CANCELLED = 'cancelled';

    /**
     * Boot the model.
     */
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($buyPhone) {
            // Set received date if not provided
            if (!$buyPhone->received_date) {
                $buyPhone->received_date = now()->toDateString();
            }

            // Set received_by if not provided and user is authenticated
            if (!$buyPhone->received_by && auth()->check()) {
                $buyPhone->received_by = auth()->id();
            }

            // Auto-calculate resell price based on condition if not provided
            if (!$buyPhone->resell_price) {
                $buyPhone->resell_price = $buyPhone->calculateSuggestedResellPrice();
            }
        });

        static::updating(function ($buyPhone) {
            // Update sold_date when status changes to sold
            if ($buyPhone->isDirty('status') && $buyPhone->status === self::STATUS_SOLD) {
                $buyPhone->sold_date = now()->toDateString();
            }

            // Clear sold_date if status changes from sold
            if ($buyPhone->isDirty('status') && $buyPhone->getOriginal('status') === self::STATUS_SOLD) {
                $buyPhone->sold_date = null;
            }
        });
    }

    /**
     * Get the brand that owns the buy phone.
     */
    public function brand(): BelongsTo
    {
        return $this->belongsTo(Brand::class);
    }

    /**
     * Get the user who received the phone.
     */
    public function receiver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'received_by');
    }

    /**
     * Get the customer who bought the phone.
     */
    public function buyer(): BelongsTo
    {
        return $this->belongsTo(Customer::class, 'sold_to');
    }

    /**
     * Get the exchange record if this phone was used in an exchange.
     */
    public function exchange(): HasOne
    {
        return $this->hasOne(Exchange::class, 'buy_phone_id');
    }

    /**
     * Calculate suggested resell price based on buy price and condition.
     */
    public function calculateSuggestedResellPrice(): float
    {
        $multiplier = match($this->condition) {
            self::CONDITION_EXCELLENT => 1.5,
            self::CONDITION_VERY_GOOD => 1.4,
            self::CONDITION_GOOD => 1.3,
            self::CONDITION_FAIR => 1.2,
            self::CONDITION_DAMAGED => 1.1,
            self::CONDITION_BROKEN => 1.0,
            default => 1.3,
        };

        return round($this->buy_price * $multiplier, 2);
    }

    /**
     * Calculate potential profit.
     */
    public function getPotentialProfitAttribute(): ?float
    {
        if (!$this->resell_price) {
            return null;
        }
        
        return $this->resell_price - $this->buy_price;
    }

    /**
     * Calculate profit margin.
     */
    public function getProfitMarginAttribute(): ?float
    {
        if (!$this->resell_price || $this->buy_price == 0) {
            return null;
        }
        
        return (($this->resell_price - $this->buy_price) / $this->buy_price) * 100;
    }

    /**
     * Check if phone is sold.
     */
    public function getIsSoldAttribute(): bool
    {
        return $this->status === self::STATUS_SOLD;
    }

    /**
     * Check if phone is available for sale.
     */
    public function getIsAvailableAttribute(): bool
    {
        return in_array($this->status, [self::STATUS_TESTED, self::STATUS_LISTED]);
    }

    /**
     * Check if phone needs testing.
     */
    public function getNeedsTestingAttribute(): bool
    {
        return $this->status === self::STATUS_RECEIVED;
    }

    /**
     * Check if phone is broken.
     */
    public function getIsBrokenAttribute(): bool
    {
        return $this->condition === self::CONDITION_BROKEN;
    }

    /**
     * Check if phone is damaged.
     */
    public function getIsDamagedAttribute(): bool
    {
        return $this->condition === self::CONDITION_DAMAGED;
    }

    /**
     * Mark phone as tested.
     */
    public function markAsTested(array $issues = null): bool
    {
        $data = ['status' => self::STATUS_TESTED];
        
        if ($issues !== null) {
            $data['issues'] = implode(', ', $issues);
        }
        
        return $this->update($data);
    }

    /**
     * Mark phone as listed for sale.
     */
    public function markAsListed(): bool
    {
        return $this->update(['status' => self::STATUS_LISTED]);
    }

    /**
     * Mark phone as sold.
     */
    public function markAsSold($customerId = null): bool
    {
        $data = [
            'status' => self::STATUS_SOLD,
            'sold_date' => now()->toDateString(),
        ];
        
        if ($customerId) {
            $data['sold_to'] = $customerId;
        }
        
        return $this->update($data);
    }

    /**
     * Mark phone as returned.
     */
    public function markAsReturned(): bool
    {
        return $this->update(['status' => self::STATUS_RETURNED]);
    }

    /**
     * Get full phone description.
     */
    public function getDescriptionAttribute(): string
    {
        $description = $this->brand->name . ' ' . $this->model;
        
        if ($this->storage) {
            $description .= ' ' . $this->storage;
        }
        
        if ($this->color) {
            $description .= ' (' . $this->color . ')';
        }
        
        return $description;
    }

    /**
     * Get days in inventory.
     */
    public function getDaysInInventoryAttribute(): int
    {
        if ($this->sold_date) {
            return $this->received_date->diffInDays($this->sold_date);
        }
        
        return $this->received_date->diffInDays(now());
    }

    /**
     * Scope a query to only include sold phones.
     */
    public function scopeSold($query)
    {
        return $query->where('status', self::STATUS_SOLD);
    }

    /**
     * Scope a query to only include available phones.
     */
    public function scopeAvailable($query)
    {
        return $query->whereIn('status', [self::STATUS_TESTED, self::STATUS_LISTED]);
    }

    /**
     * Scope a query to only include phones needing testing.
     */
    public function scopeNeedsTesting($query)
    {
        return $query->where('status', self::STATUS_RECEIVED);
    }

    /**
     * Scope a query to only include phones in specific condition.
     */
    public function scopeByCondition($query, $condition)
    {
        return $query->where('condition', $condition);
    }

    /**
     * Scope a query to search phones by various fields.
     */
    public function scopeSearch($query, $searchTerm)
    {
        return $query->where('imei', 'like', '%' . $searchTerm . '%')
                     ->orWhere('model', 'like', '%' . $searchTerm . '%')
                     ->orWhere('seller_name', 'like', '%' . $searchTerm . '%')
                     ->orWhere('seller_phone', 'like', '%' . $searchTerm . '%')
                     ->orWhereHas('brand', function ($q) use ($searchTerm) {
                         $q->where('name', 'like', '%' . $searchTerm . '%');
                     });
    }

    /**
     * Scope a query by date range.
     */
    public function scopeDateRange($query, $startDate, $endDate = null)
    {
        $endDate = $endDate ?: $startDate;
        
        return $query->whereBetween('received_date', [$startDate, $endDate]);
    }

    /**
     * Scope a query by brand.
     */
    public function scopeByBrand($query, $brandId)
    {
        return $query->where('brand_id', $brandId);
    }

    /**
     * Get statistics for buy phones.
     */
    public static function getStatistics($period = 'month')
    {
        $query = self::query();
        
        if ($period === 'month') {
            $query->where('received_date', '>=', now()->subMonth());
        } elseif ($period === 'year') {
            $query->where('received_date', '>=', now()->subYear());
        }
        
        $total = $query->count();
        $sold = $query->clone()->sold()->count();
        $available = $query->clone()->available()->count();
        $totalInvestment = $query->clone()->sum('buy_price');
        $totalRevenue = $query->clone()->sold()->sum('resell_price');
        
        return [
            'total_phones' => $total,
            'sold_phones' => $sold,
            'available_phones' => $available,
            'needs_testing' => $query->clone()->needsTesting()->count(),
            'total_investment' => $totalInvestment,
            'total_revenue' => $totalRevenue,
            'total_profit' => $totalRevenue - $totalInvestment,
            'sell_through_rate' => $total > 0 ? ($sold / $total) * 100 : 0,
        ];
    }

    /**
     * Check if IMEI already exists in either products or buy_phones.
     */
    public static function imeiExists($imei): bool
    {
        return self::where('imei', $imei)->exists() || 
               Product::where('imei', $imei)->exists();
    }
}