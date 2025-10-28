import requests
import os

def download_swagger_files():
    """Download Swagger UI files for offline use"""
    files = {
        "swagger-ui-bundle.js": "https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.9.0/swagger-ui-bundle.js",
        "swagger-ui-standalone-preset.js": "https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.9.0/swagger-ui-standalone-preset.js", 
        "swagger-ui.css": "https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.9.0/swagger-ui.css",
        "favicon-32x32.png": "https://fastapi.tiangolo.com/img/favicon-32x32.png"
    }
    
    os.makedirs("static/docs", exist_ok=True)
    
    for filename, url in files.items():
        try:
            print(f"Downloading {filename}...")
            response = requests.get(url)
            with open(f"static/docs/{filename}", "wb") as f:
                f.write(response.content)
            print(f"✓ Downloaded: {filename}")
        except Exception as e:
            print(f"✗ Error downloading {filename}: {e}")

if __name__ == "__main__":
    download_swagger_files()