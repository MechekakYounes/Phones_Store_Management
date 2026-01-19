<?php

namespace App\Http\Controllers\Api;

use App\Models\Category;
use Illuminate\Http\Request;

class CategoryController extends BaseController
{
    public function __construct()
    {
        $this->model = Category::class;
        $this->validationRules = [
            'name' => 'required|string|max:255|unique:categories,name'
        ];
        $this->withRelations = ['products'];
    }
}