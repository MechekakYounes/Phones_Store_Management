<?php
// app/Models/Product.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Product extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'brand_id',
        'category_id',
        'model',
        'storage',
        'color',
        'imei',
        'purchase_price',
        'selling_price',
        'quantity',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'purchase_price' => 'decimal:2',
        'selling_price' => 'decimal:2',
        'quantity' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Get the brand that owns the product.
     */
    public function brand(): BelongsTo
    {
        return $this->belongsTo(Brand::class);
    }

    /**
     * Get the category that owns the product.
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    /**
     * Get the sale items for the product.
     */
    public function saleItems(): HasMany
    {
        return $this->hasMany(SaleItem::class);
    }

    /**
     * Get the purchase items for the product.
     */
    public function purchaseItems(): HasMany
    {
        return $this->hasMany(PurchaseItem::class);
    }

    /**
     * Scope a query to only include phones (IMEI not null).
     */
    public function scopePhones($query)
    {
        return $query->whereNotNull('imei');
    }

    /**
     * Scope a query to only include accessories (IMEI is null).
     */
    public function scopeAccessories($query)
    {
        return $query->whereNull('imei');
    }

    /**
     * Scope a query to only include in-stock products.
     */
    public function scopeInStock($query)
    {
        return $query->where('quantity', '>', 0);
    }

    /**
     * Scope a query to only include out-of-stock products.
     */
    public function scopeOutOfStock($query)
    {
        return $query->where('quantity', '<=', 0);
    }

    /**
     * Calculate profit margin for this product.
     */
    public function getProfitMarginAttribute(): float
    {
        if ($this->purchase_price == 0) {
            return 0;
        }
        
        return (($this->selling_price - $this->purchase_price) / $this->purchase_price) * 100;
    }

    /**
     * Calculate total value of current stock.
     */
    public function getStockValueAttribute(): float
    {
        return $this->quantity * $this->purchase_price;
    }

    /**
     * Check if product is a phone (has IMEI).
     */
    public function getIsPhoneAttribute(): bool
    {
        return !is_null($this->imei);
    }

    /**
     * Check if product is low in stock (less than 3).
     */
    public function getIsLowStockAttribute(): bool
    {
        return $this->quantity < 3;
    }

    /**
     * Get full product name.
     */
    public function getFullNameAttribute(): string
    {
        $name = $this->brand->name . ' ' . $this->model;
        
        if ($this->storage) {
            $name .= ' ' . $this->storage;
        }
        
        if ($this->color) {
            $name .= ' (' . $this->color . ')';
        }
        
        return $name;
    }
}