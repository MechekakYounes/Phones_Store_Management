<?php


namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class UserController extends Controller
{
    /**
     * Display all users (only for super admin)
     */
    public function index(Request $request)
    {
        // Only super admin can view all users
        if (!$request->user()->isSuperAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized. Super admin only.'
            ], 403);
        }

        $query = User::query();
        
        // Exclude super admin from regular list
        $query->where('role', '!=', User::ROLE_SUPER_ADMIN);
        
        // Search
        if ($request->has('search')) {
            $query->search($request->search);
        }
        
        // Filter by role
        if ($request->has('role')) {
            $query->where('role', $request->role);
        }
        
        // Filter by status
        if ($request->has('is_active')) {
            $query->where('is_active', $request->boolean('is_active'));
        }
        
        // Sort
        $sortBy = $request->get('sort_by', 'created_at');
        $sortOrder = $request->get('sort_order', 'desc');
        $query->orderBy($sortBy, $sortOrder);
        
        // Pagination
        $perPage = $request->get('per_page', 15);
        $users = $query->paginate($perPage);
        
        // Add role name to each user
        $users->getCollection()->transform(function ($user) {
            $user->role_name = $user->role_name;
            return $user;
        });
        
        return response()->json([
            'success' => true,
            'data' => $users
        ]);
    }

    /**
     * Create new user (super admin only)
     */
    public function store(Request $request)
    {
        // Only super admin can create users
        if (!$request->user()->isSuperAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized. Super admin only.'
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'username' => 'required|string|max:50|unique:users',
            'password' => 'required|min:6',
            'role' => 'required|in:' . implode(',', User::CREATABLE_ROLES),
            'phone' => 'nullable|string|max:20',
            'is_active' => 'boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::create([
            'name' => $request->name,
            'username' => $request->username,
            'password' => Hash::make($request->password),
            'role' => $request->role,
            'phone' => $request->phone,
            'is_active' => $request->boolean('is_active', true),
        ]);

        $user->role_name = $user->role_name;

        return response()->json([
            'success' => true,
            'message' => 'User created successfully',
            'data' => $user
        ], 201);
    }

    /**
     * Display specific user
     */
    public function show(Request $request, $id)
    {
        $user = User::findOrFail($id);
        
        // Check permissions
        $currentUser = $request->user();
        
        // Super admin can see anyone
        // Users can see their own profile
        if (!$currentUser->isSuperAdmin() && $currentUser->id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 403);
        }
        
        $user->role_name = $user->role_name;
        
        return response()->json([
            'success' => true,
            'data' => $user
        ]);
    }

    /**
     * Update user
     */
    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);
        $currentUser = $request->user();
        
        // Super admin can update anyone
        // Users can update their own profile (except role and status)
        if (!$currentUser->isSuperAdmin() && $currentUser->id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 403);
        }

        $rules = [
            'name' => 'sometimes|string|max:255',
            'username' => 'sometimes|string|max:50|unique:users,username,' . $user->id,
            'phone' => 'nullable|string|max:20',
        ];

        // Only super admin can change role and status
        if ($currentUser->isSuperAdmin()) {
            $rules['role'] = 'sometimes|in:' . implode(',', User::CREATABLE_ROLES);
            $rules['is_active'] = 'sometimes|boolean';
        }

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        // Users cannot deactivate themselves
        if ($currentUser->id === $user->id && $request->has('is_active') && !$request->boolean('is_active')) {
            return response()->json([
                'success' => false,
                'message' => 'You cannot deactivate your own account'
            ], 422);
        }

        $user->update($request->all());
        $user->role_name = $user->role_name;

        return response()->json([
            'success' => true,
            'message' => 'User updated successfully',
            'data' => $user->fresh()
        ]);
    }

    /**
     * Delete user (super admin only)
     */
    public function destroy(Request $request, $id)
    {
        // Only super admin can delete users
        if (!$request->user()->isSuperAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized. Super admin only.'
            ], 403);
        }

        $user = User::findOrFail($id);
        
        // Cannot delete super admin
        if ($user->isSuperAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Cannot delete super admin account'
            ], 422);
        }
        
        // Cannot delete yourself
        if ($user->id === $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'You cannot delete your own account'
            ], 422);
        }

        $user->delete();

        return response()->json([
            'success' => true,
            'message' => 'User deleted successfully'
        ]);
    }

    /**
     * Reset user password (super admin only)
     */
    public function resetPassword(Request $request, $id)
    {
        // Only super admin can reset passwords
        if (!$request->user()->isSuperAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized. Super admin only.'
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'password' => 'required|min:6',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::findOrFail($id);
        
        $user->update([
            'password' => Hash::make($request->password)
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Password reset successfully'
        ]);
    }

    /**
     * Get user statistics (super admin only)
     */
    public function statistics(Request $request)
    {
        // Only super admin can view statistics
        if (!$request->user()->isSuperAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized. Super admin only.'
            ], 403);
        }

        $totalUsers = User::where('role', '!=', User::ROLE_SUPER_ADMIN)->count();
        $activeUsers = User::active()->where('role', '!=', User::ROLE_SUPER_ADMIN)->count();
        
        $roleStats = User::where('role', '!=', User::ROLE_SUPER_ADMIN)
            ->select('role', \DB::raw('COUNT(*) as count'))
            ->groupBy('role')
            ->get()
            ->mapWithKeys(function ($item) {
                return [$item->role => $item->count];
            });

        return response()->json([
            'success' => true,
            'data' => [
                'total_users' => $totalUsers,
                'active_users' => $activeUsers,
                'inactive_users' => $totalUsers - $activeUsers,
                'by_role' => $roleStats,
            ]
        ]);
    }
}