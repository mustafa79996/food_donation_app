class SupportChatResponder {
  static const suggestedQuestions = <({String label, String prompt})>[
    (label: 'Donate food', prompt: 'How do I donate food?'),
    (
      label: 'Certificate upload',
      prompt: 'My welfare centre certificate upload failed',
    ),
    (label: 'Find a centre', prompt: 'I cannot find nearby welfare centres'),
    (label: 'Application status', prompt: 'How does centre verification work?'),
  ];

  static String replyTo(String message) {
    final text = message.toLowerCase();
    final mentionsCertificate = _matches(
      text,
      r'\b(certificate|upload|registration document|image)\b',
    );
    final mentionsCentre = _matches(
      text,
      r'\b(welfare|centre|center|application|verification|verified)\b',
    );

    if (_matches(text, r'\b(microphone|voice|speech|speak|mic)\b')) {
      return 'Tap the microphone beside the message box, allow microphone access, and speak clearly. You can review or edit the recognized text before sending it.';
    }

    if (_matches(
      text,
      r'\b(permission[\s-]?denied|access denied|not authorized|unauthorized)\b',
    )) {
      if (mentionsCertificate || _matches(text, r'\b(submit|register)\b')) {
        return "The screenshot indicates the centre account was created, but saving its certificate was denied. Do not create another account: retry the application with the same email and a JPG, PNG, WEBP, or HEIC image no larger than 10 MB. If permission-denied continues, ask the FoodLink administrator to check that the Firebase Storage rules are deployed to the app's Firebase project and that you are signed in to the same centre account. The app should not make certificate uploads public.";
      }
      return 'The nearby-centres screen can show approved centres only and does not require sign-in. Refresh the list. If it still says permission-denied, ask the FoodLink administrator to deploy the Firestore rules to the same Firebase project used by the app; only approved public centre details should be readable.';
    }

    if (_matches(text, r'\b(search|find|available|browse|nearby)\b') &&
        _matches(text, r'\b(welfare|centre|center)\b')) {
      return 'Open Nearest Welfare Centers and allow location access. The list is sorted by distance and includes approved centres with a saved location within 25 km. If no centres appear, try Maps or search again from another location.';
    }

    if (_matches(
      text,
      r'\b(safe|safety|fresh|expiry|expired|store|storage|spoiled)\w*\b',
    )) {
      return 'Only donate fresh food that has been stored safely. Confirm the expiry date is correct before posting. Do not post spoiled or expired food; check the safety checklist before submitting.';
    }

    if (mentionsCertificate) {
      return 'For a centre application, upload a clear JPG, PNG, WEBP, or HEIC image up to 10 MB. If the account was already created, continue with the same email rather than registering again. A permission-denied error needs the FoodLink administrator to check the Firebase Storage rules and project configuration.';
    }

    if (_matches(text, r'\b(donat|donation|give food|post food)\w*\b')) {
      return 'Open Donate and add the food details, quantity, expiry date, contact number, and a photo. Confirm the food is fresh, has been stored safely, and that the expiry date is correct before posting.';
    }

    if (mentionsCentre) {
      if (_matches(text, r'\b(status|approved|pending|how long|review)\b')) {
        return 'Centre applications stay pending until an administrator reviews the registration certificate. You can sign in with the application email to continue an incomplete submission; donation requests are available to the centre after approval.';
      }
      return 'To register a welfare centre, submit its details, contact number, location, and a registration-certificate image. An administrator reviews the application before the centre can access donation requests. Approved centres with a saved location can appear in nearby-centre search.';
    }

    if (_matches(text, r'\b(search|find|available|browse|nearby)\b')) {
      return 'Open Donations to browse available food. Use the search field to filter by food name or category, and open a listing to see its details.';
    }

    if (_matches(text, r'\b(account|sign in|login|password|email)\b')) {
      return 'Use the email registered with your FoodLink account. Welfare-centre applicants should reuse the same email to finish an incomplete application; if sign-in still fails, use the app’s account recovery options or contact FoodLink support.';
    }

    return 'I can guide you through donating food, food-safety checks, finding donations or welfare centres, centre verification, certificate-upload errors, and voice input. Choose a topic below or tell me what screen and error you see.';
  }

  static bool _matches(String text, String pattern) {
    return RegExp(pattern).hasMatch(text);
  }
}
