<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\BuyPhoneController;
use App\Http\Controllers\SaleController;



// Public routes (no authentication needed)
Route::get('/check-super-admin', [AuthController::class, 'checkSuperAdmin']);
Route::post('/setup-super-admin', [AuthController::class, 'setupSuperAdmin']);
Route::post('/login', [AuthController::class, 'login']);

// Protected routes (require authentication)
Route::middleware('auth:sanctum')->group(function () {
    // Auth routes (all authenticated users)
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'user']);
    Route::post('/change-password', [AuthController::class, 'changePassword']);
    Route::post('/update-profile', [AuthController::class, 'updateProfile']);

    // BuyPhone routes
    Route::get('buy-phones', [BuyPhoneController::class, 'index']);
    Route::get('buy-phones/{id}', [BuyPhoneController::class, 'show']);
    Route::post('buy-phones', [BuyPhoneController::class, 'store']);
    Route::put('buy-phones/{id}', [BuyPhoneController::class, 'update']);
    Route::delete('buy-phones/{id}', [BuyPhoneController::class, 'destroy']);
    Route::post('/buy-phones/{id}/sell', [BuyPhoneController::class, 'sell']);
    Route::post('buy-phones/{id}/mark-tested', [BuyPhoneController::class, 'markTested']);
    Route::post('buy-phones/{id}/mark-listed', [BuyPhoneController::class, 'markListed']);
    Route::post('buy-phones/{id}/mark-sold', [BuyPhoneController::class, 'markSold']);
    Route::post('buy-phones/{id}/mark-returned', [BuyPhoneController::class, 'markReturned']);
    Route::get('buy-phones-stats', [BuyPhoneController::class, 'stats']);
    
    //sale routes 
    Route::post('sales', [SaleController::class, 'store']);

    //History routes
    Route::get('history', [App\Http\Controllers\HistoryController::class, 'index']);
    
    // User management (super admin only)
    Route::middleware('super_admin')->group(function () {
        Route::apiResource('users', UserController::class);
        Route::post('users/{id}/reset-password', [UserController::class, 'resetPassword']);
        Route::get('users/statistics', [UserController::class, 'statistics']);
    });
    
    // Product routes (require manage_products permission)
    Route::middleware('permission:manage_products')->group(function () {
        // Product routes will go here
    });
    
    // Customer routes (require manage_customers permission)
    Route::middleware('permission:manage_customers')->group(function () {
        // Customer routes will go here
    });
    
    // Sale routes (require manage_sales permission)
    Route::middleware('permission:manage_sales')->group(function () {
        // Sale routes will go here
    });
    
    // Purchase routes (require manage_purchases permission)
    Route::middleware('permission:manage_purchases')->group(function () {
        // Purchase routes will go here
    });
    
    // Dashboard (require view_dashboard permission)
    Route::middleware('permission:view_dashboard')->group(function () {
        // Dashboard routes will go here
    });
});