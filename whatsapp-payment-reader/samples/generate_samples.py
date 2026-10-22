"""Generates the fake payment screenshots used to demo the workflow.

Every image is fictional (made-up names, numbers and IDs) and carries a
"DEMO SAMPLE" watermark. Requires Pillow:  pip install pillow
Run:  python3 generate_samples.py   (writes PNGs next to this script)
"""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.dirname(os.path.abspath(__file__))
W, H = 720, 1400
SANS = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def font(size, bold=False):
    try:
        return ImageFont.truetype(BOLD if bold else SANS, size)
    except OSError:
        return ImageFont.load_default(size)


def centre(d, y, text, size, fill, bold=False):
    f = font(size, bold)
    w = d.textlength(text, font=f)
    d.text(((W - w) / 2, y), text, font=f, fill=fill)


def rows(d, y, items, label_fill, value_fill, x=60, gap=78):
    for label, value in items:
        d.text((x, y), label, font=font(24), fill=label_fill)
        d.text((x, y + 30), value, font=font(30, True), fill=value_fill)
        y += gap
    return y


def tick(d, cx, cy, r, colour):
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=colour)
    d.line([(cx - r * .45, cy), (cx - r * .1, cy + r * .35), (cx + r * .5, cy - r * .35)], fill="white", width=int(r * .18))


def status_bar(d, dark=False):
    c = "white" if dark else "#222222"
    d.text((30, 18), "10:42", font=font(24, True), fill=c)
    d.text((W - 150, 18), "4G  86%", font=font(22), fill=c)


def watermark(img):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    for y in range(150, H, 420):
        ld.text((70, y), "DEMO SAMPLE - NOT A REAL PAYMENT", font=font(30, True), fill=(220, 30, 30, 70))
    return Image.alpha_composite(img.convert("RGBA"), layer.rotate(25, center=(W / 2, H / 2))).convert("RGB")


def save(img, name):
    watermark(img).save(os.path.join(OUT, name), optimize=True)
    print("wrote", name)


# 1. Google Pay style: light, blue accents, shows UPI transaction ID, no payer phone
def gpay():
    img = Image.new("RGB", (W, H), "white"); d = ImageDraw.Draw(img); status_bar(d)
    d.text((40, 80), "Google Pay", font=font(30, True), fill="#1a73e8")
    tick(d, W / 2, 260, 80, "#1e8e3e")
    centre(d, 370, "₹1,500", 72, "#202124", True)
    centre(d, 470, "Paid to Sunrise Cricket Academy", 30, "#202124")
    centre(d, 515, "sunrisecricket@okaxis", 26, "#5f6368")
    centre(d, 575, "Completed", 28, "#1e8e3e", True)
    centre(d, 615, "22 Oct 2026, 10:41 am", 26, "#5f6368")
    d.rounded_rectangle((40, 690, W - 40, 1210), 20, outline="#dadce0", width=2)
    rows(d, 715, [
        ("UPI transaction ID", "629514873201"),
        ("To", "SUNRISE CRICKET ACADEMY"),
        ("From", "Rahul Verma (HDFC Bank ****4821)"),
        ("Google transaction ID", "CICAgKD9xLmQBg"),
        ("Note", "Aarav U12 October fees"),
    ], "#5f6368", "#202124", x=70, gap=95)
    save(img, "01-gpay-success.png")


# 2. PhonePe style: purple header, shows payer mobile, transaction ID and UTR
def phonepe():
    img = Image.new("RGB", (W, H), "#f5f3fa"); d = ImageDraw.Draw(img)
    d.rectangle((0, 0, W, 330), fill="#5f259f"); status_bar(d, dark=True)
    d.text((40, 80), "PhonePe", font=font(30, True), fill="white")
    tick(d, 100, 220, 45, "#2fb344")
    d.text((170, 185), "Transaction Successful", font=font(34, True), fill="white")
    d.text((170, 235), "10:38 am on 22 Oct 2026", font=font(24), fill="#e0d4f5")
    d.rounded_rectangle((30, 360, W - 30, 1250), 18, fill="white")
    d.text((60, 390), "Paid to", font=font(24), fill="#666666")
    d.text((60, 425), "Sunrise Cricket Academy", font=font(32, True), fill="#222222")
    d.text((W - 230, 470), "\u20b92,500", font=font(40, True), fill="#222222")
    d.text((60, 475), "sunrisecricket@ybl", font=font(24), fill="#666666")
    d.line((60, 530, W - 60, 530), fill="#eeeeee", width=2)
    rows(d, 555, [
        ("Transaction ID", "T2610221038254417896512"),
        ("Debited from", "XXXXXXXX7710   (Priya Nair)"),
        ("UTR", "429731056842"),
        ("Mobile number", "+91 98765 01234"),
        ("Message", "Kabir - kit and jersey"),
    ], "#666666", "#222222", gap=100)
    save(img, "02-phonepe-success.png")


# 3. WhatsApp Pay style: chat bubble, payment card, note, no payer phone
def whatsapp_pay():
    img = Image.new("RGB", (W, H), "#efe7dd"); d = ImageDraw.Draw(img)
    d.rectangle((0, 0, W, 150), fill="#075e54"); status_bar(d, dark=True)
    d.text((40, 80), "Sunrise Cricket Academy", font=font(30, True), fill="white")
    d.rounded_rectangle((W - 520, 240, W - 40, 760), 18, fill="#dcf8c6")
    d.text((W - 490, 270), "Payment", font=font(24), fill="#4a4a4a")
    d.text((W - 490, 310), "₹3,000", font=font(64, True), fill="#111111")
    d.text((W - 490, 400), "Paid", font=font(28, True), fill="#128c7e")
    d.text((W - 490, 450), "Note: Ishaan tournament entry", font=font(24), fill="#111111")
    d.text((W - 490, 500), "+ coaching camp", font=font(24), fill="#111111")
    d.line((W - 490, 560, W - 70, 560), fill="#b5d9a5", width=2)
    d.text((W - 490, 580), "UPI transaction ID", font=font(22), fill="#4a4a4a")
    d.text((W - 490, 610), "631208774519", font=font(28, True), fill="#111111")
    d.text((W - 490, 665), "Bank of Baroda ****0932", font=font(22), fill="#4a4a4a")
    d.text((W - 210, 715), "21/10/2026 7:15 pm", font=font(20), fill="#7a7a7a")
    save(img, "03-whatsapp-pay.png")


# 4. CRED style: dark theme, UPI ref no, date in a different format
def cred():
    img = Image.new("RGB", (W, H), "#0d0d0d"); d = ImageDraw.Draw(img); status_bar(d, dark=True)
    d.text((40, 80), "CRED pay", font=font(30, True), fill="#e5e5e5")
    tick(d, W / 2, 280, 70, "#2bb673")
    centre(d, 390, "payment successful", 34, "#e5e5e5", True)
    centre(d, 460, "₹ 1,200.00", 70, "white", True)
    centre(d, 560, "to SUNRISE CRICKET ACADEMY", 26, "#9a9a9a")
    d.line((60, 640, W - 60, 640), fill="#2a2a2a", width=2)
    rows(d, 670, [
        ("UPI ref no.", "512687340923"),
        ("paid on", "Tue, 20 Oct 2026  |  06:05 PM"),
        ("paid from", "ICICI Bank xx3359"),
        ("paid by", "Anjali Deshpande  •  9820011223"),
    ], "#8a8a8a", "#f0f0f0", gap=105)
    save(img, "04-cred-success.png")


# 5. Bank / BHIM-style pending payment: should be flagged "Needs review"
def pending():
    img = Image.new("RGB", (W, H), "white"); d = ImageDraw.Draw(img); status_bar(d)
    d.text((40, 80), "BHIM UPI", font=font(30, True), fill="#00796b")
    d.ellipse((W / 2 - 75, 190, W / 2 + 75, 340), fill="#f9a825")
    centre(d, 222, "!", 80, "white", True)
    centre(d, 380, "Payment Pending", 38, "#e65100", True)
    centre(d, 450, "₹800", 72, "#212121", True)
    centre(d, 550, "Your bank has not confirmed this payment yet.", 24, "#616161")
    rows(d, 640, [
        ("To", "sunrisecricket@upi"),
        ("Transaction ref", "430155908127"),
        ("Date", "22-10-2026 09:55"),
        ("From", "Sameer Khan  +91 90040 55678"),
    ], "#757575", "#212121", gap=100)
    save(img, "05-bhim-pending.png")


# 6. Not a payment: a tournament notice, should be rejected and not logged
def not_payment():
    img = Image.new("RGB", (W, H), "#fffbea"); d = ImageDraw.Draw(img); status_bar(d)
    centre(d, 120, "Junior Champions T20 Cup", 40, "#1b5e20", True)
    centre(d, 180, "Semi-final line-up", 32, "#33691e")
    y = 280
    for line in ["SF1  Thunder Kings vs Royal Strikers", "        22 Oct, 9:00 am, Ground 1", "",
                 "SF2  Super Sixers vs Blazing Bulls", "        22 Oct, 2:00 pm, Ground 1", "",
                 "Final  23 Oct, 3:00 pm", "", "Please reach 45 minutes early."]:
        d.text((60, y), line, font=font(28), fill="#212121"); y += 50
    save(img, "06-not-a-payment.png")


if __name__ == "__main__":
    gpay(); phonepe(); whatsapp_pay(); cred(); pending(); not_payment()
