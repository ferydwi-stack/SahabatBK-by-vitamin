# CARA DEPLOY FIRESTORE RULES

## ⚠️ PENTING: Rules HARUS di-deploy ke Firebase Console!

File `firestore.rules` di project ini HANYA file lokal. Rules belum aktif sampai di-deploy ke Firebase.

## Langkah-langkah Deploy:

### 1. Buka Firebase Console
- Link langsung: https://console.firebase.google.com/project/sahabatbk-f3fb9/firestore/rules
- Atau: https://console.firebase.google.com → Pilih project → Firestore Database → Rules

### 2. Copy Rules
Buka file `firestore.rules` di project ini, copy SEMUA isinya.

### 3. Paste ke Firebase Console
- Hapus semua rules yang ada di editor Firebase Console
- Paste rules yang sudah di-copy
- Klik tombol **"Publish"** (biru, di kanan atas)

### 4. Verifikasi
- Setelah deploy, akan muncul: "Rules published successfully"
- Akan ada timestamp: "Last published: [waktu]"

### 5. Test
- Restart aplikasi (tutup dan buka lagi)
- Coba registrasi akun baru
- Error permission-denied seharusnya sudah hilang

## Rules yang Perlu Di-Deploy:

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
    
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## Troubleshooting:

### Masih error permission-denied?
1. Pastikan rules sudah di-deploy (cek timestamp "Last published")
2. Restart aplikasi setelah deploy rules
3. Pastikan user sudah login (createUserWithEmailAndPassword sudah berhasil)
4. Cek Firebase Console → Firestore → Rules untuk memastikan rules sudah ter-update

### Rules tidak bisa di-deploy?
- Pastikan format rules benar (tidak ada syntax error)
- Cek apakah ada error message di Firebase Console
- Pastikan Anda memiliki permission untuk edit rules di project Firebase

