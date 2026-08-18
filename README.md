# Rutuj Tours & Travels - Airport Management System

Flutter Web & Mobile Operations Portal for Airport Transfers, Fleet, and Driver Management.

## Local Mobile Web Testing

To test the application locally from your phone/mobile browser on the same Wi-Fi network:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Access the portal on your phone's browser using your computer's local IP address (e.g. `http://192.168.1.5:8080`).

## Vercel Deployment & Single Page Application (SPA) Setup

This project is configured for Vercel deployment with single-page app (SPA) rewrites and path URL strategy (`usePathUrlStrategy()`).

- `vercel.json` is located in the root project folder and automatically included in `web/` to prevent 404 errors on browser refresh or direct deep-linking.
- Mobile viewport metadata is enabled in `web/index.html` for maximum mobile browser compatibility.

