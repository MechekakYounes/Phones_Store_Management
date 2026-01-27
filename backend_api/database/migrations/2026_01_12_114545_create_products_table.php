<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('brand_id')->constrained('brands')->onDelete('cascade');
            $table->string('model');
            $table->string('storage')->nullable(); // e.g., "128GB", "256GB"
            $table->string('color')->nullable();
            $table->string('imei', 15)->unique()->nullable(); // 15 chars for IMEI
            $table->decimal('purchase_price', 10, 2); 
            $table->decimal('selling_price', 10, 2);
            $table->integer('quantity')->default(0);
            $table->timestamps();
            // indexes for better performance
            $table->index('brand_id');
            $table->index('imei');
            $table->index('model');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
