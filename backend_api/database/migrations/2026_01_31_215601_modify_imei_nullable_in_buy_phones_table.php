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
        Schema::table('buy_phones', function (Blueprint $table) {
            $table->string('imei')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('buy_phones', function (Blueprint $table) {
            // Note: This might fail if there are null values, so be careful rollback
            $table->string('imei')->nullable(false)->change();
        });
    }
};
