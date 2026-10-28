# Visitor Management Mobile Application

A production-grade, responsive Flutter mobile application designed for front-desk and security personnel to register visitors, manage visitor information, generate and scan QR codes, and record visitor check-in/check-out activities in real time.

---

## 🚀 Key Features

* **Dashboard & Analytics:** Real-time summary metrics calculated dynamically from local date (*Total Visitors Today*, *Currently Checked In*, and *Checked Out Today*) with quick action shortcuts.
* **Visitor Registration & Forms:** Comprehensive input validation for names, 10-digit mobile numbers, optional emails, visitor types (*Customer, Vendor, Other*), and project categories (*Project A, B, C*).
* **Visitor Listing & Local Search:** Real-time search filtering by visitor name or mobile number with scrollable `ListView.builder` cards and status badges.
* **QR Code Generation & Scanning:** Instant QR code generation encoding unique visitor IDs using `qr_flutter`, paired with camera-based scanning using `mobile_scanner`.
* **State Machine & Status Workflow:** Enforces strict business rules: `Registered` $\rightarrow$ `Checked In` $\rightarrow$ `Checked Out` (preventing duplicate check-ins or checking out before checking in).
* **Persistent REST API Integration:** Asynchronous CRUD operations communicating with a MockAPI backend, handling HTTP errors, loading states, and data persistence across app restarts.

---

## 🛠️ Technology Stack & Architecture

* **Framework:** Flutter (Dart 3+)
* **State Management:** `Provider` (`ChangeNotifier`) with immutable models and reactive listeners.
* **Network Client:** `http` package with dedicated repository service layer (`VisitorApiService`) and custom exception handling (`VisitorApiException`).
* **UI Components & Packages:**
  * `qr_flutterHere is a comprehensive, professional, and detailed `README.md` template for your Visitor Management Flutter application. It expands heavily on your setup, architecture, state management, API endpoints, and platform configurations to make your project stand out during an interview or evaluation.

---

## ⚙️ Configuration & Setup

### Configure the API
The application communicates with a persistent REST backend (such as MockAPI.io). The default MockAPI project configuration is located in `lib/services/api_config.dart`:
```text
https://<api-key>.baseUrl/visitors
```
## API Endpoints Reference
The application interacts with the following standard RESTful endpoints:
```markdown
Method         Endpoint         Functionality
-------------|----------------|--------------------------------------------------
GET            visitors          Retrieve all visitor records
GET            visitors/{id}     Retrieve specific visitor details
POST           visitors          Register a new visitor
PUT            visitors/{id}     Edit an existing visitor record
PATCH          visitors/{id}     Update visit status and check-in/out timestamps
DELETE         visitors/{id}     Delete a visitor record
```
## Platform Permissions
- #Android: Configured in AndroidManifest.xml with internet and camera permissions.
- #iOS: Configured in Info.plist with NSCameraUsageDescription for QR code scanning.
- #macOS Desktop: Configured in DebugProfile.entitlements and Release.entitlements with the client network entitlement (com.apple.security.network.client).
- #Web: Browser handles runtime camera permissions (requires HTTPS or localhost during development).
  
```text
lib/
│
├── models/          # Immutable data models, JSON serialization, copyWith patterns
├── services/        # API repository layer, HTTP client handling, ApiConfig
├── providers/       # State management controllers (ChangeNotifier, business rules)
├── screens/         # Primary application views (Dashboard, List, Register, Details, Scanner)
└── widgets/         # Reusable custom UI components (Stat cards, visitor rows, status chips)
```
### Screenshots & App Flow
## App Flow Diagram
```markdown
[ Application Launch ] ───▶ [ Load API Data ] ───▶ [ Dashboard Screen ]
                                                      │
         ┌────────────────────────────────────────────┼────────────────────────────────────────────┐
         ▼                                            ▼                                            ▼
 ┌───────────────┐                           ┌────────────────┐                           ┌───────────────┐
 │ Visitor List  │                           │  Registration  │                           │  Scan QR Code │
 └───────┬───────┘                           └────────┬───────┘                           └───────┬───────┘
         │                                            │                                            │
         │ Tap Card                                   │ POST /visitors                             │ Camera scan ID
         ▼                                            ▼                                            ▼
 ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────|
 │                                         Visitor Details Screen                                          │
 │               (Displays Info, Rendered QR Code, Timestamps, Dynamic Check-In/Out Button)                │
 └────────────────────────────────────────────────────┬────────────────────────────────────────────────────┘
                                                      │
                                    ┌─────────────────┴─────────────────₂
                                    ▼                                   ▼
                          [ Action: Check-In ]                [ Action: Check-Out ]
                          - Allowed if "Registered"           - Allowed if "Checked In"
                          - Record checkInTime                - Record checkOutTime
                          - PATCH status="Checked In"         - PATCH status="Checked Out"
                                    │                                   │
                                    └─────────────────┬─────────────────┘
                                                      ▼
                                      [ Sync State & Refresh Dashboard ]
```
## 📸 App Screenshots

### Dashboard
![Dashboard](screenshots/dashboard.png)
 
### Visitor List
![Visitor List](screenshots/visitor_list.png)

### Visitor Registration
![Visitor Registration](screenshots/registration.png)

### Visitor Details
![Visitor Details](screenshots/visitor_details.png)

## Architectural Highlights
- Immutability & Safety: Models utilize custom const constructors and unmodifiable list wrappers (List.unmodifiable) to guarantee data integrity across widget boundaries.
- Error Boundaries: Network exceptions and malformed responses are captured by VisitorApiException and communicated cleanly via UI SnackBar alerts, preventing unhandled crashes.
- Optimized Search: Local in-memory filtering prevents unnecessary API requests during typing, offering instant real-time search results.

## Future Implementation Roadmap & Advanced Architecture
- 1. Dedicated Refresh Button on Dashboard
Implementation: Wrap the dashboard layout inside a RefreshIndicator (pull-to-refresh) and add an IconButton in the AppBar tied to an explicit provider.loadVisitors() async call. This gives operators manual control to force-sync records with the server on demand.
- 2. Active Sorting & Offline Support (Local Caching)
Active Sorting: Modify the visitor listing selector to automatically sort active visitors (Checked In / Registered) to the top of the list in descending chronological order by timestamp.
Offline Availability: Integrate Hive or Isar (lightweight NoSQL local databases for Flutter). When loadVisitors() runs successfully, cache the JSON payload locally. If network connectivity drops, the app falls back to rendering cached local data, allowing security guards to view records and queue actions offline.
- 3. Secure & Proprietary QR Code Parsing
Problem: If a standard QR scanner app (like phone camera or third-party scanner) scans the visitor pass, exposing a raw plain-text ID (VIS001) or URL could pose security risks.
Solution: Encrypt or structure the QR code payload into a proprietary application scheme (e.g., sumadhura://visitor?id=VIS001&sig=HMAC_SHA256_HASH).
When scanned by external general-purpose QR readers, the phone will fail to open it or show an unrecognized link.
Only your custom mobile_scanner implementation inside the Visitor Management App will register the custom URI scheme, validate the cryptographic signature (sig), extract the visitor id, and successfully parse the record.
- 4. Share Intent on QR Code Pass
Implementation: Integrate the share_plus package. Add a "Share QR Pass" action button on the Visitor Details screen. This invokes the native platform share sheet, allowing front-desk personnel to instantly forward the visitor's digital QR pass via WhatsApp, Email, or SMS.
- 5. Server-Side Search Optimization (Enterprise Scale)
Problem: Client-side search (filtering in memory) fails when databases grow to millions of rows.
Solution:
Debouncing: Attach a 300ms debounce timer to the search bar so API requests are only sent after the user finishes typing.
Backend Indexing & Pagination: Offload search parameters to the backend (GET /visitors?search=Rahul&page=1&limit=20), utilizing database indexes (such as PostgreSQL B-Tree indexes on mobile and name) alongside full-text search engines like Elasticsearch for sub-millisecond lookups.
- 6. Transitioning from REST to WebSockets for Multi-Guard Concurrency
Why REST Falls Short at Scale: REST is stateless and request-response based. If Guard A checks in a visitor, Guard B's dashboard remains static until they manually refresh.
The WebSockets Solution:
Replace HTTP polling with a persistent, bidirectional WebSocket connection (or Firebase/Supabase real-time data streams).
When multiple security guards check in or delete visitors concurrently across different gates, the server broadcasts state deltas instantly down the socket to all connected terminals.
Optimistic Locking: Implement version numbers (version column) on database rows to prevent race conditions when two guards attempt to update the same record at the exact same millisecond.

## 👨‍💻 Author

**Shivam Kumar / Shivam Singh**  
Mobile Application Developer [Android | iOS | Unity]

- **Email:** shivamkumar99852@gmail.com
- **GitHub:** [@biophile2241](https://github.com/biophile2241)

For questions, collaboration, or permission to use this project, please contact me.

## ⚖️ Usage & Copyright

© 2026 Shivam Kumar. All rights reserved.

This project is published for portfolio, demonstration, and evaluation purposes only.

Viewing or accessing this repository does not grant permission to copy, modify, redistribute, publish, or use its source code, in whole or in part, for personal or commercial projects without prior written permission from the author.

For permission or licensing inquiries, please contact me directly.

**Note:** This notice expresses the author's intended restrictions. Its legal effect depends on applicable law and the circumstances of publication.
