class SupportChatResponder {
  static const String agentName = 'Mia';
  static const String agentTitle = 'FoodLink Live Support Agent';

  static const suggestedQuestions = <({String label, String prompt})>[
    (label: 'Donate food', prompt: 'How do I donate food?'),
    (
      label: 'Certificate upload',
      prompt: 'My welfare centre certificate upload failed',
    ),
    (label: 'Find a centre', prompt: 'I cannot find nearby welfare centres'),
    (label: 'Application status', prompt: 'How does centre verification work?'),
    (label: 'Food safety', prompt: 'What are the food safety guidelines?'),
    (label: 'Who is Mia?', prompt: 'Who are you and how can you help me?'),
    (label: 'Call support', prompt: 'How do I call live support?'),
    (label: 'Accepted food', prompt: 'What types of food can I donate?'),
  ];

  static String replyTo(String message) {
    final text = message.trim().toLowerCase();
    if (text.isEmpty) {
      return "Hi there! I'm Mia, your FoodLink live support agent. How can I help you today?";
    }

    // 1. Identity & Persona ("Who are you?", "What is your name?", "Mia")
    if (_matches(
      text,
      r"\b(who are you|your name|what is your name|what's your name|who am i (talking|speaking) (to|with)|are you mia|is this mia|who is mia|are you a bot|are you real|are you live|are you an ai|who created you|introduce yourself)\b",
    )) {
      return "I'm Mia, your dedicated live support agent at FoodLink! 😊 I'm here in real-time to assist you with donating food, finding nearby welfare centres, checking application status, resolving upload errors, and understanding food safety. How can I help you today?";
    }

    // 2. Greetings & Pleasantries
    if (_matches(
      text,
      r"^(hi|hello|hey|good\s*(morning|afternoon|evening|day)|greetings|howdy|namaste|hola|hiya)[\s!.,?]*$",
    )) {
      return "Hello! 👋 I'm Mia, your FoodLink live support agent. How are you doing today? What question can I help you with?";
    }

    // 3. Courtesy & Well-being
    if (_matches(
      text,
      r"\b(how are you|how's it going|how are things|how do you do|what's up)\b",
    )) {
      return "I'm doing great, thank you for asking! 😊 I'm right here and ready to help you with anything on FoodLink. How can I assist you right now?";
    }

    // 4. Appreciation / Gratitude
    if (_matches(
      text,
      r"\b(thank you|thanks|thx|appreciate it|thank u|great job|you're awesome|you are awesome|you're helpful|you are helpful)\b",
    )) {
      return "You're very welcome! ❤️ It's my absolute pleasure to help. If you have any other questions or need further assistance, please don't hesitate to ask!";
    }

    // 5. Farewells
    if (_matches(
      text,
      r"\b(bye|goodbye|see you|take care|have a good day|good night)\b",
    )) {
      return "Goodbye! Thank you for supporting the FoodLink mission to eradicate food hunger and reduce waste. Have a wonderful day, and reach out anytime you need assistance!";
    }

    // 6. Microphone & Voice Input
    if (_matches(text, r"\b(microphone|voice|speech|speak|mic)\b")) {
      return 'Tap the microphone beside the message box, allow microphone access, and speak clearly. You can review or edit the recognized text before sending it.';
    }

    // 7. Fees, Costs & Free platform
    if (_matches(text, r"\b(fee|fees|cost|costs|charge|charges|free|money|pay|payment)\b")) {
      return 'FoodLink is 100% free! There are never any fees or charges for donors or welfare centres. Our mission is pure community food sharing to eliminate hunger.';
    }

    final mentionsCertificate = _matches(
      text,
      r"\b(certificate|upload|registration document|image)\b",
    );
    final mentionsCentre = _matches(
      text,
      r"\b(welfare|centre|center|centres|centers|application|verification|verified)\b",
    );

    // 7. Permission-denied errors
    if (_matches(
      text,
      r"\b(permission[\s-]?denied|access denied|not authorized|unauthorized)\b",
    )) {
      if (mentionsCertificate || _matches(text, r"\b(submit|register)\b")) {
        return "The screenshot indicates the centre account was created, but saving its certificate was denied. Do not create another account: retry the application with the same email and a JPG, PNG, WEBP, or HEIC image no larger than 10 MB. If permission-denied continues, ask the FoodLink administrator to check that the Firebase Storage rules are deployed to the app's Firebase project and that you are signed in to the same centre account. The app should not make certificate uploads public.";
      }
      return 'The nearby-centres screen can show approved centres only and does not require sign-in. Refresh the list. If it still says permission-denied, ask the FoodLink administrator to deploy the Firestore rules to the same Firebase project used by the app; only approved public centre details should be readable.';
    }

    // 8. Finding Nearby Welfare Centres
    if (_matches(
          text,
          r"\b(search|find|available|browse|nearby|near me|nearest|locate|location|map|maps|distance)\b",
        ) &&
        (mentionsCentre || _matches(text, r"\b(charity|shelter|orphanage)\b"))) {
      return 'Open Nearest Welfare Centers and allow location access. The list is sorted by distance and includes approved centres with a saved location within 25 km. If no centres appear, try Maps or search again from another location.';
    }

    // 9. Safety, Freshness, Expiry & Spoiled Food
    if (_matches(
      text,
      r"\b(safe|safety|fresh|freshness|expiry|expired|store|storage|spoiled|stale|temperature|hygiene|clean)\w*\b",
    )) {
      return 'Only donate fresh food that has been stored safely. Confirm the expiry date is correct before posting. Do not post spoiled or expired food; check the safety checklist before submitting.';
    }

    // 10. Certificate Inquiries
    if (mentionsCertificate) {
      return 'For a centre application, upload a clear JPG, PNG, WEBP, or HEIC image up to 10 MB. If the account was already created, continue with the same email rather than registering again. A permission-denied error needs the FoodLink administrator to check the Firebase Storage rules and project configuration.';
    }

    // 11. Donation Specific Inquiries
    if (_matches(text, r"\b(donat|donation|give food|post food|share food)\w*\b")) {
      if (_matches(text, r"\b(cooked|meals?|rice|curry|prepared|dishes)\b")) {
        return 'Yes, cooked food can be donated! Open Donate and add the food details, quantity, expiry date, contact number, and a photo. Confirm the food is fresh, prepared within safe hygiene standards, kept at safe temperatures, and properly packaged before posting.';
      }
      if (_matches(text, r"\b(cancel|delete|edit|change|remove|update)\b")) {
        return "To edit or cancel a donation, go to your Profile and select 'My Donations' (or open the Donations tab). Select the listing to review its status or remove it if it is no longer available.";
      }
      if (_matches(text, r"\b(pickup|collect|deliver|transport|courier)\b")) {
        return "When a registered welfare centre accepts your donation, their staff or volunteer drivers will coordinate pickup directly from your address. You can also view their contact details on the accepted donation card.";
      }
      if (_matches(text, r"\b(fee|cost|charge|free|money|pay|payment)\b")) {
        return 'FoodLink is 100% free! There are never any fees or charges for donors or welfare centres. Our mission is pure community food sharing to eliminate hunger.';
      }
      if (_matches(text, r"\b(how much|quantity|limit|minimum|maximum)\b")) {
        return 'There is no minimum or maximum limit! Whether you have 3 meal boxes from home or 200 meals from a restaurant or wedding catering, every donation feeds someone in need.';
      }
      return 'Open Donate and add the food details, quantity, expiry date, contact number, and a photo. Confirm the food is fresh, has been stored safely, and that the expiry date is correct before posting.';
    }

    // 12. Welfare Centre Inquiries
    if (mentionsCentre) {
      if (_matches(text, r"\b(status|approved|pending|how long|review|track)\b")) {
        return 'Centre applications stay pending until an administrator reviews the registration certificate. You can sign in with the application email to continue an incomplete submission; donation requests are available to the centre after approval.';
      }
      if (_matches(text, r"\b(reject|rejected|denied|declined)\b")) {
        return 'If a centre application is rejected, it usually means the registration certificate was blurry, expired, or incomplete. You can sign in with your email to upload a valid document or contact support.';
      }
      if (_matches(text, r"\b(claim|accept|receive|request|get food)\b")) {
        return 'Approved welfare centres can browse available listings in the Donations tab or Welfare Dashboard, inspect the food safety checklist, and tap "Accept Donation" to schedule pickup with the donor.';
      }
      return 'To register a welfare centre, submit its details, contact number, location, and a registration-certificate image. An administrator reviews the application before the centre can access donation requests. Approved centres with a saved location can appear in nearby-centre search.';
    }

    // 13. Searching/Browsing Donations
    if (_matches(text, r"\b(search|find|available|browse|listing|food list)\b")) {
      return 'Open Donations to browse available food. Use the search field to filter by food name or category, and open a listing to see its details.';
    }

    // 14. Accounts, Authentication & Password
    if (_matches(
      text,
      r"\b(account|sign in|login|password|email|sign up|register|forgot)\b",
    )) {
      return 'Use the email registered with your FoodLink account. Welfare-centre applicants should reuse the same email to finish an incomplete application; if sign-in still fails, use the app’s account recovery options or contact FoodLink support.';
    }

    // 15. Calling Support / Live Agent Helpline / Escalation
    if (_matches(
      text,
      r"\b(call|phone|contact|number|helpline|human|operator|dial|customer care|speak to someone|talk to someone|admin email)\b",
    )) {
      return 'You can call our live support team directly by tapping the phone icon at the top right of this screen, or dialing +91 98765 43210. You can also email our administration team at admin@foodlink.org or mustafa79996@gmail.com.';
    }

    // 16. Volunteering & Partnerships
    if (_matches(
      text,
      r"\b(volunteer|driver|delivery partner|join|help out|participate)\b",
    )) {
      return 'We warmly welcome volunteers! Volunteers assist by transporting surplus food from donors to shelters and orphanages. Please email us at admin@foodlink.org with your location and availability to join our volunteer network.';
    }

    // 17. Restaurants, Caterers & Event Organizers
    if (_matches(
      text,
      r"\b(restaurant|caterer|catering|hotel|banquet|wedding|party|bulk)\b",
    )) {
      return 'Restaurants, caterers, and party hosts can easily donate bulk surplus food! Simply tap "Donate Food", select the Meals category, specify the number of servings, and upload a photo. Verified welfare centres will be alerted to collect it.';
    }

    // 18. What is FoodLink / About
    if (_matches(
      text,
      r"\b(what is foodlink|about foodlink|foodlink mission|purpose|who created|app)\b",
    )) {
      return 'FoodLink is a modern food donation and distribution platform connecting compassionate donors with verified welfare centres, shelters, and orphanages. Our mission is to eliminate food waste and fight hunger in our communities.';
    }

    // 19. Specific Food Items (Fruits, Vegetables, Bread, Milk, Rice, etc.)
    if (_matches(
      text,
      r"\b(fruit|vegetable|produce|bread|bakery|milk|dairy|rice|grain|canned|raw|meat|curry|sweet)\w*\b",
    )) {
      return 'We accept cooked meals, fresh fruits and vegetables, bakery items, grains, dairy, and sealed packaged or canned goods. All items must be fresh, wholesome, hygienically stored, and well within their expiration date.';
    }

    // 20. Packaging & Storage Questions
    if (_matches(
      text,
      r"\b(pack|package|packaging|container|box|plastic|foil|tray|seal|wrap)\w*\b",
    )) {
      return 'Please pack food in clean, food-grade, leak-proof containers (such as foil trays, airtight food containers, or sealed bags). Labeling the container with the preparation date and time is highly recommended!';
    }

    // 21. Timings & Night donations
    if (_matches(
      text,
      r"\b(night|late|time|timing|hours|schedule|weekend|sunday)\b",
    )) {
      return 'You can post donations on FoodLink 24/7! Most welfare centres coordinate pickups during daytime and evening hours (before 9:00 PM). If you have late-night event food, post it immediately with clear expiry details so night shelters can respond.';
    }

    // 22. General Intelligent Live Agent Fallback (Answering Any Other Question)
    return _generateIntelligentAnswer(text);
  }

  static String _generateIntelligentAnswer(String text) {
    if (_matches(text, r"\b(how|what|why|where|when|who|can i|is it|do i|should i)\b")) {
      return "That's a great question! As your FoodLink live support agent, Mia is here to help you make the most of our platform. I can assist you with donating food, checking welfare applications, inspecting food safety guidelines, finding nearby centres, or contacting our admin. Could you provide a bit more detail, or choose one of the suggested topics below?";
    }

    return "Hi, I'm Mia, your FoodLink live support agent! I can help you with anything regarding donating food, safety checks, nearby welfare centres, verification certificates, and technical help. Choose a topic below or let me know what questions you have!";
  }

  static bool _matches(String text, String pattern) {
    return RegExp(pattern, caseSensitive: false).hasMatch(text);
  }
}
