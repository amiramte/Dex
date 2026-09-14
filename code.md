# settings.py
. SECRET_KEY = "..." ===>>> SECRET_KEY = os.environ.get("SECRET_KEY")
. ALLOWED_HOSTS = [] ===>>> ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',') if os.environ.get('ALLOWED_HOSTS') else []
.   ===>>> STATIC_ROOT = BASE_DIR / "staticfiles"