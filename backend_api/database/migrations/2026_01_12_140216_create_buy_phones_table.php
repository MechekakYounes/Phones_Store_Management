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
        Schema::create('buy_phones', function (Blueprint $table) {
            $table->id();
            $table->string('seller_name');
            $table->string('seller_phone')->nullable();
            $table->foreignId('brand_id')->constrained('brands')->onDelete('cascade');
            $table->string('model');
            $table->string('color')->nullable();
            $table->string('storage')->nullable();
            $table->string('imei', 15)->nullable()->unique();
            $table->string('condition')->nullable(); // good, very_good, excellent, broken, damaged
            $table->decimal('buy_price', 10, 2);
            $table->decimal('resell_price', 10, 2)->nullable();
            $table->string('status')->nullable(); // received, tested, listed, sold, returned
            $table->text('notes')->nullable();
            $table->text('issues')->nullable(); // Any issues found during testing
            $table->date('received_date')->nullable();
            $table->date('sold_date')->nullable();
            $table->foreignId('received_by')->nullable()->constrained('users')->onDelete('set null');
            $table->foreignId('sold_to')->nullable()->constrained('customers')->onDelete('set null');
            $table->timestamps();
            
            // Indexes for better performance
            $table->index('imei');
            $table->index('seller_phone');
            $table->index('brand_id');
            $table->index('condition');
            $table->index('status');
            $table->index('received_date');
            $table->index('sold_date');
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('buy_phones');
    }
};
