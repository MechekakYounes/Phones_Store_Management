<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Customer extends Model
{
    protected $fillable = [
        'name',
        'phone',
        'address',
    ];
    
    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        // 'deleted_at' => 'datetime', // Uncomment if using soft deletes
    ];

    /**
     * Get the sales for the customer.
     */
    public function sales(): HasMany
    {
        return $this->hasMany(Sale::class);
    }

    /**
     * Get the repairs for the customer.
     */
    public function repairs(): HasMany
    {
        return $this->hasMany(Repair::class);
    }

    /**
     * Get the exchanges for the customer.
     */
    public function exchanges(): HasMany
    {
        return $this->hasMany(Exchange::class);
    }

    /**
     * Get total spent by customer.
     */
    public function getTotalSpentAttribute(): float
    {
        return $this->sales()->sum('total_amount');
    }

    /**
     * Get total number of purchases.
     */
    public function getPurchaseCountAttribute(): int
    {
        return $this->sales()->count();
    }

    /**
     * Get customer's last purchase date.
     */
    public function getLastPurchaseDateAttribute()
    {
        $lastSale = $this->sales()->latest()->first();
        return $lastSale ? $lastSale->created_at : null;
    }

    /**
     * Scope a query to only include customers who have made purchases.
     */
    public function scopeHasPurchases($query)
    {
        return $query->has('sales');
    }

    /**
     * Scope a query to only include customers with phone number.
     */
    public function scopeHasPhone($query)
    {
        return $query->whereNotNull('phone');
    }

    /**
     * Scope a query to search customers by name or phone.
     */
    public function scopeSearch($query, $searchTerm)
    {
        return $query->where('name', 'like', '%' . $searchTerm . '%')
                     ->orWhere('phone', 'like', '%' . $searchTerm . '%');
    }

    /**
     * Get customer's sales with pagination.
     */
    public function salesPaginated($perPage = 10)
    {
        return $this->sales()->with(['saleItems.product'])->latest()->paginate($perPage);
    }

    /**
     * Check if customer is active (made purchase in last 30 days).
     */
    public function getIsActiveAttribute(): bool
    {
        $thirtyDaysAgo = now()->subDays(30);
        return $this->sales()
            ->where('created_at', '>=', $thirtyDaysAgo)
            ->exists();
    }

    /**
     * Validate phone number format (basic validation).
     */
    public static function validatePhone($phone): bool
    {
        // Basic phone validation - adjust based on your country
        return preg_match('/^[0-9+\-\s()]{10,15}$/', $phone);
    }

    /**
     * Format phone number for display.
     */
    public function getFormattedPhoneAttribute(): ?string
    {
        if (!$this->phone) {
            return null;
        }

        // Remove all non-numeric characters
        $phone = preg_replace('/[^0-9]/', '', $this->phone);
        
        // Simple formatting - adjust based on your country
        if (strlen($phone) == 10) {
            return substr($phone, 0, 3) . '-' . substr($phone, 3, 3) . '-' . substr($phone, 6);
        }
        
        return $this->phone;
    }
}
