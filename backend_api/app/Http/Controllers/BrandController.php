<?php
// app/Http\Controllers\Api\BrandController.php

namespace App\Http\Controllers\Api;

use App\Models\Brand;
use Illuminate\Http\Request;

class BrandController extends BaseController
{
    public function __construct()
    {
        $this->model = Brand::class;
        $this->validationRules = [
            'name' => 'required|string|max:255|unique:brands,name'
        ];
    }

    public function statistics()
    {
        $totalBrands = Brand::count();
        $brandsWithProducts = Brand::has('products')->count();
        
        $topBrands = Brand::withCount(['products as total_products'])
            ->withSum(['products as total_stock' => function ($query) {
                $query->select(\DB::raw('SUM(quantity)'));
            }], '')
            ->orderBy('total_products', 'desc')
            ->limit(10)
            ->get();
        
        return response()->json([
            'success' => true,
            'data' => [
                'total_brands' => $totalBrands,
                'brands_with_products' => $brandsWithProducts,
                'top_brands' => $topBrands,
            ]
        ]);
    }
}