<?php
// app/Models/Invoice.php

namespace App\Models;

use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Storage;

class Invoice extends Purchase
{
    /**
     * Invoice status constants
     */
    const STATUS_DRAFT = 'draft';
    const STATUS_SENT = 'sent';
    const STATUS_PAID = 'paid';
    const STATUS_OVERDUE = 'overdue';
    const STATUS_CANCELLED = 'cancelled';

    /**
     * The "booted" method of the model.
     */
    protected static function booted()
    {
        static::addGlobalScope('invoice', function (Builder $builder) {
            // We'll use the same table, but add invoice-specific scopes
        });

        static::creating(function ($invoice) {
            // Set invoice dates if not provided
            if (!$invoice->invoice_date) {
                $invoice->invoice_date = now()->toDateString();
            }

            if (!$invoice->due_date) {
                $invoice->due_date = now()->addDays(30)->toDateString();
            }

            // Calculate tax amount if not provided
            if ($invoice->tax_rate > 0 && $invoice->tax_amount == 0) {
                $invoice->tax_amount = $invoice->total_amount * ($invoice->tax_rate / 100);
            }
        });
    }

    /**
     * Get invoice items.
     */
    public function items()
    {
        return $this->purchaseItems;
    }

    /**
     * Check if invoice is overdue.
     */
    public function getIsOverdueAttribute(): bool
    {
        if ($this->invoice_status === self::STATUS_PAID || 
            $this->invoice_status === self::STATUS_CANCELLED) {
            return false;
        }

        return $this->due_date && now()->greaterThan($this->due_date);
    }

    /**
     * Get days overdue.
     */
    public function getDaysOverdueAttribute(): ?int
    {
        if (!$this->is_overdue) {
            return null;
        }

        return now()->diffInDays($this->due_date);
    }

    /**
     * Get remaining balance.
     */
    public function getBalanceAttribute(): float
    {
        return max(0, $this->grand_total - $this->paid_amount);
    }

    /**
     * Check if invoice is fully paid.
     */
    public function getIsFullyPaidAttribute(): bool
    {
        return $this->balance <= 0;
    }

    /**
     * Get formatted invoice number.
     */
    public function getFormattedInvoiceNumberAttribute(): string
    {
        return 'INV-' . $this->invoice_number;
    }

    /**
     * Mark invoice as sent.
     */
    public function markAsSent(): bool
    {
        return $this->update(['invoice_status' => self::STATUS_SENT]);
    }

    /**
     * Mark invoice as paid.
     */
    public function markAsPaid(float $amount = null): bool
    {
        $data = ['invoice_status' => self::STATUS_PAID];
        
        if ($amount) {
            $data['paid_amount'] = $this->paid_amount + $amount;
        } else {
            $data['paid_amount'] = $this->grand_total;
        }
        
        return $this->update($data);
    }

    /**
     * Add payment to invoice.
     */
    public function addPayment(float $amount): bool
    {
        $newPaidAmount = $this->paid_amount + $amount;
        
        $data = ['paid_amount' => $newPaidAmount];
        
        if ($newPaidAmount >= $this->grand_total) {
            $data['invoice_status'] = self::STATUS_PAID;
        } elseif ($newPaidAmount > 0) {
            $data['invoice_status'] = self::STATUS_SENT;
        }
        
        return $this->update($data);
    }

    /**
     * Generate invoice data for display.
     */
    public function generateInvoiceData(): array
    {
        $items = $this->items->map(function ($item) {
            return [
                'id' => $item->id,
                'product_name' => $item->product ? $item->product->full_name : 'Unknown Product',
                'product_id' => $item->product_id,
                'quantity' => $item->quantity,
                'unit_price' => $item->unit_price,
                'total_price' => $item->total_price,
                'state' => $item->state,
            ];
        });

        return [
            'invoice' => [
                'id' => $this->id,
                'invoice_number' => $this->formatted_invoice_number,
                'original_invoice_number' => $this->invoice_number,
                'invoice_date' => $this->invoice_date->format('d M Y'),
                'due_date' => $this->due_date->format('d M Y'),
                'status' => $this->invoice_status,
                'terms' => $this->terms,
            ],
            'supplier' => $this->supplier ? [
                'id' => $this->supplier->id,
                'name' => $this->supplier->name,
                'phone' => $this->supplier->phone,
                'email' => $this->supplier->email,
                'address' => $this->supplier->address,
                'contact_person' => $this->supplier->contact_person,
            ] : null,
            'items' => $items,
            'totals' => [
                'subtotal' => $this->total_amount,
                'tax_rate' => $this->tax_rate,
                'tax_amount' => $this->tax_amount,
                'shipping_cost' => $this->shipping_cost,
                'grand_total' => $this->grand_total,
                'paid_amount' => $this->paid_amount,
                'balance' => $this->balance,
                'is_fully_paid' => $this->is_fully_paid,
            ],
            'dates' => [
                'created_at' => $this->created_at->format('d M Y H:i'),
                'updated_at' => $this->updated_at->format('d M Y H:i'),
            ],
            'creator' => $this->creator ? [
                'id' => $this->creator->id,
                'name' => $this->creator->name,
            ] : null,
        ];
    }

    /**
     * Generate PDF invoice.
     */
    public function generatePDF(): string
    {
        $data = $this->generateInvoiceData();
        
        $pdf = Pdf::loadView('invoices.purchase', $data);
        
        // Store the PDF
        $filename = "invoice-{$this->invoice_number}.pdf";
        $path = "invoices/{$filename}";
        
        Storage::put($path, $pdf->output());
        
        // Update invoice with PDF path
        $this->update(['invoice_data' => array_merge($this->invoice_data ?? [], ['pdf_path' => $path])]);
        
        return $path;
    }

    /**
     * Get items from invoice.
     */
    public function getItems(): array
    {
        return $this->items->map(function ($item) {
            return [
                'item_id' => $item->id,
                'product_id' => $item->product_id,
                'product_name' => $item->product->full_name ?? 'Unknown',
                'imei' => $item->product->imei ?? null,
                'quantity' => $item->quantity,
                'unit_price' => $item->unit_price,
                'total_price' => $item->total_price,
                'state' => $item->state,
                'received' => $item->created_at->format('d M Y'),
            ];
        })->toArray();
    }

    /**
     * Get supplier from invoice.
     */
    public function getSupplier(): ?array
    {
        if (!$this->supplier) {
            return null;
        }

        return [
            'supplier_id' => $this->supplier->id,
            'name' => $this->supplier->name,
            'phone' => $this->supplier->phone,
            'email' => $this->supplier->email,
            'address' => $this->supplier->address,
            'contact_person' => $this->supplier->contact_person,
            'total_purchases' => $this->supplier->total_purchases,
            'purchase_count' => $this->supplier->purchase_count,
            'last_purchase' => $this->supplier->last_purchase_date?->format('d M Y'),
        ];
    }

    /**
     * Search invoices by various criteria.
     */
    public static function searchInvoices(array $criteria)
    {
        $query = self::query()->with(['supplier', 'items.product']);
        
        if (!empty($criteria['invoice_number'])) {
            $query->where('invoice_number', 'like', '%' . $criteria['invoice_number'] . '%');
        }
        
        if (!empty($criteria['supplier_id'])) {
            $query->where('supplier_id', $criteria['supplier_id']);
        }
        
        if (!empty($criteria['supplier_name'])) {
            $query->whereHas('supplier', function ($q) use ($criteria) {
                $q->where('name', 'like', '%' . $criteria['supplier_name'] . '%');
            });
        }
        
        if (!empty($criteria['status'])) {
            $query->where('invoice_status', $criteria['status']);
        }
        
        if (!empty($criteria['date_from']) && !empty($criteria['date_to'])) {
            $query->whereBetween('invoice_date', [$criteria['date_from'], $criteria['date_to']]);
        }
        
        if (!empty($criteria['product_name'])) {
            $query->whereHas('items.product', function ($q) use ($criteria) {
                $q->where('model', 'like', '%' . $criteria['product_name'] . '%')
                  ->orWhereHas('brand', function ($q2) use ($criteria) {
                      $q2->where('name', 'like', '%' . $criteria['product_name'] . '%');
                  });
            });
        }
        
        if (!empty($criteria['imei'])) {
            $query->whereHas('items.product', function ($q) use ($criteria) {
                $q->where('imei', 'like', '%' . $criteria['imei'] . '%');
            });
        }
        
        return $query->orderBy('invoice_date', 'desc')->paginate($criteria['per_page'] ?? 15);
    }

    /**
     * Get invoice statistics.
     */
    public static function getInvoiceStatistics(): array
    {
        $total = self::count();
        $paid = self::where('invoice_status', self::STATUS_PAID)->count();
        $pending = self::whereIn('invoice_status', [self::STATUS_DRAFT, self::STATUS_SENT])->count();
        $overdue = self::where('invoice_status', self::STATUS_SENT)
            ->where('due_date', '<', now())
            ->count();
        
        $totalAmount = self::sum('grand_total');
        $paidAmount = self::where('invoice_status', self::STATUS_PAID)->sum('grand_total');
        $pendingAmount = self::whereIn('invoice_status', [self::STATUS_DRAFT, self::STATUS_SENT])->sum('grand_total');
        $overdueAmount = self::where('invoice_status', self::STATUS_SENT)
            ->where('due_date', '<', now())
            ->sum('balance');
        
        return [
            'counts' => [
                'total' => $total,
                'paid' => $paid,
                'pending' => $pending,
                'overdue' => $overdue,
            ],
            'amounts' => [
                'total' => $totalAmount,
                'paid' => $paidAmount,
                'pending' => $pendingAmount,
                'overdue' => $overdueAmount,
            ],
            'averages' => [
                'average_invoice' => $total > 0 ? $totalAmount / $total : 0,
                'payment_ratio' => $total > 0 ? ($paid / $total) * 100 : 0,
            ],
        ];
    }

    /**
     * Export invoices to CSV.
     */
    public static function exportToCSV(array $invoiceIds = null)
    {
        $query = self::with(['supplier', 'items.product']);
        
        if ($invoiceIds) {
            $query->whereIn('id', $invoiceIds);
        }
        
        $invoices = $query->get();
        
        $csvData = [];
        $csvData[] = [
            'Invoice Number', 'Date', 'Due Date', 'Supplier', 'Status', 
            'Subtotal', 'Tax', 'Shipping', 'Total', 'Paid', 'Balance',
            'Items Count', 'Creator', 'Created At'
        ];
        
        foreach ($invoices as $invoice) {
            $csvData[] = [
                $invoice->formatted_invoice_number,
                $invoice->invoice_date->format('d/m/Y'),
                $invoice->due_date->format('d/m/Y'),
                $invoice->supplier->name ?? 'N/A',
                $invoice->invoice_status,
                $invoice->total_amount,
                $invoice->tax_amount,
                $invoice->shipping_cost,
                $invoice->grand_total,
                $invoice->paid_amount,
                $invoice->balance,
                $invoice->items->count(),
                $invoice->creator->name ?? 'N/A',
                $invoice->created_at->format('d/m/Y H:i'),
            ];
        }
        
        $filename = 'invoices-export-' . date('Y-m-d-H-i-s') . '.csv';
        $path = storage_path('app/exports/' . $filename);
        
        $file = fopen($path, 'w');
        foreach ($csvData as $row) {
            fputcsv($file, $row);
        }
        fclose($file);
        
        return $path;
    }
}