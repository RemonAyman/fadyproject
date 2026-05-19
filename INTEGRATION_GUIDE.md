# 🔗 دليل الربط الشامل: من قاعدة البيانات إلى واجهة المستخدم (بالتفصيل الممل)

الملف ده بيشرح حرفياً خطوة بخطوة إزاي دورة حياة البيانات بتم في المشروع (Data Flow). إزاي بنربط الـ **MongoDB** بالـ **Backend (Node.js)**، وبعدين إزاي بنربط الـ **Backend** بالـ **Frontend (Flutter)** بكل صغيرة وكبيرة، من أول كود الاتصال لحد ما الداتا تظهر للمستخدم.

---

## 🟢 الجزء الأول: ربط الباك إند بقاعدة البيانات (Node.js ↔ MongoDB)

الهدف هنا إن الخادم (Server) اللي شغال بـ Node.js يقدر يحتفظ بالبيانات ويسترجعها من قاعدة البيانات السحابية MongoDB Atlas.

### 📄 الملفات المسؤولة عن الربط ده:
1.  `backend/.env`: لتأمين رابط الاتصال.
2.  `backend/server.js`: ده الملف اللي بيحصل فيه الاتصال الفعلي.
3.  `backend/models/`: هنا بنحدد هيكل الداتا (Schemas).

### ⚙️ إزاي بيتم الربط بالحرف؟

1.  **رابط الاتصال (Connection String) وحمايته:**
    عشان نربط السيرفر السحابي بـ MongoDB، محتاجين رابط سري بنجيبه من موقع MongoDB Atlas. الرابط ده بيحتوي على (اليوزر نيم، الباسورد، واسم الداتابيز).
    عشان الحماية، مش بنكتب الرابط ده في الكود مباشرة، بنحطه في ملف مخفي اسمه `.env` بالشكل ده:
    ```env
    MONGODB_URI=mongodb+srv://remonayman968_db_user:PASSWORD@cluster0.7aus8ef.mongodb.net/herafy?appName=Cluster0
    ```
    وبنستخدم حزمة `dotenv` في Node.js عشان نقرأ الرابط ده عن طريق `process.env.MONGODB_URI`.

2.  **كود الاتصال الفعلي (Mongoose Connection):**
    في ملف `server.js` بنستخدم مكتبة `mongoose` (ودي مكتبة Object Data Modeling بتسهل التعامل مع MongoDB). بنكتب الكود ده في أول السيرفر:
    ```javascript
    const mongoose = require('mongoose');
    const MONGODB_URI = process.env.MONGODB_URI;

    mongoose.connect(MONGODB_URI)
      .then(() => console.log('✅ Connected to MongoDB Atlas'))
      .catch(err => console.error('❌ MongoDB Connection Error:', err));
    ```
    السطر ده بيفتح "قناة اتصال دائمة" بين السيرفر والداتابيز طول ما السيرفر شغال.

3.  **إجبار الداتا على شكل معين (Mongoose Schemas):**
    بما إن MongoDB مبتقولش لأ لأي داتا (NoSQL)، كان لازم نظبطها. في مجلد `models`، بنعمل ملف لكل جدول. مثلاً ملف `Booking.js` بنقول فيه:
    ```javascript
    const bookingSchema = new mongoose.Schema({
        customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        craftsmanId: { type: mongoose.Schema.Types.ObjectId, ref: 'Craftsman' },
        description: { type: String, required: true },
        status: { type: String, default: 'pending' }
    });
    ```
    الطريقة دي بتضمن إن السيرفر مش هيحفظ أي طلب حجز (Booking) في الداتابيز إلا لو كان فيه التفاصيل دي بالظبط.

---

## 🔵 الجزء التاني: ربط الفرونت إند بالباك إند (Flutter ↔ Node.js)

الهدف هنا إن الموبايل (Flutter) يتكلم مع السيرفر عن طريق الإنترنت (HTTP Requests)، ويبعتله داتا (زي بيانات التسجيل) أو يسأله عن داتا (زي هاتلي الحرفيين اللي في قسم السباكة).

### 📄 الملفات المسؤولة عن الربط ده:
1.  `lib/api_service.dart`: العقل المدبر في الموبايل اللي بيبعت الطلبات.
2.  `backend/server.js`: اللي بيستقبل الطلبات (APIs).

### ⚙️ إزاي بيتم الربط بالحرف والتفصيل؟

#### 1. تهيئة السيرفر لاستقبال الطلبات (CORS & Body Parser):
عشان السيرفر يرضى يستقبل طلبات من موبايل أبلكيشن، في `server.js` كتبنا:
```javascript
app.use(cors()); // بيسمح باستقبال الطلبات من أي مكان
app.use(express.json()); // بيخلي السيرفر يفهم الداتا اللي جاية بصيغة JSON
```

#### 2. فتح المسارات في الباك إند (API Endpoints):
عملنا روابط (Endpoints) لكل أكشن. مثلاً عشان العميل يطلب حرفي، عملنا المسار ده:
```javascript
// POST request لاستقبال بيانات حجز جديد
app.post('/api/bookings', async (req, res) => {
    // بياخد الداتا اللي الموبايل بعتها
    const bookingData = req.body; 
    // بيعمل منها أوبجيكت جديد حسب الـ Schema ويرميه في MongoDB
    const booking = new Booking(bookingData);
    await booking.save();
    // بيرجع رسالة للموبايل إن الطلب اتسجل بنجاح
    res.status(201).json(booking);
});
```

#### 3. إرسال الطلب من الفلاتر (HTTP Package):
في الفلاتر، بنستخدم حزمة `http`. في ملف `api_service.dart`، بنجهز الدالة اللي هتكلم السيرفر. الداتا بتتبعت دايماً بصيغة `JSON`، وبنستقبلها كـ `JSON` ونحولها لـ Map عشان الفلاتر يفهمها.
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

static Future<bool> createBooking(String userId, String craftsmanId, String desc) async {
  // 1. تحديد الرابط بتاع السيرفر
  final url = Uri.parse('http://YOUR_SERVER_IP:5000/api/bookings');
  
  // 2. إرسال الطلب (POST) مع إرفاق البيانات
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({ // تحويل الداتا من فلاتر لـ JSON
      'customerId': userId,
      'craftsmanId': craftsmanId,
      'description': desc
    }),
  );

  // 3. التأكد من الرد
  if (response.statusCode == 201) {
    return true; // الحجز تم بنجاح
  } else {
    return false; // حصل مشكلة
  }
}
```

#### 4. دورة حياة الـ Authentication (JWT Tokens & SharedPreferences):
دي أهم جزء في الربط. إزاي الموبايل بيفضل فاكر اليوزر؟
1.  **في الفلاتر:** اليوزر بيكتب الإيميل والباسورد في `Login_Screen` ويدوس لوجين.
2.  **الربط:** `api_service` بيبعتهم للـ Node.js (`/api/auth/login`).
3.  **في السيرفر:** المونجو بيفحص الباسورد بالـ `bcrypt`، ولو صح، السيرفر بيولد مفتاح سري (JWT Token) مدته 30 يوم، ويرجعه للموبايل.
4.  **الاستقبال في الفلاتر:** الفلاتر بياخد الـ Token ده، وبيحفظه جوا الموبايل نفسه باستخدام حزمة `SharedPreferences`.
    ```dart
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
    await prefs.setString('userId', data['userId']);
    await prefs.setString('userType', data['userType']);
    ```
5.  الخطوة دي بتضمن إن حتى لو العميل قفل التطبيق وفتحه تاني، التطبيق هيدور في الـ SharedPreferences هيلاقي الـ Token ويقوم مدخله على شاشة الـ Home على طول من غير ما يطلب باسورد تاني.

### 💡 ملخص الرحلة (The Full Trip):
1.  **(Flutter):** المستخدم بيدوس "احجز الآن". زرار الحجز بيكلم `api_service.dart` وبيحوله الداتا لـ JSON.
2.  **(Network):** الداتا بتسافر عبر الـ HTTP للـ Node.js Server.
3.  **(Node.js):** السيرفر في `server.js` بيستقبل الطلب على Endpoint الـ `/api/bookings` وبيحلل الـ JSON عن طريق `express.json()`.
4.  **(Mongoose):** السيرفر بيكلم `Mongoose` يديله الداتا عشان يتأكد إنها مطابقة للـ `Booking Schema`.
5.  **(MongoDB Atlas):** المونجوس بيكلم أطلس السحابي ويحفظ الـ Document الجديد.
6.  **(Node.js):** أطلس بيرد على السيرفر بإن الداتا اتحفظت (Status 201).
7.  **(Network):** السيرفر بيرجع الداتا دي كـ JSON Response للفلاتر.
8.  **(Flutter):** الموبايل بيعمل `jsonDecode` للرد، والـ UI (الشاشة) بيعمل `setState` وبيظهر رسالة للمستخدم (تم الحجز بنجاح!).
