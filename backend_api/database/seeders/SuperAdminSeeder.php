<?php
// database/seeders/SuperAdminSeeder.php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class SuperAdminSeeder extends Seeder
{
    public function run(): void
    {
        // Check if super admin already exists
        if (User::where('role', User::ROLE_SUPER_ADMIN)->exists()) {
            $this->command->info('Super Admin already exists.');
            return;
        }

        // Create super admin
        User::create([
            'name' => 'Super Admin',
            'username' => 'superadmin',
            'password' => Hash::make('admin123'),
            'role' => User::ROLE_SUPER_ADMIN,
            'phone' => '1234567890',
            'is_active' => true,
        ]);

        $this->command->info('✅ Super Admin created successfully!');
        $this->command->info('👤 Username: superadmin');
        $this->command->info('🔑 Password: admin123');
        $this->command->warn('⚠️  Please change the password immediately!');

        // Create some test users
        User::create([
            'name' => 'Store Manager',
            'username' => 'manager',
            'password' => Hash::make('manager123'),
            'role' => User::ROLE_ADMIN,
            'phone' => '0987654321',
            'is_active' => true,
        ]);

        User::create([
            'name' => 'Sales Person',
            'username' => 'seller',
            'password' => Hash::make('seller123'),
            'role' => User::ROLE_SELLER,
            'phone' => '5555555555',
            'is_active' => true,
        ]);

        User::create([
            'name' => 'Phone Technician',
            'username' => 'technician',
            'password' => Hash::make('tech123'),
            'role' => User::ROLE_TECHNICIAN,
            'phone' => '4444444444',
            'is_active' => true,
        ]);

        User::create([
            'name' => 'Inventory Manager',
            'username' => 'inventory',
            'password' => Hash::make('inventory123'),
            'role' => User::ROLE_INVENTORY,
            'phone' => '3333333333',
            'is_active' => true,
        ]);

        $this->command->info('✅ Test users created successfully!');
    }
}