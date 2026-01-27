<?php

namespace App\Observers;

use App\Models\BuyPhone;
use App\Models\Product;

class BuyPhoneObserver
{
    /**
     * Handle the BuyPhone "created" event.
     */
    public function created(BuyPhone $buyPhone): void
    {
        // Automatically insert into products table
        Product::firstOrCreate(
            ['imei' => $buyPhone->imei], // unique identifier
            [
                'brand_id'      => $buyPhone->brand_id,
                'model'         => $buyPhone->model,
                'storage'       => $buyPhone->storage,
                'color'         => $buyPhone->color,
                'buy_price'     => $buyPhone->buy_price,
                'selling_price' => $buyPhone->resell_price, // or 'selling_price' column in buy_phones
            ]
        );
    }

    /**
     * Handle the BuyPhone "updated" event.
     */
    public function updated(BuyPhone $buyPhone): void
    {
        //
    }

    /**
     * Handle the BuyPhone "deleted" event.
     */
    public function deleted(BuyPhone $buyPhone): void
    {
        //
    }

    /**
     * Handle the BuyPhone "restored" event.
     */
    public function restored(BuyPhone $buyPhone): void
    {
        //
    }

    /**
     * Handle the BuyPhone "force deleted" event.
     */
    public function forceDeleted(BuyPhone $buyPhone): void
    {
        //
    }
}
