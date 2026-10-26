# FoodLink

FoodLink connects food donors with approved welfare centres.

## Features

- Speak food names while creating a donation or searching donations.
- Require donors to confirm freshness, safe storage, and the expiry date.
- Register welfare centres with a PDF or image of their registration certificate.
- Show approved welfare centres within 25 km, ranked by the donor's location.
- Restrict welfare dashboards to administrator-approved centres.
- Provide an administrator review queue for centre applications.
- Offer an in-app FAQ assistant and a call action on donation details.

Voice recognition uses the device speech-recognition service. The help assistant uses local FAQ responses and does not require an AI API key
or send chat messages to a remote service. **Call Support** asks for a phone
number because no support line was configured; enter the complete number with
country code to open the device dialer.

## Firebase setup

The app uses Firebase Authentication, Cloud Firestore, and Firebase Storage.
Deploy the included Firestore and Storage rules before testing centre
registration, verification, or donation updates:

```powershell
firebase use <your-firebase-project-id>
firebase deploy --only firestore:rules,storage
```

The administrator is allowlisted as `mustafa79996@gmail.com` in
`lib/utils/admin_config.dart`, `firestore.rules`, and `storage.rules`. Sign in
with that verified Firebase Authentication account and open **Profile → Welfare
centre applications** to review certificates. Keep the three allowlist values
in sync if the administrator address changes.

Welfare centres apply from the **Welfare Centre** button and can sign in to the
welfare dashboard only after approval. Certificate images are stored privately
in Firebase Storage; the included rules limit uploads to 10 MB.

## Run

```powershell
flutter pub get
flutter run
```
