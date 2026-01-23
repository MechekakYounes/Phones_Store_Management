<?php
// app/Models/User.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory;

    protected $fillable = [
        'name',
        'username',
        'password',
        'role',
        'phone',
        'is_active',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'password' => 'hashed',
        'is_active' => 'boolean',
    ];

    // Role constants
    const ROLE_SUPER_ADMIN = 'super_admin';
    const ROLE_ADMIN = 'admin';
    const ROLE_SELLER = 'seller';
    const ROLE_TECHNICIAN = 'technician';
    const ROLE_INVENTORY = 'inventory';

    // Available roles for super admin to create
    const CREATABLE_ROLES = [
        self::ROLE_ADMIN,
        self::ROLE_SELLER,
        self::ROLE_TECHNICIAN,
        self::ROLE_INVENTORY,
    ];

    /**
     * Check if user is super admin
     */
    public function isSuperAdmin(): bool
    {
        return $this->role === self::ROLE_SUPER_ADMIN;
    }

    /**
     * Check if user is admin
     */
    public function isAdmin(): bool
    {
        return $this->role === self::ROLE_ADMIN;
    }

    /**
     * Check if user is seller
     */
    public function isSeller(): bool
    {
        return $this->role === self::ROLE_SELLER;
    }

    /**
     * Check if user is technician
     */
    public function isTechnician(): bool
    {
        return $this->role === self::ROLE_TECHNICIAN;
    }

    /**
     * Check if user is inventory manager
     */
    public function isInventory(): bool
    {
        return $this->role === self::ROLE_INVENTORY;
    }

    /**
     * Check if user is active
     */
    public function isActive(): bool
    {
        return $this->is_active === true;
    }

    /**
     * Get role display name
     */
    public function getRoleNameAttribute(): string
    {
        return match($this->role) {
            self::ROLE_SUPER_ADMIN => 'Super Admin',
            self::ROLE_ADMIN => 'Admin',
            self::ROLE_SELLER => 'Seller',
            self::ROLE_TECHNICIAN => 'Technician',
            self::ROLE_INVENTORY => 'Inventory Manager',
            default => 'User',
        };
    }

    /**
     * Get permissions based on role
     */
    public function getPermissions(): array
    {
        $permissions = [];

        // Super Admin has all permissions
        if ($this->isSuperAdmin()) {
            return [
                'manage_users',
                'manage_products',
                'manage_customers',
                'manage_suppliers',
                'manage_sales',
                'manage_purchases',
                'manage_buy_phones',
                'manage_repairs',
                'manage_exchanges',
                'view_reports',
                'view_dashboard',
                'manage_settings',
            ];
        }

        // Admin has almost all permissions except system settings
        if ($this->isAdmin()) {
            $permissions = [
                'manage_users',
                'manage_products',
                'manage_customers',
                'manage_suppliers',
                'manage_sales',
                'manage_purchases',
                'manage_buy_phones',
                'manage_repairs',
                'manage_exchanges',
                'view_reports',
                'view_dashboard',
            ];
        }

        // Seller permissions
        if ($this->isSeller()) {
            $permissions = [
                'view_products',
                'manage_customers',
                'manage_sales',
                'view_buy_phones',
                'view_reports',
                'view_dashboard',
            ];
        }

        // Technician permissions
        if ($this->isTechnician()) {
            $permissions = [
                'view_products',
                'view_customers',
                'manage_repairs',
                'view_buy_phones',
            ];
        }

        // Inventory manager permissions
        if ($this->isInventory()) {
            $permissions = [
                'manage_products',
                'manage_purchases',
                'manage_buy_phones',
                'manage_suppliers',
                'view_inventory',
            ];
        }

        return $permissions;
    }

    /**
     * Check if user has specific permission
     */
    public function hasPermission(string $permission): bool
    {
        return in_array($permission, $this->getPermissions());
    }

    /**
     * Scope to get active users
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope to get users by role
     */
    public function scopeByRole($query, $role)
    {
        return $query->where('role', $role);
    }

    /**
     * Scope to search users
     */
    public function scopeSearch($query, $search)
    {
        return $query->where('name', 'like', "%{$search}%")
                     ->orWhere('username', 'like', "%{$search}%")
                     ->orWhere('phone', 'like', "%{$search}%");
    }
}