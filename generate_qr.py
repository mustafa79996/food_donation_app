import os
import shutil
import qrcode
import qrcode.image.svg
from PIL import Image, ImageDraw, ImageFont

URL = "http://192.168.0.144:8080/foodlink.apk"
PRIMARY_GREEN = (15, 81, 50)       # #0F5132
BRAND_GREEN   = (19, 93, 57)       # #135D39
MINT_BG       = (240, 253, 244)    # #F0FDF4
TEXT_DARK     = (30, 41, 59)       # #1E293B
TEXT_MUTED    = (100, 116, 139)    # #64748B
WHITE         = (255, 255, 255)
BORDER_GRAY   = (226, 232, 240)    # #E2E8F0
AMBER_COLOR   = (217, 119, 6)      # #D97706

def get_font(size, bold=False):
    font_path = "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf"
    if not os.path.exists(font_path):
        font_path = "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf"
    try:
        return ImageFont.truetype(font_path, size)
    except Exception:
        return ImageFont.load_default()

def draw_center_logo(size):
    """Draw the official FoodLink logo badge for the center of the QR."""
    logo_path = os.path.join(os.path.dirname(__file__), "assets", "images", "logo.png")
    if os.path.exists(logo_path):
        badge = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(badge)
        margin = 3
        draw.rounded_rectangle([margin, margin, size - margin, size - margin], radius=size // 4, fill=WHITE, outline=PRIMARY_GREEN, width=3)
        inner_size = size - 12
        logo_img = Image.open(logo_path).convert("RGBA").resize((inner_size, inner_size), Image.Resampling.LANCZOS)
        badge.paste(logo_img, (6, 6), logo_img)
        return badge

    badge = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(badge)
    
    # White rounded square background with smooth border
    margin = 4
    draw.rounded_rectangle([margin, margin, size - margin, size - margin], radius=size // 4, fill=WHITE, outline=PRIMARY_GREEN, width=4)
    
    # Draw food bowl / leaf icon inside
    center_x = size // 2
    center_y = size // 2
    radius = size // 3
    
    # Bowl shape (half circle at bottom)
    draw.chord([center_x - radius, center_y - 6, center_x + radius, center_y + radius + 8], start=0, end=180, fill=PRIMARY_GREEN)
    
    # Leaf / steam shape at top
    leaf_top = center_y - radius + 2
    draw.polygon([
        (center_x, leaf_top),
        (center_x + radius // 2, center_y - 8),
        (center_x, center_y - 2),
        (center_x - radius // 2, center_y - 8)
    ], fill=AMBER_COLOR)
    
    return badge

def generate_standard_qr(url, filename):
    qr = qrcode.QRCode(
        version=None,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=16,
        border=4,
    )
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white").convert("RGB")
    img.save(filename)
    return img

def generate_brand_qr(url, filename, with_logo=True):
    qr = qrcode.QRCode(
        version=None,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=16,
        border=4,
    )
    qr.add_data(url)
    qr.make(fit=True)
    
    # Generate green QR code
    img = qr.make_image(fill_color=PRIMARY_GREEN, back_color="white").convert("RGBA")
    
    if with_logo:
        # Overlay FoodLink center logo
        qr_width, qr_height = img.size
        logo_size = int(qr_width * 0.22)  # 22% of QR code width (safe for ERROR_CORRECT_H)
        logo = draw_center_logo(logo_size)
        pos = ((qr_width - logo_size) // 2, (qr_height - logo_size) // 2)
        img.paste(logo, pos, mask=logo)
    
    rgb_img = img.convert("RGB")
    rgb_img.save(filename)
    return rgb_img

def generate_svg_qr(url, filename):
    factory = qrcode.image.svg.SvgImage
    qr = qrcode.QRCode(
        version=None,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=16,
        border=4,
        image_factory=factory
    )
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image()
    img.save(filename)

def generate_marketing_poster(qr_img, url, filename):
    # Standard printable A4 / flyer ratio: 1080 x 1480
    w, h = 1080, 1480
    poster = Image.new("RGB", (w, h), (248, 250, 252))
    draw = ImageDraw.Draw(poster)
    
    # Top curved header gradient / block
    header_height = 290
    for y in range(header_height):
        ratio = y / header_height
        r = int(PRIMARY_GREEN[0] + (BRAND_GREEN[0] - PRIMARY_GREEN[0]) * ratio)
        g = int(PRIMARY_GREEN[1] + (BRAND_GREEN[1] - PRIMARY_GREEN[1]) * ratio)
        b = int(PRIMARY_GREEN[2] + (BRAND_GREEN[2] - PRIMARY_GREEN[2]) * ratio)
        draw.line([(0, y), (w, y)], fill=(r, g, b))
    
    # Header Accent bar
    draw.rectangle([0, header_height - 6, w, header_height], fill=(134, 239, 172))
    
    # Fonts
    title_font = get_font(58, bold=True)
    subtitle_font = get_font(24, bold=False)
    cta_title_font = get_font(38, bold=True)
    cta_sub_font = get_font(22, bold=False)
    url_font = get_font(24, bold=True)
    badge_font = get_font(18, bold=True)
    footer_font = get_font(18, bold=False)
    
    # Header Text
    draw.text((w // 2, 85), "FoodLink", font=title_font, fill=WHITE, anchor="mm")
    draw.text((w // 2, 155), "Bridging Surplus Food to Verified Welfare Centres", font=subtitle_font, fill=(232, 245, 233), anchor="mm")
    draw.text((w // 2, 205), "DONOR  •  COMMUNITY  •  WELFARE", font=get_font(18, bold=True), fill=(187, 247, 208), anchor="mm")
    
    # Central Card (White with soft border)
    card_margin_x = 90
    card_top = 340
    card_bottom = 1260
    card_rect = [card_margin_x, card_top, w - card_margin_x, card_bottom]
    
    # Card shadow
    for offset in range(8, 0, -2):
        shadow_rect = [card_rect[0] - offset, card_rect[1] - offset, card_rect[2] + offset, card_rect[3] + offset]
        draw.rounded_rectangle(shadow_rect, radius=36, fill=(235, 240, 245))
        
    draw.rounded_rectangle(card_rect, radius=32, fill=WHITE, outline=BORDER_GRAY, width=2)
    
    # CTA heading inside card
    draw.text((w // 2, card_top + 60), "Scan to Download FoodLink APK", font=cta_title_font, fill=TEXT_DARK, anchor="mm")
    draw.text((w // 2, card_top + 115), "Scan with your phone to download the Android app", font=cta_sub_font, fill=TEXT_MUTED, anchor="mm")
    
    # QR Code placement inside card
    qr_target_size = 540
    resized_qr = qr_img.resize((qr_target_size, qr_target_size), Image.Resampling.LANCZOS)
    qr_box = [
        (w - qr_target_size) // 2 - 16,
        card_top + 170 - 16,
        (w + qr_target_size) // 2 + 16,
        card_top + 170 + qr_target_size + 16
    ]
    # Subtle inner frame for QR
    draw.rounded_rectangle(qr_box, radius=20, fill=(248, 250, 252), outline=BORDER_GRAY, width=1)
    poster.paste(resized_qr, ((w - qr_target_size) // 2, card_top + 170))
    
    # URL Pill Container
    pill_y = card_top + 170 + qr_target_size + 50
    pill_w = 720
    pill_h = 56
    pill_rect = [(w - pill_w) // 2, pill_y, (w + pill_w) // 2, pill_y + pill_h]
    draw.rounded_rectangle(pill_rect, radius=28, fill=MINT_BG, outline=(187, 247, 208), width=2)
    draw.text((w // 2, pill_y + pill_h // 2), url, font=url_font, fill=PRIMARY_GREEN, anchor="mm")
    
    # Badges row under card
    badges_y = 1315
    badges = [
        ("🌱 Freshness Guaranteed", (240, 253, 244), PRIMARY_GREEN),
        ("🤝 Verified NGOs", (237, 233, 254), (91, 77, 223)),
        ("⚡ Real-Time Tracking", (254, 243, 199), (180, 83, 9))
    ]
    badge_width = 270
    badge_height = 44
    gap = 25
    start_x = (w - (3 * badge_width + 2 * gap)) // 2
    
    for i, (text, bg_col, text_col) in enumerate(badges):
        bx = start_x + i * (badge_width + gap)
        draw.rounded_rectangle([bx, badges_y, bx + badge_width, badges_y + badge_height], radius=22, fill=bg_col)
        draw.text((bx + badge_width // 2, badges_y + badge_height // 2), text, font=badge_font, fill=text_col, anchor="mm")
        
    # Bottom footer note
    draw.text((w // 2, 1410), "FoodLink — Reducing Food Waste, Nurturing Communities", font=footer_font, fill=TEXT_MUTED, anchor="mm")
    draw.text((w // 2, 1435), "Compatible with iOS Camera, Android Camera, Google Lens & Web Browsers", font=get_font(15, bold=False), fill=(148, 163, 184), anchor="mm")
    
    poster.save(filename)
    return poster

def main():
    print(f"Generating FoodLink QR Codes for: {URL}...")
    
    dirs_to_sync = [
        "assets/qr",
        "website/assets/qr"
    ]
    for d in dirs_to_sync:
        os.makedirs(d, exist_ok=True)
        
    # 1. Standard QR Code (Black & White, high precision)
    std_file = "foodlink_qr_standard.png"
    std_qr = generate_standard_qr(URL, std_file)
    print(f"  [OK] Generated {std_file}")
    
    # 2. Branded QR Code (FoodLink Forest Green with Center Badge)
    brand_file = "foodlink_qr_brand.png"
    brand_qr = generate_brand_qr(URL, brand_file, with_logo=True)
    print(f"  [OK] Generated {brand_file}")

    # 3. Clean Brand QR Code (Forest Green without center logo, ultra-reliable scanner)
    brand_clean_file = "foodlink_qr_clean.png"
    generate_brand_qr(URL, brand_clean_file, with_logo=False)
    print(f"  [OK] Generated {brand_clean_file}")
    
    # 4. SVG Vector QR Code
    svg_file = "foodlink_qr.svg"
    generate_svg_qr(URL, svg_file)
    print(f"  [OK] Generated {svg_file}")
    
    # 5. Marketing Poster Card (Printable Table Tent / Flyer)
    poster_file = "foodlink_qr_poster.png"
    generate_marketing_poster(brand_qr, URL, poster_file)
    print(f"  [OK] Generated {poster_file}")
    
    # Copy files to designated asset folders
    files = [std_file, brand_file, brand_clean_file, svg_file, poster_file]
    for target_dir in dirs_to_sync:
        for f in files:
            shutil.copy2(f, os.path.join(target_dir, f))
        print(f"  [OK] Synced all files to {target_dir}/")

    print("\nAll QR code assets generated successfully!")

if __name__ == "__main__":
    main()
