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
        Schema::create('suppliers', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('phone')->nullable();
            $table->text('address')->nullable();
            $table->text('notes')->nullable(); // Optional: for additional info
            $table->string('email')->nullable(); // Optional: for email contact
            $table->string('contact_person')->nullable(); // Optional: name of contact person
            $table->timestamps();
            
            // Index for better performance
            $table->index('name');
            $table->index('phone');
            $table->index('created_at');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('suppliers');
    }
};
