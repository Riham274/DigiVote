import os
import re
import urllib.request

base_dir = r"c:\Users\riham\OneDrive\Desktop\stitch_univote_smart_voting_system\univote_smart_voting_system"
app_dir = os.path.join(base_dir, "univote_app")
assets_dir = os.path.join(app_dir, "assets", "images")

os.makedirs(assets_dir, exist_ok=True)
os.makedirs(os.path.join(app_dir, "lib", "core", "theme"), exist_ok=True)
os.makedirs(os.path.join(app_dir, "lib", "presentation", "screens", "welcome"), exist_ok=True)
os.makedirs(os.path.join(app_dir, "lib", "presentation", "screens", "auth"), exist_ok=True)
os.makedirs(os.path.join(app_dir, "lib", "presentation", "screens", "candidates"), exist_ok=True)
os.makedirs(os.path.join(app_dir, "lib", "presentation", "screens", "admin"), exist_ok=True)
os.makedirs(os.path.join(app_dir, "lib", "presentation", "widgets"), exist_ok=True)

image_count = 1

for root, dirs, files in os.walk(base_dir):
    if "univote_app" in root:
        continue
    for file in files:
        if file.endswith(".html"):
            with open(os.path.join(root, file), 'r', encoding='utf-8') as f:
                content = f.read()
                urls = re.findall(r'src="(https://lh3.googleusercontent.com/[^"]+)"', content)
                for url in urls:
                    image_name = f"image_{image_count}.jpg"
                    image_path = os.path.join(assets_dir, image_name)
                    print(f"Downloading {url} to {image_name}")
                    try:
                        urllib.request.urlretrieve(url, image_path)
                        image_count += 1
                    except Exception as e:
                        print(f"Failed to download {url}: {e}")

print("Directories created and images downloaded.")
