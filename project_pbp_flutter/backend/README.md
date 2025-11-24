# Backend API untuk Aplikasi Pencatatan Hutang

API ini menyediakan endpoint untuk mengelola data pengguna dan hutang.

## Cara Menjalankan Backend

1. Install dependencies:
```bash
npm install
```

2. Jalankan server:
```bash
node server.js
```

Server akan berjalan di `http://localhost:3000`

## Endpoint API

### Users
- `GET /api/users` - Mendapatkan semua user dengan summary hutang
- `GET /api/users/:id` - Mendapatkan detail user dengan hutangnya
- `POST /api/users` - Menambahkan user baru

### Hutangs
- `GET /api/hutangs` - Mendapatkan semua hutang
- `GET /api/hutangs/:id` - Mendapatkan detail hutang
- `POST /api/hutangs` - Menambahkan hutang baru
- `PUT /api/hutangs/:id` - Update hutang

### Payments
- `POST /api/hutangs/:id/payments` - Menambahkan pembayaran untuk hutang

### Summary
- `GET /api/summary` - Mendapatkan ringkasan hutang

### Health Check
- `GET /api/health` - Cek status API

## Contoh Request Body

### Tambah User (POST /api/users)
```json
{
  "name": "Nama User",
  "phone": "081234567890",
  "address": "Jl. Contoh No. 123",
  "photoUrl": "https://example.com/photo.jpg"
}
```

### Tambah Hutang (POST /api/hutangs)
```json
{
  "description": "Hutang belanja",
  "amount": 2500000,
  "dueDate": "2024-12-31",
  "debtorId": "1",
  "notes": "Untuk kebutuhan sehari-hari"
}
```

### Tambah Pembayaran (POST /api/hutangs/:id/payments)
```json
{
  "amount": 1000000,
  "notes": "Pembayaran pertama"
}
```