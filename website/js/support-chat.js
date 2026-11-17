/**
 * FoodLink AI Support Chat Responder & Web Speech Dictation
 * Mirrors lib/utils/support_chat_responder.dart and lib/utils/voice_input.dart
 */

const SUPPORT_SUGGESTED_QUESTIONS = [
  { label: '🍲 Donate food', prompt: 'How do I donate food?' },
  { label: '🛡️ Safety checklist', prompt: 'What food safety checks are required?' },
  { label: '🏢 Find a centre', prompt: 'I cannot find nearby welfare centres' },
  { label: '📄 Certificate upload', prompt: 'My welfare centre certificate upload failed' },
  { label: '⏳ Application status', prompt: 'How does centre verification work?' },
  { label: '🎙️ Voice dictation', prompt: 'How does voice input work?' }
];

function getChatBotReply(message) {
  const text = (message || '').toLowerCase();

  const matches = (pattern) => new RegExp(pattern, 'i').test(text);

  const mentionsCertificate = matches('\\b(certificate|upload|registration document|image)\\b');
  const mentionsCentre = matches('\\b(welfare|centre|center|application|verification|verified)\\b');

  if (matches('\\b(microphone|voice|speech|speak|mic|dictat)\\b')) {
    return 'Tap the microphone icon beside any text box or chat input, allow microphone access in your browser, and speak clearly. The speech-to-text engine will transcribe your voice in real time!';
  }

  if (matches('\\b(permission[\\s-]?denied|access denied|not authorized|unauthorized)\\b')) {
    if (mentionsCertificate || matches('\\b(submit|register)\\b')) {
      return "The centre account was registered, but certificate upload encountered a storage rule. Ensure your document is a JPG, PNG, WEBP, or PDF under 10 MB. If permission-denied continues, please verify you are signed in or contact FoodLink administrator at mustafa79996@gmail.com.";
    }
    return 'The nearby centres directory displays approved centres and does not require sign-in. If you experience an access issue, refresh your browser or check your network connectivity.';
  }

  if (matches('\\b(search|find|available|browse|nearby)\\b') && matches('\\b(welfare|centre|center)\\b')) {
    return 'Navigate to the "Welfare Centers" tab and click "Detect My Location". The directory is dynamically sorted by real distance in kilometers and shows certified local food relief centres within 25 km. You can also directly call centres or view directions on Google Maps!';
  }

  if (matches('\\b(safe|safety|fresh|expiry|expired|store|storage|spoiled|quality)\\w*\\b')) {
    return 'Only donate fresh, safe, and hygienically stored food. Confirm the expiry date is valid before posting. All donors must confirm the 4-point Food Safety Checklist (Freshness, Storage condition, Food-grade packaging, and Valid consumption window). Spoiled or contaminated food is strictly prohibited.';
  }

  if (mentionsCertificate) {
    return 'For welfare centre verification, upload a clean, legible JPG, PNG, WEBP, or PDF copy of your government NGO / Society registration certificate (under 10 MB). The FoodLink administrator (mustafa79996@gmail.com) reviews submissions within 24 hours.';
  }

  if (matches('\\b(donat|donation|give food|post food|share meal)\\w*\\b')) {
    return 'Click on the "Donate Food" tab, enter the food name, quantity (servings), expiry window, pickup address, and donor contact number. Check all 4 safety criteria and click "Post Food Donation". Welfare centres in your vicinity will be notified instantly!';
  }

  if (mentionsCentre) {
    if (matches('\\b(status|approved|pending|how long|review)\\b')) {
      return 'Centre applications remain in Pending status until the administrator reviews the NGO credentials. Once approved, the centre gains full access to claim incoming food donations and perform quality audits in the Welfare Portal.';
    }
    return 'To register your NGO or welfare organisation, go to the Welfare Portal -> "Register New Welfare Centre", fill out the organisation details and attach your registration certificate.';
  }

  if (matches('\\b(search|find|available|browse|list|feed)\\b')) {
    return 'Head over to "Browse Donations" to explore live community food listings. You can filter by category (Meals, Vegetables, Fruits, Grains, Snacks, Beverages) or by status (Pending, Accepted, Rejected), or toggle "My Donations" to see your personal history.';
  }

  if (matches('\\b(account|sign in|login|password|email|register)\\b')) {
    return 'Click the "Sign In" button in the top navigation bar. You can sign in with your email or use the One-Click Demo profiles (Donor, Welfare Staff, or Welfare Administrator mustafa79996@gmail.com).';
  }

  return 'I am the FoodLink AI Assistant. I can guide you through donating surplus food, food safety guidelines, finding verified welfare centres, NGO certificate verification, and voice dictation. How can I help you today?';
}

/**
 * Web Speech Recognition helper for any input element or button
 */
function initSpeechRecognition(targetInputId, micButtonId, onResultCallback) {
  const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  const micBtn = document.getElementById(micButtonId);
  const inputEl = document.getElementById(targetInputId);

  if (!micBtn || !inputEl) return;

  if (!SpeechRecognition) {
    micBtn.title = 'Speech recognition is not supported in this browser. Please use Chrome/Edge.';
    micBtn.classList.add('disabled-mic');
    return;
  }

  const recognition = new SpeechRecognition();
  recognition.continuous = false;
  recognition.interimResults = false;
  recognition.lang = 'en-US';

  let isListening = false;

  micBtn.addEventListener('click', (e) => {
    e.preventDefault();
    if (isListening) {
      recognition.stop();
      return;
    }

    try {
      recognition.start();
      isListening = true;
      micBtn.classList.add('mic-active');
      micBtn.setAttribute('aria-pressed', 'true');
    } catch (err) {
      console.warn('Speech start error:', err);
    }
  });

  recognition.onresult = (event) => {
    const transcript = event.results[0][0].transcript;
    inputEl.value = (inputEl.value ? inputEl.value + ' ' : '') + transcript;
    inputEl.dispatchEvent(new Event('input', { bubbles: true }));
    if (onResultCallback) onResultCallback(transcript);
  };

  recognition.onerror = (event) => {
    console.warn('Speech recognition error:', event.error);
    isListening = false;
    micBtn.classList.remove('mic-active');
  };

  recognition.onend = () => {
    isListening = false;
    micBtn.classList.remove('mic-active');
  };
}
