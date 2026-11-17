/**
 * FoodLink Web Application Controller
 * Handles SPA navigation, UI rendering, interaction handlers, and real-time syncing.
 */

// Application State
const appState = {
  currentTab: 'donations',
  categoryFilter: 'All',
  statusFilter: 'All',
  scopeFilter: 'All', // 'All' or 'My Donations'
  searchQuery: '',
  centersRadius: '25',
  centersSearchQuery: '',
  userLocation: null,
  activeDetailDonation: null,
  activeQualityInspectionDonation: null,
  notificationsFilterRole: 'all'
};

document.addEventListener('DOMContentLoaded', () => {
  initNavigation();
  initAuthUI();
  initDonationForm();
  initDonationsView();
  initNearestCentersView();
  initWelfarePortal();
  initSupportChatView();
  initNotificationsModal();
  initVoiceInputSupport();

  // Listen to service updates
  window.foodLinkService.on('donations', () => {
    renderDonationsGrid();
    renderWelfareDonationsFeed();
  });

  window.foodLinkService.on('notifications', () => {
    updateNotificationBadge();
    renderNotificationsList();
  });

  window.foodLinkService.on('auth', (user) => {
    updateUserNavUI(user);
    renderDonationsGrid();
    renderWelfareDonationsFeed();
  });

  // Initial render
  renderDonationsGrid();
  renderNearestCentersList();
  renderWelfareDonationsFeed();
  renderWelfareApplicationsList();
  updateNotificationBadge();
  updateUserNavUI(window.foodLinkService.currentUser);
});

// ================= Navigation & Router =================
function initNavigation() {
  const navLinks = document.querySelectorAll('.nav-link, .mobile-nav-btn');
  navLinks.forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();
      const tabTarget = link.getAttribute('data-tab');
      if (tabTarget) switchTab(tabTarget);
    });
  });

  // Handle hash changes if any
  window.addEventListener('hashchange', () => {
    const hash = window.location.hash.replace('#', '');
    if (hash && document.getElementById(`tab-${hash}`)) {
      switchTab(hash);
    }
  });

  if (window.location.hash) {
    const initialHash = window.location.hash.replace('#', '');
    if (document.getElementById(`tab-${initialHash}`)) {
      switchTab(initialHash);
    }
  }
}

function switchTab(tabId) {
  appState.currentTab = tabId;

  // Update tabs active state
  document.querySelectorAll('.tab-pane').forEach(el => el.classList.remove('active'));
  const targetPane = document.getElementById(`tab-${tabId}`);
  if (targetPane) targetPane.classList.add('active');

  // Update nav link styles
  document.querySelectorAll('.nav-link, .mobile-nav-btn').forEach(link => {
    if (link.getAttribute('data-tab') === tabId) {
      link.classList.add('active');
    } else {
      link.classList.remove('active');
    }
  });

  // Adjust hero wave banner style based on tab
  const heroBanner = document.querySelector('.hero-wave-container');
  if (heroBanner) {
    if (tabId === 'welfare' || tabId === 'profile') {
      heroBanner.classList.add('purple-theme');
    } else {
      heroBanner.classList.remove('purple-theme');
    }
  }

  // Auto scroll to top of view
  window.scrollTo({ top: 0, behavior: 'smooth' });

  // Update URL hash without reload
  history.replaceState(null, null, `#${tabId}`);
}

// ================= User & Auth UI =================
function initAuthUI() {
  const userBtn = document.getElementById('user-profile-btn');
  const authModal = document.getElementById('auth-modal');
  const closeAuthBtn = document.getElementById('close-auth-modal-btn');
  const authForm = document.getElementById('auth-form');

  if (userBtn) {
    userBtn.addEventListener('click', () => {
      authModal.classList.add('open');
    });
  }

  if (closeAuthBtn) {
    closeAuthBtn.addEventListener('click', () => {
      authModal.classList.remove('open');
    });
  }

  // Demo user quick login buttons
  document.querySelectorAll('.demo-login-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const role = btn.getAttribute('data-role');
      window.foodLinkService.setDemoRole(role);
      authModal.classList.remove('open');
      showToast(`Signed in as ${window.foodLinkService.currentUser.displayName} (${role.toUpperCase()})`);
      if (role === 'admin' || role === 'welfare') {
        switchTab('welfare');
      }
    });
  });

  if (authForm) {
    authForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const email = document.getElementById('auth-email').value;
      const pass = document.getElementById('auth-password').value;
      await window.foodLinkService.signIn(email, pass);
      authModal.classList.remove('open');
      showToast('Signed in successfully!');
    });
  }
}

function updateUserNavUI(user) {
  const userBtnText = document.getElementById('user-pill-name');
  const userRoleBadge = document.getElementById('user-role-badge');
  const userAvatar = document.querySelector('.user-avatar-circle');

  if (user) {
    if (userBtnText) userBtnText.textContent = user.displayName || user.email.split('@')[0];
    if (userRoleBadge) {
      userRoleBadge.textContent = user.isWelfareAdmin ? 'Admin' : (user.role === 'welfare' ? 'Welfare' : 'Donor');
    }
    if (userAvatar) userAvatar.textContent = (user.displayName || user.email)[0].toUpperCase();
  } else {
    if (userBtnText) userBtnText.textContent = 'Sign In';
    if (userRoleBadge) userRoleBadge.textContent = 'Guest';
    if (userAvatar) userAvatar.textContent = 'G';
  }

  // Also update Profile Tab view
  renderProfileScreen();
}

// ================= Donate Food Form =================
function initDonationForm() {
  const form = document.getElementById('donate-food-form');
  const expiryInput = document.getElementById('donate-expiry');
  const categoryChips = document.querySelectorAll('.donate-cat-chip');
  const imagePresetButtons = document.querySelectorAll('.image-preset-btn');
  const imagePreview = document.getElementById('donate-image-preview');
  const imageInput = document.getElementById('donate-custom-image-file');

  // Set default expiry date (+2 days formatted)
  if (expiryInput) {
    const d = new Date(Date.now() + 48 * 3600 * 1000);
    expiryInput.value = d.toISOString().slice(0, 16);
  }

  // Category chip selection
  categoryChips.forEach(chip => {
    chip.addEventListener('click', () => {
      categoryChips.forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      const cat = chip.getAttribute('data-category');
      document.getElementById('donate-category-val').value = cat;

      // Update image preview to match category default if no custom image selected
      if (!imageInput.files || imageInput.files.length === 0) {
        if (CATEGORY_DEFAULT_IMAGES[cat]) {
          imagePreview.src = CATEGORY_DEFAULT_IMAGES[cat];
        }
      }
    });
  });

  // Image Presets
  imagePresetButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const url = btn.getAttribute('data-img-url');
      if (url && imagePreview) {
        imagePreview.src = url;
        document.getElementById('donate-image-url-val').value = url;
      }
    });
  });

  // Custom Image Upload
  if (imageInput) {
    imageInput.addEventListener('change', (e) => {
      const file = e.target.files[0];
      if (file) {
        const reader = new FileReader();
        reader.onload = (event) => {
          imagePreview.src = event.target.result;
          document.getElementById('donate-image-url-val').value = event.target.result;
        };
        reader.readAsDataURL(file);
      }
    });
  }

  // Geolocation auto-fill for pickup address
  const detectAddressBtn = document.getElementById('detect-pickup-location-btn');
  if (detectAddressBtn) {
    detectAddressBtn.addEventListener('click', () => {
      if (navigator.geolocation) {
        detectAddressBtn.textContent = '📍 Locating...';
        navigator.geolocation.getCurrentPosition((pos) => {
          detectAddressBtn.textContent = '📍 Located!';
          const addrInput = document.getElementById('donate-address');
          addrInput.value = `Road No 12, Banjara Hills, Hyderabad (${pos.coords.latitude.toFixed(4)}, ${pos.coords.longitude.toFixed(4)})`;
          setTimeout(() => { detectAddressBtn.textContent = '📍 Use My Location'; }, 3000);
        }, (err) => {
          alert('Could not detect location. Please type your pickup address.');
          detectAddressBtn.textContent = '📍 Use My Location';
        });
      }
    });
  }

  // Form Submit
  if (form) {
    form.addEventListener('submit', async (e) => {
      e.preventDefault();

      // Check 4 food safety checklist items
      const c1 = document.getElementById('safety-fresh').checked;
      const c2 = document.getElementById('safety-stored').checked;
      const c3 = document.getElementById('safety-packed').checked;
      const c4 = document.getElementById('safety-expiry').checked;

      if (!c1 || !c2 || !c3 || !c4) {
        alert('Please confirm all 4 items on the Food Safety Checklist before donating.');
        return;
      }

      const submitBtn = document.getElementById('submit-donation-btn');
      submitBtn.disabled = true;
      submitBtn.textContent = 'Posting Donation...';

      const foodName = document.getElementById('donate-food-name').value.trim();
      const category = document.getElementById('donate-category-val').value || 'Meals';
      const quantity = parseInt(document.getElementById('donate-quantity').value, 10) || 1;
      const pickupAddress = document.getElementById('donate-address').value.trim();
      const contactNumber = document.getElementById('donate-contact').value.trim();
      const expiryDate = document.getElementById('donate-expiry').value;
      const imageUrl = document.getElementById('donate-image-url-val').value || CATEGORY_DEFAULT_IMAGES[category];

      const newRecord = await window.foodLinkService.addDonation({
        foodName,
        category,
        quantity,
        pickupAddress,
        contactNumber,
        expiryDate: new Date(expiryDate).toISOString(),
        imageUrl,
        foodSafetyChecklist: {
          fresh: c1,
          properlyStored: c2,
          properlyPacked: c3,
          expiryDateConfirmed: c4
        }
      });

      submitBtn.disabled = false;
      submitBtn.textContent = 'Post Food Donation';

      // Reset form
      form.reset();
      // Re-check safety boxes
      document.getElementById('safety-fresh').checked = true;
      document.getElementById('safety-stored').checked = true;
      document.getElementById('safety-packed').checked = true;
      document.getElementById('safety-expiry').checked = true;

      showToast(`🎉 Food Donation "${foodName}" posted successfully! Welfare centres notified.`);
      switchTab('donations');
    });
  }
}

// ================= Browse Donations View =================
function initDonationsView() {
  // Category Chips
  document.querySelectorAll('.filter-cat-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      document.querySelectorAll('.filter-cat-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      appState.categoryFilter = chip.getAttribute('data-category');
      renderDonationsGrid();
    });
  });

  // Status Filter Select
  const statusSelect = document.getElementById('donations-status-filter');
  if (statusSelect) {
    statusSelect.addEventListener('change', (e) => {
      appState.statusFilter = e.target.value;
      renderDonationsGrid();
    });
  }

  // Scope Toggle ("All" vs "My Donations")
  document.querySelectorAll('.scope-toggle-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.scope-toggle-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      appState.scopeFilter = btn.getAttribute('data-scope');
      renderDonationsGrid();
    });
  });

  // Search Input
  const searchInput = document.getElementById('donations-search-input');
  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      appState.searchQuery = e.target.value.trim().toLowerCase();
      renderDonationsGrid();
    });
  }
}

function renderDonationsGrid() {
  const grid = document.getElementById('donations-grid-container');
  if (!grid) return;

  const currentUid = window.foodLinkService.currentUser?.uid;
  const currentEmail = window.foodLinkService.currentUser?.email?.toLowerCase();

  // Filter donations
  let list = window.foodLinkService.donations.filter(item => {
    // Scope filter
    if (appState.scopeFilter === 'My Donations') {
      const matchId = item.donorId && item.donorId === currentUid;
      const matchEmail = item.donorEmail && currentEmail && item.donorEmail.toLowerCase() === currentEmail;
      if (!matchId && !matchEmail) return false;
    }

    // Category filter
    if (appState.categoryFilter !== 'All') {
      if (item.category.toLowerCase() !== appState.categoryFilter.toLowerCase()) return false;
    }

    // Status filter
    if (appState.statusFilter !== 'All') {
      const itemStatus = (item.status || 'pending').toLowerCase();
      if (appState.statusFilter === 'pending' && itemStatus !== 'pending') return false;
      if (appState.statusFilter === 'accepted' && itemStatus !== 'accepted' && itemStatus !== 'approved') return false;
      if (appState.statusFilter === 'rejected' && itemStatus !== 'rejected') return false;
    }

    // Search query
    if (appState.searchQuery) {
      const q = appState.searchQuery;
      const matchName = item.foodName.toLowerCase().includes(q);
      const matchAddress = item.pickupAddress.toLowerCase().includes(q);
      const matchDonor = item.donorName.toLowerCase().includes(q);
      const matchCat = item.category.toLowerCase().includes(q);
      if (!matchName && !matchAddress && !matchDonor && !matchCat) return false;
    }

    return true;
  });

  // Update counters
  updateMetricsCounters();

  if (list.length === 0) {
    grid.innerHTML = `
      <div style="grid-column: 1 / -1; text-align: center; padding: 48px 20px; background: white; border-radius: var(--radius-lg); border: 1px solid var(--border-color);">
        <div style="font-size: 3rem; margin-bottom: 12px;">🍲</div>
        <h3 style="font-size: 1.25rem; font-weight: 700; color: var(--text-dark);">No donations match your filter</h3>
        <p style="color: var(--text-muted); margin-top: 6px;">Try adjusting your search criteria or post a surplus food donation!</p>
        <button class="btn btn-primary" style="margin-top: 16px;" onclick="switchTab('donate')">Donate Food Now</button>
      </div>
    `;
    return;
  }

  grid.innerHTML = list.map(item => {
    const status = (item.status || 'pending').toLowerCase();
    let statusClass = 'status-pending';
    let statusLabel = 'Pending Review';
    if (status === 'accepted' || status === 'approved') {
      statusClass = 'status-accepted';
      statusLabel = 'Accepted';
    } else if (status === 'rejected') {
      statusClass = 'status-rejected';
      statusLabel = 'Declined';
    }

    const hasQualityAudit = item.welfareChecklist && item.welfareChecklist.completed;

    return `
      <div class="donation-card" data-id="${item.id}">
        <div class="donation-img-box">
          <img src="${item.imageUrl || CATEGORY_DEFAULT_IMAGES[item.category] || CATEGORY_DEFAULT_IMAGES.Meals}" alt="${item.foodName}" loading="lazy" />
          <span class="donation-card-badge">${item.category}</span>
          <span class="donation-quantity-badge">${item.quantity} Servings</span>
        </div>
        <div class="donation-content">
          <div class="donation-title-row">
            <h4 class="donation-title">${escapeHtml(item.foodName)}</h4>
            <span class="status-pill ${statusClass}">${statusLabel}</span>
          </div>
          
          <div class="donation-meta-item">
            <span>👤</span>
            <span>Donor: <strong>${escapeHtml(item.donorName)}</strong></span>
          </div>

          <div class="donation-meta-item">
            <span>📍</span>
            <span style="overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${escapeHtml(item.pickupAddress)}</span>
          </div>

          <div class="donation-meta-item">
            <span>⏳</span>
            <span>Best Before: ${formatFriendlyDate(item.expiryDate)}</span>
          </div>

          ${hasQualityAudit ? `
            <div style="margin-top: 6px;">
              <span class="verified-quality-badge">✓ Quality & Freshness Verified</span>
            </div>
          ` : ''}

          <div class="donation-footer-row">
            <span style="font-size: 0.76rem; color: var(--text-muted);">${formatRelativeTime(item.createdAt)}</span>
            <button class="btn btn-outline btn-sm view-details-btn" onclick="openDonationDetails('${item.id}')">View Details</button>
          </div>
        </div>
      </div>
    `;
  }).join('');
}

function updateMetricsCounters() {
  const donations = window.foodLinkService.donations;
  const total = donations.length;
  const pending = donations.filter(d => (d.status || '').toLowerCase() === 'pending').length;
  const accepted = donations.filter(d => (d.status || '').toLowerCase() === 'accepted' || (d.status || '').toLowerCase() === 'approved').length;
  const rejected = donations.filter(d => (d.status || '').toLowerCase() === 'rejected').length;

  const tEl = document.getElementById('count-total');
  const pEl = document.getElementById('count-pending');
  const aEl = document.getElementById('count-accepted');
  const rEl = document.getElementById('count-rejected');

  if (tEl) tEl.textContent = total;
  if (pEl) pEl.textContent = pending;
  if (aEl) aEl.textContent = accepted;
  if (rEl) rEl.textContent = rejected;
}

// Donation Detail Modal
function openDonationDetails(donationId) {
  const item = window.foodLinkService.donations.find(d => d.id === donationId);
  if (!item) return;

  const modal = document.getElementById('donation-detail-modal');
  const body = document.getElementById('donation-detail-body');

  const status = (item.status || 'pending').toLowerCase();
  let statusBadge = `<span class="status-pill status-pending">Pending Review</span>`;
  if (status === 'accepted') statusBadge = `<span class="status-pill status-accepted">Accepted by ${escapeHtml(item.updatedBy || 'Welfare Partner')}</span>`;
  if (status === 'rejected') statusBadge = `<span class="status-pill status-rejected">Declined</span>`;

  body.innerHTML = `
    <div style="border-radius: var(--radius-md); overflow: hidden; height: 220px; margin-bottom: 16px;">
      <img src="${item.imageUrl}" style="width: 100%; height: 100%; object-fit: cover;" alt="${item.foodName}" />
    </div>

    <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;">
      <h3 style="font-size: 1.3rem; font-weight: 800;">${escapeHtml(item.foodName)}</h3>
      ${statusBadge}
    </div>

    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 16px; background: var(--background); padding: 14px; border-radius: var(--radius-md);">
      <div>
        <div style="font-size: 0.76rem; color: var(--text-muted);">CATEGORY</div>
        <div style="font-weight: 700;">${item.category}</div>
      </div>
      <div>
        <div style="font-size: 0.76rem; color: var(--text-muted);">QUANTITY</div>
        <div style="font-weight: 700;">${item.quantity} Servings</div>
      </div>
      <div>
        <div style="font-size: 0.76rem; color: var(--text-muted);">DONOR</div>
        <div style="font-weight: 700;">${escapeHtml(item.donorName)}</div>
      </div>
      <div>
        <div style="font-size: 0.76rem; color: var(--text-muted);">EXPIRY WINDOW</div>
        <div style="font-weight: 700;">${formatFriendlyDate(item.expiryDate)}</div>
      </div>
    </div>

    <div style="margin-bottom: 16px;">
      <div style="font-size: 0.84rem; font-weight: 700; margin-bottom: 4px;">📍 Pickup Location:</div>
      <div style="color: var(--text-dark);">${escapeHtml(item.pickupAddress)}</div>
      <a href="https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(item.pickupAddress)}" target="_blank" class="btn btn-outline btn-sm" style="margin-top: 8px;">
        🗺️ Open Directions in Google Maps
      </a>
    </div>

    <div style="margin-bottom: 16px;">
      <div style="font-size: 0.84rem; font-weight: 700; margin-bottom: 4px;">📞 Contact Information:</div>
      <div style="display: flex; align-items: center; gap: 10px;">
        <span style="font-weight: 700; color: var(--primary-green);">${escapeHtml(item.contactNumber || 'Contact not provided')}</span>
        ${item.contactNumber ? `<a href="tel:${item.contactNumber}" class="btn btn-primary btn-sm">Call Donor</a>` : ''}
      </div>
    </div>

    <div class="safety-box" style="margin-top: 14px;">
      <div class="safety-header">🛡️ Donor Food Safety Guarantee Confirmed:</div>
      <div style="font-size: 0.84rem; color: #166534; display: flex; flex-direction: column; gap: 4px;">
        <div>✓ Food is freshly cooked / wholesome</div>
        <div>✓ Stored under hygienic, safe conditions</div>
        <div>✓ Packed in clean food-grade containers</div>
        <div>✓ Expiry period accurately verified</div>
      </div>
    </div>

    ${item.welfareChecklist ? `
      <div style="background: #EFF6FF; border: 1px solid #BFDBFE; border-radius: var(--radius-md); padding: 14px; margin-top: 14px;">
        <div style="color: #1E40AF; font-weight: 700; font-size: 0.9rem; margin-bottom: 6px;">🌟 Welfare Inspection Report:</div>
        <div style="font-size: 0.84rem; color: #1E3A8A;">
          <div>✓ Inspected by: <strong>${escapeHtml(item.welfareChecklist.verifiedBy || 'Staff')}</strong></div>
          <div>✓ Freshness & Hygiene Approved: Yes</div>
          ${item.welfareChecklist.feedbackNotes ? `<div>Notes: "${escapeHtml(item.welfareChecklist.feedbackNotes)}"</div>` : ''}
        </div>
      </div>
    ` : ''}
  `;

  modal.classList.add('open');
}

// ================= Nearest Welfare Centers =================
function initNearestCentersView() {
  const detectBtn = document.getElementById('detect-centers-location-btn');
  const searchInput = document.getElementById('centers-search-input');
  const radiusSelect = document.getElementById('centers-radius-select');

  if (detectBtn) {
    detectBtn.addEventListener('click', () => {
      if (navigator.geolocation) {
        detectBtn.textContent = '📍 Finding GPS location...';
        navigator.geolocation.getCurrentPosition((pos) => {
          appState.userLocation = {
            latitude: pos.coords.latitude,
            longitude: pos.coords.longitude
          };
          detectBtn.textContent = '📍 Location Active (Hyderabad)';
          renderNearestCentersList();
        }, (err) => {
          // Default to central Hyderabad
          appState.userLocation = { latitude: 17.3850, longitude: 78.4867 };
          detectBtn.textContent = '📍 Hyderabad Central (Default)';
          renderNearestCentersList();
        });
      }
    });
  }

  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      appState.centersSearchQuery = e.target.value.trim().toLowerCase();
      renderNearestCentersList();
    });
  }

  if (radiusSelect) {
    radiusSelect.addEventListener('change', (e) => {
      appState.centersRadius = e.target.value;
      renderNearestCentersList();
    });
  }
}

function renderNearestCentersList() {
  const container = document.getElementById('centers-list-container');
  if (!container) return;

  const centers = window.foodLinkService.welfareCentres;
  const userLat = appState.userLocation ? appState.userLocation.latitude : 17.3850;
  const userLng = appState.userLocation ? appState.userLocation.longitude : 78.4867;

  // Compute live distance for each center
  const calculatedList = centers.map(c => {
    const dist = calculateDistanceKm(userLat, userLng, c.latitude, c.longitude);
    return {
      ...c,
      calculatedDistance: dist
    };
  });

  // Filter
  const filtered = calculatedList.filter(c => {
    if (appState.centersRadius !== 'all') {
      const maxKm = parseFloat(appState.centersRadius);
      if (c.calculatedDistance > maxKm) return false;
    }
    if (appState.centersSearchQuery) {
      const q = appState.centersSearchQuery;
      if (!c.name.toLowerCase().includes(q) && !c.address.toLowerCase().includes(q)) return false;
    }
    return true;
  });

  // Sort by nearest distance
  filtered.sort((a, b) => a.calculatedDistance - b.calculatedDistance);

  if (filtered.length === 0) {
    container.innerHTML = `
      <div class="card" style="text-align: center; padding: 40px;">
        <div style="font-size: 2.5rem; margin-bottom: 10px;">🏢</div>
        <h3>No welfare centres found within radius</h3>
        <p style="color: var(--text-muted); margin-top: 6px;">Try expanding your distance radius or search query.</p>
      </div>
    `;
    return;
  }

  container.innerHTML = filtered.map(c => `
    <div class="centre-card">
      <div class="centre-header">
        <div>
          <h4 class="centre-name">${escapeHtml(c.name)}</h4>
          <span style="font-size: 0.78rem; color: #16A34A; font-weight: 700;">✓ Government / FoodLink Approved NGO</span>
        </div>
        <span class="distance-badge">📍 ${c.calculatedDistance.toFixed(1)} km away</span>
      </div>

      <div style="font-size: 0.88rem; color: var(--text-muted);">
        🏢 ${escapeHtml(c.address)}
      </div>

      <div style="font-size: 0.82rem; color: var(--text-muted);">
        📞 Direct Helpline: <strong>${escapeHtml(c.phone)}</strong> • Hours: ${c.operatingHours || '8:00 AM - 9:00 PM'}
      </div>

      <div class="centre-actions">
        <a href="tel:${c.phone}" class="btn btn-primary btn-sm">📞 Call Centre</a>
        <a href="https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(c.name + ' ' + c.address)}" target="_blank" class="btn btn-outline btn-sm">
          🗺️ Open in Google Maps
        </a>
        <button class="btn btn-outline btn-sm" onclick="prefillDonationWithCenter('${escapeHtml(c.name)}')">
          🍲 Donate to this Centre
        </button>
      </div>
    </div>
  `).join('');
}

function prefillDonationWithCenter(centreName) {
  switchTab('donate');
  const addressInput = document.getElementById('donate-address');
  if (addressInput) {
    addressInput.value = `Drop-off at ${centreName}`;
  }
}

// ================= Welfare Portal & Quality Checklist =================
function initWelfarePortal() {
  // Welfare tab switching
  document.querySelectorAll('.welfare-subtab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.welfare-subtab-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const subtab = btn.getAttribute('data-subtab');

      document.querySelectorAll('.welfare-subpane').forEach(p => p.style.display = 'none');
      const targetPane = document.getElementById(`welfare-pane-${subtab}`);
      if (targetPane) targetPane.style.display = 'block';
    });
  });

  // Welfare Centre Registration Form Submit
  const regForm = document.getElementById('welfare-registration-form');
  if (regForm) {
    regForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const name = document.getElementById('welfare-reg-name').value.trim();
      const email = document.getElementById('welfare-reg-email').value.trim();
      const phone = document.getElementById('welfare-reg-phone').value.trim();
      const address = document.getElementById('welfare-reg-address').value.trim();
      const regNo = document.getElementById('welfare-reg-number').value.trim();

      await window.foodLinkService.registerWelfareCentre({
        name,
        email,
        phone,
        address,
        registrationNumber: regNo
      });

      regForm.reset();
      showToast('Welfare Centre registration submitted! Pending review by administrator.');
      renderWelfareApplicationsList();
    });
  }

  // Quality Inspection Form Submit
  const qualityForm = document.getElementById('quality-inspection-form');
  if (qualityForm) {
    qualityForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const donationId = appState.activeQualityInspectionDonation;
      if (!donationId) return;

      const isFresh = document.getElementById('audit-fresh').checked;
      const isQuality = document.getElementById('audit-quality').checked;
      const isPackaging = document.getElementById('audit-packaging').checked;
      const notes = document.getElementById('audit-notes').value.trim();

      await window.foodLinkService.submitWelfareQualityChecklist(donationId, {
        isFresh,
        isGoodQuality: isQuality,
        isPackagingIntact: isPackaging,
        feedbackNotes: notes,
        verifiedBy: window.foodLinkService.currentUser?.displayName || 'Hope Foundation Staff'
      });

      document.getElementById('quality-checklist-modal').classList.remove('open');
      showToast('Food Quality checklist saved! Donor notified.');
      renderWelfareDonationsFeed();
    });
  }
}

function renderWelfareDonationsFeed() {
  const container = document.getElementById('welfare-feed-container');
  if (!container) return;

  const donations = window.foodLinkService.donations;

  if (donations.length === 0) {
    container.innerHTML = `<p style="padding: 24px; color: var(--text-muted); text-align: center;">No active food donations found.</p>`;
    return;
  }

  container.innerHTML = donations.map(d => {
    const isPending = (d.status || '').toLowerCase() === 'pending';
    const isAccepted = (d.status || '').toLowerCase() === 'accepted';

    return `
      <div class="card" style="margin-bottom: 16px; border-left: 4px solid ${isAccepted ? '#16A34A' : (isPending ? '#D97706' : '#DC2626')};">
        <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 10px; margin-bottom: 8px;">
          <div>
            <h4 style="font-size: 1.15rem; font-weight: 700;">${escapeHtml(d.foodName)}</h4>
            <span style="font-size: 0.82rem; color: var(--text-muted);">${d.category} • <strong>${d.quantity} Servings</strong></span>
          </div>
          <span class="status-pill status-${d.status || 'pending'}">${d.status || 'Pending'}</span>
        </div>

        <div style="font-size: 0.86rem; color: var(--text-dark); margin-bottom: 8px;">
          📍 <strong>Pickup:</strong> ${escapeHtml(d.pickupAddress)}
        </div>

        <div style="font-size: 0.86rem; color: var(--text-dark); margin-bottom: 12px;">
          👤 <strong>Donor:</strong> ${escapeHtml(d.donorName)} (${escapeHtml(d.contactNumber)})
        </div>

        <div style="display: flex; gap: 10px; flex-wrap: wrap; border-top: 1px solid var(--border-color); padding-top: 12px;">
          ${isPending ? `
            <button class="btn btn-primary btn-sm" onclick="handleWelfareAcceptDonation('${d.id}')">
              ✓ Accept Donation
            </button>
            <button class="btn btn-outline btn-sm" style="color: var(--danger-red);" onclick="handleWelfareDeclineDonation('${d.id}')">
              ✕ Decline
            </button>
          ` : ''}

          <button class="btn btn-purple btn-sm" onclick="openQualityInspectionModal('${d.id}')">
            🔍 Inspect Quality & Freshness
          </button>

          <a href="tel:${d.contactNumber}" class="btn btn-outline btn-sm">📞 Call Donor</a>
        </div>
      </div>
    `;
  }).join('');
}

async function handleWelfareAcceptDonation(donationId) {
  const staffName = window.foodLinkService.currentUser?.displayName || 'Hope Foundation Staff';
  await window.foodLinkService.updateDonationStatus(donationId, 'accepted', staffName);
  showToast(`Donation accepted by ${staffName}! Donor notified.`);
  renderWelfareDonationsFeed();
}

async function handleWelfareDeclineDonation(donationId) {
  const staffName = window.foodLinkService.currentUser?.displayName || 'Welfare Organisation';
  await window.foodLinkService.updateDonationStatus(donationId, 'rejected', staffName);
  showToast('Donation declined. Donor notified.');
  renderWelfareDonationsFeed();
}

function openQualityInspectionModal(donationId) {
  appState.activeQualityInspectionDonation = donationId;
  const d = window.foodLinkService.donations.find(item => item.id === donationId);
  if (!d) return;

  const titleEl = document.getElementById('audit-food-title');
  if (titleEl) titleEl.textContent = `${d.foodName} (${d.quantity} servings)`;

  const modal = document.getElementById('quality-checklist-modal');
  modal.classList.add('open');
}

function renderWelfareApplicationsList() {
  const container = document.getElementById('admin-applications-list');
  if (!container) return;

  const apps = window.foodLinkService.pendingApplications;
  const isAdmin = window.foodLinkService.currentUser?.isWelfareAdmin;

  if (apps.length === 0) {
    container.innerHTML = `<p style="padding: 20px; color: var(--text-muted); text-align: center;">No pending welfare centre registrations.</p>`;
    return;
  }

  container.innerHTML = apps.map(app => `
    <div class="card" style="margin-bottom: 14px;">
      <div style="display: flex; justify-content: space-between; align-items: flex-start;">
        <div>
          <h4 style="font-size: 1.1rem; font-weight: 700;">${escapeHtml(app.name)}</h4>
          <div style="font-size: 0.84rem; color: var(--text-muted);">Reg: ${escapeHtml(app.registrationNumber)} • Email: ${escapeHtml(app.email)}</div>
        </div>
        <span class="status-pill status-${app.status}">${app.status.toUpperCase()}</span>
      </div>

      <div style="margin: 8px 0; font-size: 0.86rem;">
        📍 Address: ${escapeHtml(app.address)}
      </div>

      <div style="margin-bottom: 12px;">
        <a href="${app.certificateUrl}" target="_blank" class="btn btn-outline btn-sm">
          📄 View NGO Registration Certificate
        </a>
      </div>

      ${app.status === 'pending' ? `
        <div style="display: flex; gap: 8px;">
          <button class="btn btn-primary btn-sm" onclick="reviewCentreApplication('${app.id}', 'approved')">
            ✓ Approve & Verify NGO
          </button>
          <button class="btn btn-outline btn-sm" style="color: var(--danger-red);" onclick="reviewCentreApplication('${app.id}', 'rejected')">
            ✕ Reject Application
          </button>
        </div>
      ` : ''}
    </div>
  `).join('');
}

async function reviewCentreApplication(appId, decision) {
  await window.foodLinkService.reviewWelfareApplication(appId, decision);
  showToast(`Centre application marked as ${decision.toUpperCase()}!`);
  renderWelfareApplicationsList();
  renderNearestCentersList();
}

// ================= Notifications Drawer & Modal =================
function initNotificationsModal() {
  const notifBtn = document.getElementById('notifications-bell-btn');
  const modal = document.getElementById('notifications-modal');
  const closeBtn = document.getElementById('close-notifications-btn');
  const markAllBtn = document.getElementById('mark-all-read-btn');

  if (notifBtn) {
    notifBtn.addEventListener('click', () => {
      modal.classList.add('open');
      renderNotificationsList();
    });
  }

  if (closeBtn) {
    closeBtn.addEventListener('click', () => {
      modal.classList.remove('open');
    });
  }

  if (markAllBtn) {
    markAllBtn.addEventListener('click', () => {
      window.foodLinkService.markAllNotificationsAsRead();
      showToast('All notifications marked as read.');
      renderNotificationsList();
      updateNotificationBadge();
    });
  }

  // Filter tabs in modal
  document.querySelectorAll('.notif-filter-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.notif-filter-tab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      appState.notificationsFilterRole = tab.getAttribute('data-role');
      renderNotificationsList();
    });
  });
}

function updateNotificationBadge() {
  const badge = document.getElementById('notification-unread-dot');
  if (!badge) return;

  const currentRole = window.foodLinkService.currentUser?.role || 'donor';
  const unreadCount = window.foodLinkService.notifications.filter(n => {
    if (n.isRead) return false;
    if (currentRole === 'welfare' || currentRole === 'admin') {
      return n.targetRole === 'welfare' || n.targetRole === 'admin';
    }
    return n.targetRole === 'donor' || n.targetRole === 'all';
  }).length;

  if (unreadCount > 0) {
    badge.style.display = 'block';
  } else {
    badge.style.display = 'none';
  }
}

function renderNotificationsList() {
  const container = document.getElementById('notifications-list-container');
  if (!container) return;

  let notifs = window.foodLinkService.notifications;
  if (appState.notificationsFilterRole !== 'all') {
    notifs = notifs.filter(n => n.targetRole === appState.notificationsFilterRole);
  }

  if (notifs.length === 0) {
    container.innerHTML = `<div style="text-align: center; padding: 40px 20px; color: var(--text-muted);">No notifications to display.</div>`;
    return;
  }

  container.innerHTML = notifs.map(n => `
    <div style="padding: 14px 18px; border-bottom: 1px solid var(--border-color); background: ${n.isRead ? 'white' : '#F0FDF4'}; display: flex; gap: 12px; align-items: flex-start; cursor: pointer;" onclick="handleNotificationClick('${n.id}', '${n.donationId}')">
      <div style="font-size: 1.4rem;">${getNotificationIcon(n.type)}</div>
      <div style="flex: 1;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
          <h5 style="font-size: 0.94rem; font-weight: 700; color: var(--text-dark);">${escapeHtml(n.title)}</h5>
          <span style="font-size: 0.72rem; color: var(--text-muted);">${formatRelativeTime(n.createdAt)}</span>
        </div>
        <p style="font-size: 0.84rem; color: var(--text-muted); line-height: 1.4;">${escapeHtml(n.body)}</p>
      </div>
    </div>
  `).join('');
}

function handleNotificationClick(notifId, donationId) {
  window.foodLinkService.markNotificationAsRead(notifId);
  updateNotificationBadge();
  if (donationId) {
    document.getElementById('notifications-modal').classList.remove('open');
    openDonationDetails(donationId);
  }
}

function getNotificationIcon(type) {
  switch (type) {
    case 'donation_accepted': return '🎉';
    case 'donation_rejected': return '⚠️';
    case 'new_donation': return '🍲';
    case 'food_quality_verified': return '🌟';
    case 'centre_application': return '🏢';
    default: return '🔔';
  }
}

// ================= Support AI Chat Screen =================
function initSupportChatView() {
  const sendBtn = document.getElementById('chat-send-btn');
  const chatInput = document.getElementById('chat-input-box');
  const messagesBox = document.getElementById('chat-messages-container');

  function sendChatMessage(msgText) {
    const text = msgText || chatInput.value.trim();
    if (!text) return;

    // Render user message
    const userMsgEl = document.createElement('div');
    userMsgEl.className = 'chat-bubble user';
    userMsgEl.textContent = text;
    messagesBox.appendChild(userMsgEl);

    if (!msgText) chatInput.value = '';
    messagesBox.scrollTop = messagesBox.scrollHeight;

    // AI Bot Reply
    setTimeout(() => {
      const replyText = getChatBotReply(text);
      const botMsgEl = document.createElement('div');
      botMsgEl.className = 'chat-bubble bot';
      botMsgEl.textContent = replyText;
      messagesBox.appendChild(botMsgEl);
      messagesBox.scrollTop = messagesBox.scrollHeight;
    }, 400);
  }

  if (sendBtn) {
    sendBtn.addEventListener('click', () => sendChatMessage());
  }

  if (chatInput) {
    chatInput.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') sendChatMessage();
    });
  }

  // Quick Suggested Questions
  document.querySelectorAll('.suggestion-pill').forEach(pill => {
    pill.addEventListener('click', () => {
      const prompt = pill.getAttribute('data-prompt');
      sendChatMessage(prompt);
    });
  });
}

// ================= Profile Screen =================
function renderProfileScreen() {
  const user = window.foodLinkService.currentUser;
  const nameEl = document.getElementById('profile-name');
  const emailEl = document.getElementById('profile-email');
  const roleEl = document.getElementById('profile-role');
  const myDonationsCountEl = document.getElementById('profile-donations-count');
  const peopleFedCountEl = document.getElementById('profile-people-fed');

  if (nameEl) nameEl.textContent = user?.displayName || 'Mohammed Mustafa';
  if (emailEl) emailEl.textContent = user?.email || 'mustafa79996@gmail.com';
  if (roleEl) roleEl.textContent = user?.isWelfareAdmin ? 'Welfare Administrator' : (user?.role === 'welfare' ? 'Welfare Organisation' : 'Verified Community Donor');

  const myDonations = window.foodLinkService.donations.filter(d => d.donorId === user?.uid || d.donorEmail === user?.email);
  const totalServings = myDonations.reduce((sum, d) => sum + (d.quantity || 0), 0);

  if (myDonationsCountEl) myDonationsCountEl.textContent = myDonations.length;
  if (peopleFedCountEl) peopleFedCountEl.textContent = totalServings > 0 ? totalServings * 2 : 120;
}

// ================= Speech-to-Text Voice Input =================
function initVoiceInputSupport() {
  // Voice input on Donate food form
  initSpeechRecognition('donate-food-name', 'mic-donate-food-name');
  initSpeechRecognition('donate-address', 'mic-donate-address');
  initSpeechRecognition('chat-input-box', 'mic-chat-input');
}

// ================= Utility Helpers =================
function calculateDistanceKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function formatFriendlyDate(dateStr) {
  if (!dateStr) return 'N/A';
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return dateStr;
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

function formatRelativeTime(dateStr) {
  if (!dateStr) return 'Recently';
  const d = new Date(dateStr);
  const diffSec = Math.floor((Date.now() - d.getTime()) / 1000);
  if (diffSec < 60) return 'Just now';
  if (diffSec < 3600) return `${Math.floor(diffSec / 60)}m ago`;
  if (diffSec < 86400) return `${Math.floor(diffSec / 3600)}h ago`;
  return `${Math.floor(diffSec / 86400)}d ago`;
}

function escapeHtml(str) {
  if (!str) return '';
  return str.toString()
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function showToast(message) {
  let toast = document.getElementById('app-toast');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'app-toast';
    toast.style.cssText = `
      position: fixed;
      bottom: 24px;
      right: 24px;
      background: var(--primary-green);
      color: white;
      padding: 12px 20px;
      border-radius: var(--radius-md);
      box-shadow: var(--shadow-lg);
      font-weight: 600;
      font-size: 0.92rem;
      z-index: 3000;
      opacity: 0;
      transform: translateY(12px);
      transition: all 0.25s ease;
      display: flex;
      align-items: center;
      gap: 8px;
    `;
    document.body.appendChild(toast);
  }

  toast.textContent = message;
  toast.style.opacity = '1';
  toast.style.transform = 'translateY(0)';

  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(12px)';
  }, 3500);
}

// Global modal closer helper
window.closeActiveModal = function(modalId) {
  const m = document.getElementById(modalId);
  if (m) m.classList.remove('open');
};
