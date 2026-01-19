<?php
// app/Models/SaleItem.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SaleItem extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'sale_id',
        'product_id',
        'buy_phone_id',
        'quantity',
        'unit_price',
        'cost_price',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'quantity' => 'integer',
        'unit_price' => 'decimal:2',
        'total_price' => 'decimal:2',
        'cost_price' => 'decimal:2',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Boot the model.
     */
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($item) {
            // Set unit price from product if not provided
            if (!$item->unit_price && $item->product) {
                $item->unit_price = $item->product->selling_price;
            }

            // Set cost price for profit calculation
            if (!$item->cost_price) {
                if ($item->buy_phone) {
                    $item->cost_price = $item->buy_phone->buy_price;
                } elseif ($item->product) {
                    $item->cost_price = $item->product->purchase_price;
                }
            }
        });
    }

    /**
     * Get the sale that owns the sale item.
     */
    public function sale(): BelongsTo
    {
        return $this->belongsTo(Sale::class);
    }

    /**
     * Get the product that owns the sale item.
     */
    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    /**
     * Get the buy phone that owns the sale item.
     */
    public function buyPhone(): BelongsTo
    {
        return $this->belongsTo(BuyPhone::class);
    }

    /**
     * Calculate profit for this item.
     */
    public function getProfitAttribute(): ?float
    {
        if (!$this->cost_price) {
            return null;
        }
        
        return ($this->unit_price - $this->cost_price) * $this->quantity;
    }

    /**
     * Calculate profit margin for this item.
     */
    public function getProfitMarginAttribute(): ?float
    {
        if (!$this->cost_price || $this->cost_price == 0) {
            return null;
        }
        
        return (($this->unit_price - $this->cost_price) / $this->cost_price) * 100;
    }

    /**
     * Get item description.
     */
    public function getDescriptionAttribute(): string
    {
        if ($this->buy_phone) {
            return $this->buy_phone->description . ' (Used)';
        }
        
        if ($this->product) {
            $product = $this->product;
            $description = $product->brand->name . ' ' . $product->model;
            
            if ($product->storage) {
                $description .= ' ' . $product->storage;
            }
            
            if ($product->color) {
                $description .= ' (' . $product->color . ')';
            }
            
            return $description;
        }
        
        return 'Unknown Item';
    }

    /**
     * Get formatted unit price.
     */
    public function getFormattedUnitPriceAttribute(): string
    {
        return number_format($this->unit_price, 2);
    }

    /**
     * Get formatted total price.
     */
    public function getFormattedTotalPriceAttribute(): string
    {
        return number_format($this->total_price, 2);
    }

    /**
     * Get formatted cost price.
     */
    public function getFormattedCostPriceAttribute(): ?string
    {
        return $this->cost_price ? number_format($this->cost_price, 2) : null;
    }
}