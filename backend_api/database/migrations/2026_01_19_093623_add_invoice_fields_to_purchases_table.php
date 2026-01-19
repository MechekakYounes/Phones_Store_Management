<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('purchases', function (Blueprint $table) {
            $table->date('invoice_date')->nullable()->after('invoice_number');
            $table->date('due_date')->nullable()->after('invoice_date');
            $table->decimal('tax_rate', 5, 2)->default(0)->after('total_amount');
            $table->decimal('tax_amount', 10, 2)->default(0)->after('tax_rate');
            $table->decimal('shipping_cost', 10, 2)->default(0)->after('tax_amount');
            $table->decimal('grand_total', 12, 2)->storedAs('total_amount + tax_amount + shipping_cost')->after('shipping_cost');
            $table->decimal('paid_amount', 12, 2)->default(0)->after('grand_total');
            $table->enum('invoice_status', ['draft', 'sent', 'paid', 'overdue', 'cancelled'])->default('draft')->after('status');
            $table->string('terms')->nullable()->after('notes');
            $table->json('invoice_data')->nullable()->after('terms'); // Store formatted invoice data
        });
    }

    public function down(): void
    {
        Schema::table('purchases', function (Blueprint $table) {
            $table->dropColumn([
                'invoice_date',
                'due_date',
                'tax_rate',
                'tax_amount',
                'shipping_cost',
                'grand_total',
                'paid_amount',
                'invoice_status',
                'terms',
                'invoice_data',
            ]);
        });
    }
};