<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Models\BuyPhone;
use App\Observers\BuyPhoneObserver;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        BuyPhone::observe(BuyPhoneObserver::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
