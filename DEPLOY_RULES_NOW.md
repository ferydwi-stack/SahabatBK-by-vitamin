# ⚠️ PENTING: DEPLOY RULES SEKARANG!

## Masalah: Permission Denied saat Simpan Catatan

Rules untuk collection `catatan` sudah diperbaiki, tapi **HARUS di-deploy ke Firebase Console**.

## Langkah Deploy (WAJIB):

### 1. Buka Firebase Console
**Link langsung:** https://console.firebase.google.com/project/sahabatbk-f3fb9/firestore/rules

### 2. Copy Rules Berikut (SELURUHNYA):

```rules
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    function isSignedIn() {
      return request.auth != null;
    }
    
    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    
    function userExists() {
      return exists(/databases/$(database)/documents/users/$(request.auth.uid));
    }
    
    function isTeacher() {
      return isSignedIn() && userExists() && getUserData().role == 'guru';
    }
    
    function isStudent() {
      return isSignedIn() && userExists() && getUserData().role == 'siswa';
    }
    
    match /users/{userId} {
      allow read: if isSignedIn();
      allow update: if isSignedIn() && request.auth.uid == userId;
      allow create: if isSignedIn() && request.auth.uid == userId;
    }
    
    match /pengajuan/{pengajuanId} {
      allow create: if isStudent();
      allow read: if isSignedIn() && (
        isTeacher() || 
        (isStudent() && resource.data.nisn == getUserData().nisn)
      );
      allow update: if isTeacher();
    }
    
    match /catatan/{catatanId} {
      allow read: if isTeacher();
      allow create: if isTeacher() && request.resource.data.guru_uid == request.auth.uid;
      allow update: if isTeacher();
    }
    
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### 3. Paste dan Deploy
1. **Hapus semua rules yang ada** di Firebase Console
2. **Paste rules di atas** ke editor
3. Klik tombol **"Publish"** (biru, di kanan atas)
4. Tunggu sampai muncul **"Rules published successfully"**

### 4. Verifikasi
- Setelah deploy, akan ada timestamp: **"Last published: [waktu]"**
- Jika sudah ada timestamp, rules sudah aktif

### 5. Test
1. **Restart aplikasi** (tutup dan buka lagi)
2. Coba simpan catatan lagi
3. Error permission-denied seharusnya sudah hilang

## Catatan Penting:

- ✅ Rules untuk `catatan` sudah benar: `allow update: if isTeacher();`
- ✅ Ini akan allow semua guru untuk update catatan (termasuk dokumen lama dengan `guru_uid` kosong)
- ✅ Create tetap memvalidasi `guru_uid` harus sesuai

## Jika Masih Error:

1. Pastikan rules sudah di-deploy (cek timestamp "Last published")
2. Pastikan user yang login adalah guru (role = 'guru' di Firestore)
3. Pastikan data user ada di collection `users` dengan field `role`
4. Restart aplikasi setelah deploy rules
