// Initial mock and baseline data matching FoodLink mobile application
const INITIAL_DONATIONS = [
  {
    id: 'mock_biryani_1',
    foodName: 'Chicken Biryani & Salan',
    category: 'Meals',
    quantity: 15,
    donorId: 'JLF2gw2ZbaA6qH3derzVHEE1tr2',
    donorName: 'Mohammed Mustafa',
    donorEmail: 'mustafa79996@gmail.com',
    pickupAddress: 'Road No 12, Banjara Hills, Hyderabad, Telangana',
    contactNumber: '+91 98765 43210',
    imageUrl: 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=800&auto=format&fit=crop&q=80',
    expiryDate: new Date(Date.now() + 18 * 3600 * 1000).toISOString(),
    createdAt: new Date(Date.now() - 2 * 3600 * 1000).toISOString(),
    status: 'pending',
    updatedBy: '',
    foodSafetyChecklist: {
      fresh: true,
      properlyStored: true,
      properlyPacked: true,
      expiryDateConfirmed: true
    },
    welfareChecklist: null
  },
  {
    id: 'mock_fruits_2',
    foodName: 'Fresh Organic Fruit Basket (Apples & Bananas)',
    category: 'Fruits',
    quantity: 8,
    donorId: 'donor_user_2',
    donorName: 'Green Valley Organic Market',
    donorEmail: 'contact@greenvalleymarket.org',
    pickupAddress: 'Plot 45, Hitec City Phase 2, Hyderabad',
    contactNumber: '+91 91234 56780',
    imageUrl: 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=800&auto=format&fit=crop&q=80',
    expiryDate: new Date(Date.now() + 48 * 3600 * 1000).toISOString(),
    createdAt: new Date(Date.now() - 10 * 3600 * 1000).toISOString(),
    status: 'accepted',
    updatedBy: 'Hope Foundation Shelter',
    foodSafetyChecklist: {
      fresh: true,
      properlyStored: true,
      properlyPacked: true,
      expiryDateConfirmed: true
    },
    welfareChecklist: {
      completed: true,
      isFresh: true,
      isGoodQuality: true,
      isPackagingIntact: true,
      verifiedBy: 'Hope Foundation Shelter',
      feedbackNotes: 'Inspected upon pickup. Very fresh condition, safe for immediate distribution.'
    }
  },
  {
    id: 'mock_bread_3',
    foodName: 'Artisan Whole Wheat Bread & Buns',
    category: 'Grains',
    quantity: 25,
    donorId: 'JLF2gw2ZbaA6qH3derzVHEE1tr2',
    donorName: 'Mohammed Mustafa',
    donorEmail: 'mustafa79996@gmail.com',
    pickupAddress: 'Madhapur Main Road, Near Metro Station, Hyderabad',
    contactNumber: '+91 98765 43210',
    imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=800&auto=format&fit=crop&q=80',
    expiryDate: new Date(Date.now() + 24 * 3600 * 1000).toISOString(),
    createdAt: new Date(Date.now() - 5 * 3600 * 1000).toISOString(),
    status: 'pending',
    updatedBy: '',
    foodSafetyChecklist: {
      fresh: true,
      properlyStored: true,
      properlyPacked: true,
      expiryDateConfirmed: true
    },
    welfareChecklist: null
  },
  {
    id: 'mock_veg_4',
    foodName: 'Farm Fresh Mixed Vegetables (Carrots & Beans)',
    category: 'Vegetables',
    quantity: 12,
    donorId: 'donor_user_3',
    donorName: 'Metro Agro Produce',
    donorEmail: 'metroagro@example.com',
    pickupAddress: 'Kothaguda X Roads, Kondapur, Hyderabad',
    contactNumber: '+91 94401 23456',
    imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&auto=format&fit=crop&q=80',
    expiryDate: new Date(Date.now() + 36 * 3600 * 1000).toISOString(),
    createdAt: new Date(Date.now() - 20 * 3600 * 1000).toISOString(),
    status: 'accepted',
    updatedBy: 'Annamrita Food Relief',
    foodSafetyChecklist: {
      fresh: true,
      properlyStored: true,
      properlyPacked: true,
      expiryDateConfirmed: true
    },
    welfareChecklist: {
      completed: true,
      isFresh: true,
      isGoodQuality: true,
      isPackagingIntact: true,
      verifiedBy: 'Annamrita Food Relief',
      feedbackNotes: 'All veggies fresh and crisp.'
    }
  },
  {
    id: 'mock_beverages_5',
    foodName: 'Fresh Orange Juice & Herbal Tea Kits',
    category: 'Beverages',
    quantity: 30,
    donorId: 'donor_user_4',
    donorName: 'Jubilee Cafe & Bakery',
    donorEmail: 'orders@jubileecafe.com',
    pickupAddress: 'Road 36, Jubilee Hills, Hyderabad',
    contactNumber: '+91 99887 76655',
    imageUrl: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=800&auto=format&fit=crop&q=80',
    expiryDate: new Date(Date.now() + 12 * 3600 * 1000).toISOString(),
    createdAt: new Date(Date.now() - 30 * 3600 * 1000).toISOString(),
    status: 'pending',
    updatedBy: '',
    foodSafetyChecklist: {
      fresh: true,
      properlyStored: true,
      properlyPacked: true,
      expiryDateConfirmed: true
    },
    welfareChecklist: null
  }
];

const INITIAL_WELFARE_CENTRES = [
  {
    id: 'centre_hope_foundation',
    name: 'Hope Foundation Shelter',
    address: 'Road No 1, Banjara Hills, Hyderabad, Telangana 500034',
    phone: '+91 40 2345 6789',
    email: 'contact@hopefoundation.org',
    status: 'approved',
    latitude: 17.4156,
    longitude: 78.4347,
    verified: true,
    capacity: '250 people daily',
    operatingHours: '8:00 AM - 9:00 PM',
    distanceKm: 2.1
  },
  {
    id: 'centre_annamrita',
    name: 'Annamrita Food Relief Centre',
    address: 'Bank Street, Koti, Hyderabad, Telangana 500095',
    phone: '+91 40 2456 7890',
    email: 'info@annamrita.org',
    status: 'approved',
    latitude: 17.3871,
    longitude: 78.4820,
    verified: true,
    capacity: '500+ meals daily',
    operatingHours: '7:00 AM - 10:00 PM',
    distanceKm: 4.8
  },
  {
    id: 'centre_robin_hood',
    name: 'Robin Hood Army - Secunderabad Hub',
    address: 'Near Paradise Circle, MG Road, Secunderabad 500003',
    phone: '+91 40 2789 1234',
    email: 'robinhoodsecunderabad@gmail.com',
    status: 'approved',
    latitude: 17.4435,
    longitude: 78.4983,
    verified: true,
    capacity: '350 meals daily',
    operatingHours: 'Open 24/7 for Food Rescue',
    distanceKm: 6.3
  },
  {
    id: 'centre_seva_bharathi',
    name: 'Seva Bharathi Community Kitchen',
    address: 'Chaitanyapuri, Dilsukhnagar, Hyderabad, Telangana 500060',
    phone: '+91 40 2405 1234',
    email: 'help@sevabharathi.org',
    status: 'approved',
    latitude: 17.3688,
    longitude: 78.5247,
    verified: true,
    capacity: '300 meals daily',
    operatingHours: '9:00 AM - 8:00 PM',
    distanceKm: 8.7
  },
  {
    id: 'centre_akshaya_patra',
    name: 'Akshaya Patra Distribution Point',
    address: 'Financial District, Gachibowli, Hyderabad 500032',
    phone: '+91 40 6677 8899',
    email: 'support@akshayapatra.org',
    status: 'approved',
    latitude: 17.4401,
    longitude: 78.3489,
    verified: true,
    capacity: '1000+ meals daily',
    operatingHours: '6:00 AM - 9:00 PM',
    distanceKm: 7.2
  }
];

const INITIAL_PENDING_APPLICATIONS = [
  {
    id: 'app_care_kitchen',
    name: 'Care & Share Kitchen Foundation',
    email: 'admin@careshare.ngo',
    phone: '+91 98480 99887',
    address: 'Plot 12, Kukatpally Housing Board Colony, Hyderabad',
    registrationNumber: 'NGO-TS-2024-88419',
    certificateUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=800&auto=format&fit=crop&q=80',
    status: 'pending',
    appliedAt: new Date(Date.now() - 36 * 3600 * 1000).toISOString(),
    latitude: 17.4849,
    longitude: 78.4138
  },
  {
    id: 'app_vidya_seva',
    name: 'Vidya Seva Orphanage & Meal Trust',
    email: 'vidyaseva.trust@gmail.com',
    phone: '+91 97001 55443',
    address: 'Uppal Main Road, Near Stadium, Hyderabad',
    registrationNumber: 'REG-TS-55102',
    certificateUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=800&auto=format&fit=crop&q=80',
    status: 'pending',
    appliedAt: new Date(Date.now() - 14 * 3600 * 1000).toISOString(),
    latitude: 17.4018,
    longitude: 78.5602
  }
];

const CATEGORY_DEFAULT_IMAGES = {
  Meals: 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=800&auto=format&fit=crop&q=80',
  Vegetables: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&auto=format&fit=crop&q=80',
  Fruits: 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=800&auto=format&fit=crop&q=80',
  Grains: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=800&auto=format&fit=crop&q=80',
  Snacks: 'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=800&auto=format&fit=crop&q=80',
  Beverages: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=800&auto=format&fit=crop&q=80',
  Other: 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=800&auto=format&fit=crop&q=80'
};
