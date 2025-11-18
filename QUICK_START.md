# 🚀 Quick Start Guide

## 1️⃣ Dependencies Installed ✅
```bash
flutter pub get  # Already done!
```

## 2️⃣ Create Test Users

### Option A: Through Firebase Console

**Warden Account:**
```
1. Sign up in app
2. Firebase Console → Firestore → users → [user_id]
3. Edit document:
   role: "warden"
   hostelName: "Hostel A"
```

**Principal Account:**
```
1. Sign up in app
2. Firebase Console → Firestore → users → [user_id]
3. Edit document:
   role: "principal"
```

**VIP Student:**
```
1. Sign up in app
2. Firebase Console → Firestore → users → [user_id]
3. Edit document:
   isVip: true
   vipActivatedAt: [current timestamp]
```

## 3️⃣ Add Navigation

Add to your drawer/navigation:

```dart
// Students
ListTile(
  leading: Icon(Icons.report_problem),
  title: Text('My Complaints'),
  onTap: () => Navigator.push(context, 
    MaterialPageRoute(builder: (_) => ComplaintListScreen())),
),

// VIP
ListTile(
  leading: Icon(Icons.workspace_premium, color: Colors.amber),
  title: Text('VIP Premium'),
  onTap: () => Navigator.push(context,
    MaterialPageRoute(builder: (_) => PremiumVipScreen())),
),

// Wardens only
if (userRole == 'warden')
  ListTile(
    leading: Icon(Icons.admin_panel_settings),
    title: Text('Warden Dashboard'),
    onTap: () => Navigator.push(context,
      MaterialPageRoute(builder: (_) => WardenDashboardScreen())),
  ),

// Principal only
if (userRole == 'principal')
  ListTile(
    leading: Icon(Icons.school),
    title: Text('Principal Dashboard'),
    onTap: () => Navigator.push(context,
      MaterialPageRoute(builder: (_) => PrincipalDashboardScreen())),
  ),
```

## 4️⃣ Test Flow

### As Student:
1. Login
2. Submit complaint (Add Complaint)
3. View in "My Complaints"
4. Check VIP Premium screen

### As Warden:
1. Login with warden account
2. Open Warden Dashboard
3. See only your hostel's complaints
4. Update a complaint status
5. Add remarks

### As Principal:
1. Login with principal account
2. Open Principal Dashboard
3. View all complaints
4. Filter by hostel
5. Mark complaint as urgent

## 5️⃣ Key Screens

| Screen | Path | Purpose |
|--------|------|---------|
| Add Complaint | `lib/screens/complaints/add_complaint.dart` | Submit new complaint |
| Complaint List | `lib/screens/complaints/complaint_list.dart` | View user complaints |
| Complaint Detail | `lib/screens/complaints/complaint_detail_screen.dart` | Timeline view |
| Warden Dashboard | `lib/screens/warden/warden_dashboard.dart` | Manage complaints |
| Principal Dashboard | `lib/screens/principal/principal_dashboard.dart` | Admin oversight |
| VIP Dashboard | `lib/screens/vip/vip_dashboard_screen.dart` | Premium features |
| VIP Activation | `lib/screens/vip/premium_vip_screen.dart` | Activate VIP |
| Room Service | `lib/screens/room_service/room_service_screen.dart` | Service requests |

## 6️⃣ Firestore Collections

### users
```javascript
{
  role: "student" | "warden" | "principal",
  hostelName: "Hostel A" | "Hostel B" | null,
  isVip: true | false
}
```

### complaints
```javascript
{
  hostelName: "Hostel A" | "Hostel B",
  status: "Pending" | "In Progress" | "Resolved by Warden" | "Escalated to Principal",
  isVip: true | false,
  priority: "low" | "medium" | "high" | "urgent"
}
```

### room_services
```javascript
{
  serviceType: "cleaning" | "laundry" | "mattress" | "bulb" | "maintenance" | "other",
  status: "requested" | "accepted" | "in-progress" | "completed",
  isVip: true | false
}
```

## 7️⃣ VIP Features

### Activate VIP:
```dart
// In Firebase Console
users → [user_id] → Edit:
  isVip: true
  vipActivatedAt: [timestamp]
```

### VIP Benefits:
- ⚡ 30% faster response
- 🎯 Priority handling
- 💬 24/7 support
- ✅ Guaranteed resolution
- 🔔 Real-time updates
- 🏆 Exclusive services

## 8️⃣ Status Flow

```
Student submits → Pending
                    ↓
Warden accepts → In Progress
                    ↓
Warden resolves → Resolved by Warden

OR

Not updated in 24hrs → Escalated to Principal
```

## 9️⃣ Quick Commands

```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Build APK
flutter build apk

# Check for issues
flutter analyze

# Format code
flutter format .
```

## 🔟 Important Files

📄 **HOSTEL_MANAGEMENT_COMPLETE.md** - Full implementation guide
📄 **VIP_PREMIUM_UI_GUIDE.md** - UI design patterns
📄 **CLOUD_FUNCTION_SETUP.md** - Auto-escalation setup
📄 **IMPLEMENTATION_SUMMARY.md** - What's been built

## 🎯 Quick Test Checklist

- [ ] Student can submit complaint
- [ ] Student can view complaints
- [ ] Warden sees only their hostel
- [ ] Warden can update status
- [ ] Principal sees all complaints
- [ ] VIP badge shows correctly
- [ ] Images upload successfully
- [ ] Timeline displays updates
- [ ] Room services work
- [ ] VIP dashboard loads

## 🆘 Quick Fixes

**Can't see complaints?**
→ Check `hostelName` matches in user and complaint

**VIP not working?**
→ Set `isVip: true` in user document

**Images not uploading?**
→ Check Firebase Storage rules

**Role not working?**
→ Verify `role` field in user document

## 📱 Test Accounts Template

Create these in Firebase:

```
Student 1:
  email: student1@test.com
  role: student
  isVip: false

Student 2 (VIP):
  email: vip@test.com
  role: student
  isVip: true

Warden A:
  email: wardena@test.com
  role: warden
  hostelName: Hostel A

Warden B:
  email: wardenb@test.com
  role: warden
  hostelName: Hostel B

Principal:
  email: principal@test.com
  role: principal
```

## 🎨 UI Highlights

- ✨ Glassmorphism cards
- 🌟 Gold gradients for VIP
- 🎭 Smooth animations
- 💫 Shimmer loading
- 🎯 Color-coded badges
- 📊 Professional dashboards

## 🚀 You're Ready!

Everything is set up and ready to go. Just:
1. Create test users
2. Add navigation
3. Test the flows
4. Enjoy your premium hostel management system!

**Need help?** Check the detailed guides in the documentation files.

---

**Built with ❤️ using Flutter & Firebase**
