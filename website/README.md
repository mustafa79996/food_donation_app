# FoodLink Web Application 🍲🌱

A standalone responsive web application matching the **FoodLink** mobile application. It allows food donors (restaurants, catering services, event organizers, and households) to post surplus food donations, and enables verified welfare centres to claim donations, perform food freshness & quality inspections, and distribute meals to those in need.

> **Note on App Integrity:** The Flutter mobile application files (`lib/`, `android/`, `ios/`, etc.) remain completely untouched. This website lives independently in the `website/` directory and connects to the same Firebase project (`food-donation-app-9540f`).

---

## 🌟 Key Features

1. **Surplus Food Donation (`#donate`)**:
   - Food name input with **🎙️ Speech-to-Text Voice Dictation** (Web Speech API).
   - Category selection with badges (Meals, Vegetables, Fruits, Grains, Snacks, Beverages, Other).
   - Servings counter & expiry datetime selector.
   - **📍 Geolocation pickup auto-fill** and manual address input.
   - **Mandatory 4-Point Food Safety Guarantee Checklist**:
     - Freshness and wholesome preparation
     - Safe temperature storage
     - Clean, food-grade packaging
     - Accurate expiration window
   - Image upload or curated high-resolution category food photo presets.
   - Real-time Firestore document creation (`donations` collection).

2. **Real-Time Donations Feed (`#donations`)**:
   - Search by food item, category, donor, or address.
   - Filter by Category and Status (Pending Review, Accepted, Declined).
   - Scope switch: **"All Donations"** vs **"My Donations"**.
   - Live status metrics (Total, Pending, Accepted, Declined counts).
   - Comprehensive detail modal with Google Maps directions link and donor direct phone call (`tel:...`).

3. **Nearest Welfare Centres Directory (`#centers`)**:
   - **📍 Geolocation Distance Calculation** in real time (Haversine formula in km).
   - Filters by radius (5 km, 15 km, 25 km, or all centres).
   - Direct call button and Google Maps navigation.
   - "Donate to this Centre" shortcut button.

4. **Welfare Organisation Portal & Dashboard (`#welfare`)**:
   - **Live Feed of Available Food** for welfare review.
   - One-click **"Accept Donation"** or **"Decline"**.
   - **🌟 Food Freshness & Quality Checklist Audit Modal**:
     - Aroma, temperature & appearance confirmation.
     - Sanitary inspection standard approval.
     - Packaging intact verification.
     - Inspector notes saving directly to the donation record (`welfareChecklist`).
   - **Centre Registration Form** with registration certificate attachment.
   - **🔐 Admin Verification Portal** for `mustafa79996@gmail.com` to review and approve/reject pending NGO applications.

5. **AI Support Assistant & Voice Chat (`#support`)**:
   - Conversational AI matching `SupportChatResponder`.
   - Answers questions on food safety, certificate upload issues, finding centres, application status, and voice dictation.
   - Quick prompt pills and microphone voice input.

6. **Notification Center (`🔔`)**:
   - Role-separated notifications: **"Donor Updates"** vs **"Welfare Alerts"**.
   - Real-time syncing with Firestore `notifications` collection.
   - Mark as read, mark all read, and unread indicator dot.

7. **Design System & Aesthetics**:
   - Color palette matching the mobile app:
     - Forest Green: `#0F5132` / `#135D39`
     - Brand Mint Green: `#86EFAC` / `#15803D`
     - Royal Purple for Welfare & Profile: `#5B4DDF` / `#EDE9FE`
     - Amber Orange: `#D97706` / `#FEF3C7`
   - Organic curved wave hero header SVG.
   - Mobile bottom navigation bar + desktop top navigation bar.

---

## 🚀 How to Run the Website

### Option 1: Open Directly in Any Web Browser
Simply double-click or open `website/index.html` in Chrome, Edge, Brave, Firefox, or Safari!

### Option 2: Run with Node.js
From the `website/` folder:
```bash
cd website
npm start
```
Then visit `http://localhost:5000` in your browser.

### Option 3: Run with Python HTTP Server
```bash
cd website
python -m http.server 8080
```
Then visit `http://localhost:8080` in your browser.

---

## 🔗 Firebase Configuration

The website is pre-configured with the exact same credentials as the Flutter mobile app:
- **Project ID:** `food-donation-app-9540f`
- **Firestore Collections:** `donations`, `notifications`, `public_welfare_centres`, `welfare_centres`, `mail`
- **Storage Bucket:** `food-donation-app-9540f.firebasestorage.app`
- **Admin Email:** `mustafa79996@gmail.com`

It includes automatic local state caching and offline fallback, ensuring zero crashes even when testing without internet.
