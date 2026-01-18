<?php
// app/Models/Supplier.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes; // Optional: for soft delete functionality

class Supplier extends Model
{
    use HasFactory;
    // use SoftDeletes; // Uncomment if you want soft deletes

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'phone',
        'address',
        'notes',
        'email',
        'contact_person',
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
     * Get the purchases from this supplier.
     */
    public function purchases(): HasMany
    {
        return $this->hasMany(Purchase::class);
    }

    /**
     * Calculate total purchase amount from this supplier.
     */
    public function getTotalPurchasesAttribute(): float
    {
        return $this->purchases()->sum('total_amount');
    }

    /**
     * Get total number of purchases from this supplier.
     */
    public function getPurchaseCountAttribute(): int
    {
        return $this->purchases()->count();
    }

    /**
     * Get last purchase date from this supplier.
     */
    public function getLastPurchaseDateAttribute()
    {
        $lastPurchase = $this->purchases()->latest()->first();
        return $lastPurchase ? $lastPurchase->created_at : null;
    }

    /**
     * Calculate average purchase amount.
     */
    public function getAveragePurchaseAttribute(): ?float
    {
        $count = $this->purchase_count;
        return $count > 0 ? $this->total_purchases / $count : null;
    }

    /**
     * Check if supplier is active (has purchase in last 90 days).
     */
    public function getIsActiveAttribute(): bool
    {
        $ninetyDaysAgo = now()->subDays(90);
        return $this->purchases()
            ->where('created_at', '>=', $ninetyDaysAgo)
            ->exists();
    }

    /**
     * Scope a query to only include active suppliers.
     */
    public function scopeActive($query)
    {
        $ninetyDaysAgo = now()->subDays(90);
        return $query->whereHas('purchases', function ($q) use ($ninetyDaysAgo) {
            $q->where('created_at', '>=', $ninetyDaysAgo);
        });
    }

    /**
     * Scope a query to only include inactive suppliers.
     */
    public function scopeInactive($query)
    {
        $ninetyDaysAgo = now()->subDays(90);
        return $query->whereDoesntHave('purchases', function ($q) use ($ninetyDaysAgo) {
            $q->where('created_at', '>=', $ninetyDaysAgo);
        });
    }

    /**
     * Scope a query to search suppliers by name, phone, or contact person.
     */
    public function scopeSearch($query, $searchTerm)
    {
        return $query->where('name', 'like', '%' . $searchTerm . '%')
                     ->orWhere('phone', 'like', '%' . $searchTerm . '%')
                     ->orWhere('contact_person', 'like', '%' . $searchTerm . '%')
                     ->orWhere('email', 'like', '%' . $searchTerm . '%');
    }

    /**
     * Scope a query to only include suppliers with phone number.
     */
    public function scopeHasPhone($query)
    {
        return $query->whereNotNull('phone');
    }

    /**
     * Get supplier's purchases with pagination.
     */
    public function purchasesPaginated($perPage = 10)
    {
        return $this->purchases()->with(['purchaseItems.product'])->latest()->paginate($perPage);
    }

    /**
     * Get recent purchases (last 10).
     */
    public function recentPurchases($limit = 10)
    {
        return $this->purchases()->with(['purchaseItems.product'])
            ->latest()
            ->limit($limit)
            ->get();
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

    /**
     * Get supplier's contact info as array.
     */
    public function getContactInfoAttribute(): array
    {
        return [
            'name' => $this->contact_person ?: $this->name,
            'phone' => $this->phone,
            'email' => $this->email,
            'address' => $this->address,
        ];
    }
}