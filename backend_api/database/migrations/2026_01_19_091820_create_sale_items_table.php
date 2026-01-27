<?php
// database/migrations/xxxx_xx_xx_xxxxxx_create_sale_items_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sale_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sale_id')->nullable()->constrained("sales")->onDelete('cascade');
            $table->foreignId('product_id')->nullable()->constrained("products")->onDelete('cascade');
            $table->foreignId('buy_phone_id')->nullable()->constrained("buy_phones")->onDelete('set null');
            $table->integer('quantity');
            $table->decimal('unit_price', 10, 2);
            $table->decimal('total_price', 12, 2)->storedAs('quantity * unit_price');
            $table->timestamps();
            
            // Indexes for better performance
            $table->index('sale_id');
            $table->index('product_id');
            $table->index('buy_phone_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sale_items');
    }
};