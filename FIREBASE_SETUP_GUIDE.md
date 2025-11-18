# Firebase Authentication Setup Guide

## Current Issue
Google Sign-In is showing: `PlatformException(network_error, com.google.android.gms.common.api.ApiException: 7)`

This error means Firebase Authentication is not properly configured.

---

## ✅ Your Current Configuration

**Project ID:** goa-hostel-app
**Package Name:** com.hostelapp.miniproject
**SHA-1 Fingerprint:** `2A:D2:F8:1F:98:C0:56:1A:87:6F:A9:CF:2C:0B:01:7D:C7:33:6B:19`

---

## 🔧 Fix Steps

### Step 1: Enable Authentication in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **goa-hostel-app**
3. Click **Authentication** in left sidebar
4. Click **Get Started** (if not already enabled)
5. Go to **Sign-in method** tab

### Step 2: Enable Email/Password Authentication

1. Click on **Email/Password** provider
2. Click **Enable** toggle
3. Make sure **Email/Password** is enabled (not Email link)
4. Click **Save**

### Step 3: Enable Google Sign-In

1. Click on **Google** provider
2. Click **Enable** toggle
3. Enter **Project support email** (your email)
4. Click **Save**

### Step 4: Verify SHA-1 Certificate

1. In Firebase Console, click the **gear icon** (Settings)
2. Go to **Project settings**
3. Scroll down to **Your apps** section
4. Click on your Android app (com.hostelapp.miniproject)
5. Scroll to **SHA certificate fingerprints**
6. Verify this SHA-1 is listed:
   ```
   2A:D2:F8:1F:98:C0:56:1A:87:6F:A9:CF:2C:0B:01:7D:C7:33:6B:19
   ```
7. If NOT listed, click **Add fingerprint** and paste it

### Step 5: Download Updated google-services.json

1. In the same **Project settings** page
2. Under your Android app, click **google-services.json** download button
3. Replace the file at: `android/app/google-services.json`

### Step 6: Rebuild the App

Run these commands:
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🧪 Testing

### Test Email/Password Sign-Up:
1. Open the app
2. Click "Don't have an account? Sign up"
3. Enter:
   - Email: test@example.com
   - Password: test123
   - Name: Test User
   - Room: 101
4. Click Sign Up

### Test Email/Password Login:
1. Use the same credentials
2. Click Login

### Test Google Sign-In:
1. Click "Sign in with Google"
2. Select your Google account
3. Should redirect to dashboard

---

## 🐛 Common Issues

### Issue 1: "User not found" or "Wrong password"
- Make sure you've signed up first
- Check Firebase Console → Authentication → Users to see registered users

### Issue 2: Google Sign-In still fails
- Make sure SHA-1 is added in Firebase Console
- Make sure Google Sign-In is enabled
- Try uninstalling and reinstalling the app
- Clear app data: Settings → Apps → Hostel App → Clear Data

### Issue 3: "Network error"
- Check internet connection
- Make sure INTERNET permission is in AndroidManifest.xml (already added)
- Verify google-services.json is in android/app/ folder

---

## 📱 Check Firebase Console

After setup, verify in Firebase Console:

1. **Authentication → Users**: Should show registered users after sign-up
2. **Authentication → Sign-in method**: Should show Email/Password and Google as "Enabled"
3. **Project Settings → Your apps**: Should show your Android app with SHA-1

---

## 🆘 Still Having Issues?

1. Check Firebase Console logs: Authentication → Usage
2. Enable debug logging in Android:
   ```bash
   adb shell setprop log.tag.GoogleSignInActivity VERBOSE
   adb shell setprop log.tag.GoogleSignInClient VERBOSE
   adb logcat -s GoogleSignInActivity,GoogleSignInClient
   ```

3. Verify your Firebase project is on the **Spark (free) plan** or higher
4. Make sure billing is enabled if using Blaze plan

---

## ✨ After Setup

Once authentication works:
- Users will be stored in Firebase Authentication
- User data (name, room, VIP status) will be in Firestore → users collection
- You can manage users from Firebase Console
