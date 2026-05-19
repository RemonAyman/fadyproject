# 🔍 تفصيل ملفات المشروع (Deep Dive)

الملف ده بيشرح بالظبط **إيه اللي جوه كل فايل بالحرف**، وإيه الكومبوننتس (Components) اللي فيه، وليه اتعملت بالشكل ده.

---

## 📱 أولاً: ملفات الفلاتر (Frontend - lib folder)

### 1. `main.dart`
*   **موجود فيه إيه؟** فيه الـ `main()` دالة الأساسية اللي بتشغل الأبلكيشن `runApp`.
*   **ليه موجود؟** بيعمل `await Firebase.initializeApp()` عشان يربط الفايربيز قبل ما الـ UI يترسم. كمان بيعمل `MaterialApp` اللي بيحدد ثيم التطبيق (Theme) والمسار المبدئي (Initial Route) اللي هو غالباً الـ Splash Screen.

### 2. `api_service.dart`
*   **موجود فيه إيه؟** كلاس اسمه `ApiService` جواه دوال (Functions) زي `login()`, `registerUser()`, `registerCraftsman()`, `fetchCraftsmen()`, و `createBooking()`.
*   **ليه موجود؟** ده حلقة الوصل (Network Layer). بنستخدم فيه حزمة `http` عشان نبعت طلبات (GET, POST, PUT) للـ Node.js، وبنستخدم `jsonDecode` عشان نحول الداتا اللي راجعة لـ Map نقدر نعرضه في الشاشات.

### 3. `Splash_Screen.dart`
*   **موجود فيه إيه؟** شاشة فيها `Animation` أو `Image.asset` للوجو التطبيق، وفيها `Timer` أو `Future.delayed` بيستنى 3 ثواني.
*   **ليه موجود؟** عشان يدي فرصة للتطبيق يحمل في الخلفية، وبعدين بيعمل `Navigator.pushReplacement` عشان ينقل اليوزر للـ Onboarding أو شاشة اللوجين حسب هو فاتح التطبيق لأول مرة ولا لأ.

### 4. `Login_Screen.dart`
*   **موجود فيه إيه؟** `TextFormField` للإيميل وواحد للباسورد، وزرار `ElevatedButton` لتسجيل الدخول. وجواه `FormState` عشان يتأكد إن الحقول مش فاضية.
*   **ليه موجود؟** بياخد الداتا دي ويبعتها لـ `ApiService.login()`. لو رجعله Token، بيحفظه في الـ `SharedPreferences` (عشان اليوزر يفضل عامل لوجين)، وبيشوف نوع الحساب (user, craftsman, admin) ويوجهه للشاشة المناسبة.

### 5. `AdminDashboard_Screen.dart`
*   **موجود فيه إيه؟** 
    *   **Cards / Containers:** بتعرض إحصائيات (عدد العملاء، عدد الطلبات، الأرباح).
    *   **ListView / Table:** بتعرض لستة اليوزرز أو الحرفيين.
    *   **Buttons:** زرار لكل مستخدم بيعمل `Block` أو `Approve`.
*   **ليه موجود؟** عشان الإدمن يقدر يقرأ داتا الإحصائيات من الـ API (endpoint: `/api/admin/stats`)، ويقدر يتحكم في الحسابات ويبعت طلب `DELETE` لحذف أي مستخدم مخالف.

### 6. `Home_Screen.dart` (شاشة العميل الرئيسية)
*   **موجود فيه إيه؟** `GridView` بيعرض الأقسام (سباكة، كهرباء، الخ)، و `SearchBar` عشان يدور على حرفي معين، و `BottomNavigationBar` للتنقل بين الرئيسية، طلباتي، والبروفايل.
*   **ليه موجود؟** دي واجهة العميل الأساسية، لما يدوس على قسم معين، بيعمل `Navigator.push` لـ `CraftsmanList_Screen` ويبعت اسم القسم كـ Parameter عشان يفلتر الحرفيين بسببه.

### 7. `CraftsmanList_Screen.dart`
*   **موجود فيه إيه؟** `FutureBuilder` بيكلم الـ API يجيب لستة الحرفيين. جوه الـ FutureBuilder في `ListView.builder` بيعمل `Card` لكل حرفي (صورته، اسمه، تقييمه، وسعره).
*   **ليه موجود؟** عشان يطبع الداتا اللي جاية من الداتابيز قدام العميل. وفيها زراير فلترة (Filter) عشان العميل يرتبهم بالسعر أو التقييم عن طريق إرسال Query Parameters للباك إند.

### 8. `CraftsmanDetails_Screen.dart`
*   **موجود فيه إيه؟** شاشة بتعرض تفاصيل حرفي معين `Craftsman`. فيها صورته بشكل كبير، بياناته، وسجل شغله، وزرار كبير تحت اسمه `احجز الآن` (Book Now).
*   **ليه موجود؟** عشان العميل يشوف تفاصيل الصنايعي قبل ما يحجز. لما بيدوس حجز، بينقله لـ `Booking_Screen` وبياخد الـ ID بتاع الحرفي معاه.

### 9. `Booking_Screen.dart`
*   **موجود فيه إيه؟** `TextField` لوصف المشكلة، مكان عشان يرفع صورة للمشكلة (اختياري)، وزرار تأكيد الطلب.
*   **ليه موجود؟** بياخد تفاصيل المشكلة والـ `customerId` والـ `craftsmanId` ويبعتهم للـ API (endpoint: `POST /api/bookings`) عشان يعمل Record جديد في المونجو دي بي ويوصل إشعار للحرفي.

### 10. `craftsmen_homescreen.dart` و `CraftsmanRequests_Screen.dart`
*   **موجود فيه إيه؟** `ListView` بيجيب الطلبات اللي حالتها `Pending` المبعوتة للحرفي ده. كل طلب جنبه زرارين (قبول ✔️ - رفض ❌).
*   **ليه موجود؟** عشان الحرفي يقدر يشوف شغله. لما بيدوس قبول، التطبيق بيبعت `PUT` ريكويست للـ API يغير الـ `status` لـ `Accepted`، والطلب يتنقل لشاشة جدول المواعيد (Bookings).

### 11. `CraftsmanBookings_Screen.dart` و `UserBookings_Screen.dart`
*   **موجود فيه إيه؟** لستة بالطلبات اللي تم الموافقة عليها أو اكتملت.
*   **ليه موجود؟** عشان العميل أو الحرفي يتابعوا حالة الشغل. بيكلموا endpoints زي `/api/bookings/user/:id` عشان يعرضوا الداتا.

---

## ⚙️ ثانياً: ملفات الباك إند (Backend - Node.js)

### 1. `server.js` (قلب المشروع)
*   **موجود فيه إيه؟**
    *   **Imports:** استدعاء لمكتبات `express`, `mongoose`, `cors`, `jsonwebtoken`.
    *   **DB Connection:** كود `mongoose.connect()` اللي بيربط بالمونجو أطلس.
    *   **Routes (المسارات):**
        *   `/api/auth/login`: بتاخد الإيميل والباسورد، تدور في المونجو بـ `findOne`، تقارن الباسورد بـ `bcrypt.compare`، وترجع `Token`.
        *   `/api/craftsmen`: بتاخد Queries (زي المدينة أو الحرفة) وتبعتهم في `Craftsman.find(query)` عشان ترجع لستة مفلترة للعميل.
        *   `/api/bookings`: بتاخد الداتا وتعمل `new Booking(data).save()` عشان تسجل طلب جديد.
        *   `/api/admin/stats`: بتعمل `countDocuments` عشان تعد كام عميل وكام حرفي وكام طلب، وتجمع الأرباح بـ `aggregate` وترجعهم للإدمن داشبورد.

### 2. مجلد الـ Models (`User.js`, `Craftsman.js`, `Booking.js`)
*   **موجود فيهم إيه؟** كل ملف جواه `new mongoose.Schema({...})`.
    *   في الـ **User** بنكتب إن النيم `String` ومطلوب `required: true`.
    *   في الـ **Booking** بنعمل ريفرنس لليوزر والحرفي `type: mongoose.Schema.Types.ObjectId, ref: 'User'`.
*   **ليه موجودين؟** دول اللي بيعرفوا شكل الداتا جوه الـ MongoDB عشان المونجو ميقبلش أي داتا عشوائية، لازم تكون ماشية على المخطط (Schema) ده عشان يحافظ على جودة الداتا وميحصلش كراش.

### 3. `.env`
*   **موجود فيه إيه؟** `PORT=5000` و `MONGODB_URI=...` و `JWT_SECRET`.
*   **ليه موجود؟** حماية للبيانات. عشان لو رفعنا الكود على GitHub، محدش يسرق باسورد الداتابيز. السيرفر بيقرأ من الفايل ده وقت التشغيل بس عن طريق `process.env`.
