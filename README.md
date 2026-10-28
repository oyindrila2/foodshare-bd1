# FoodShare BD (frontend + backend)

- `frontend/` React app (Vite + Leaflet maps)
- `backend/`  FastAPI + SQLite API (PostgreSQL also works)

> **Do not double-click `index.html`.** The app only works through the server. Use one of the ways below and
> open **http://localhost:5000**.

## Version 5: machine learning + 8 new features

| Feature | Where | How to try it (demo password `demo123`) |
|---------|-------|-------------------------------------------|
| **ML 1: unclaimed-food risk** | `backend/ml`, donor card, donation page, admin → *Machine learning* | Post food as `donor@foodshare.bd`: the card shows "Unclaimed risk: low/medium/high". High risk alerts admins and starts NGO rescue after `ML_EARLY_RESCUE_MIN` (10) minutes instead of waiting the normal 60. |
| **ML 2: volunteer acceptance** | volunteer offers, admin → *Machine learning* | Accept a donation with "request a volunteer": volunteers are ranked by feasibility **and** predicted acceptance, with a fairness penalty. Nobody is assigned without accepting. If the model is missing, the rule-based ranking is used. |
| **Rule-based food safety** (not ML) | `backend/app/ai/food_risk.py` | Expiry date is never extended; an expiry in the past blocks the food; contradictions (frozen but warm, hot-holding but cold) are flagged. |
| **QR/OTP handover** | receiver: *Show handover code*; volunteer: code box | Receiver opens a 6-digit code + QR. The volunteer types it (or scans the QR, which opens `/handover`). Only a valid, unexpired, unused code completes the delivery. 5 wrong tries lock the code. |
| **বাংলা / English** | top bar on every page | Click **বাংলা**. The choice is remembered after reload. |
| **Event surplus pre-booking** | donor → *Event pre-booking*; receivers see *Upcoming event surplus* | Planned → (organisation coordinates, saves a pickup plan) → donor clicks *The food is ready: confirm it* → a real donation is created and the food safety check runs again. Cancel/edit only until 60 min before. |
| **Donor impact report + PDF** | donor → *Impact report*; admin → *Impact reports* | Only real, completed, confirmed handovers count. Demo and simulated data are excluded. No CO₂ figure (no validated method). |
| **Donation editing** | donor dashboard → *Edit* | While nobody has accepted it, the donor can correct quantity, servings, available-until, notes. The declaration must be ticked again and the safety check and ML score run again. |
| **Pickup photo evidence** | volunteer task → *Take / add pickup photo* | Required before "Mark as collected". Stored in `backend/private_uploads` (never public), viewable only by the donor, receiver, volunteer and admins of that donation, and in admin complaint review. |

### Machine learning: data, scripts, results

There is no real history yet, so both models are first trained on **simulated** data (fixed seed 42), stored only in
`backend/ml/data/*.csv` with `data_source=simulated`. Simulated rows never go into the app database, the impact
report or the public impact page.

```bat
cd backend
venv\Scripts\activate
python -m ml.simulate     REM create the simulated CSV files (3,500 donations, 2,600 offers)
python -m ml.train        REM train both models, save pipelines + reports
python -m ml.evaluate     REM reload the saved models and recompute the test metrics
```

Results on the held-out **time-based** test set (last 15% by time; never used for training or the threshold):

| Model | Positive class (1) | Chosen | ROC-AUC | Precision | Recall | F1 | Threshold |
|-------|--------------------|--------|---------|-----------|--------|----|-----------|
| Unclaimed-food risk | still unclaimed at its deadline | HistGradientBoosting (LogReg baseline: 0.778) | 0.804 | 0.574 | 0.620 | 0.596 | 0.51 |
| Volunteer acceptance | accepted within the response window (declined and timed-out = 0) | Logistic Regression | 0.815 | 0.590 | 0.622 | 0.605 | 0.54 |

**These numbers measure how well the models recover the simulator's own assumptions, not real-world accuracy.**
API for the new features: `docs/API_V5.md` (all endpoints: http://localhost:5000/docs).
Full reports with confusion matrices: `backend/ml/reports/`. Label assumptions: `backend/ml/simulate.py` and
`backend/ml/data/README.txt`. Admin → *Machine learning* → *Retrain on real data* is refused until there are at least
`ML_MIN_REAL_ROWS` (200) real records with both classes; a real-data model with test ROC-AUC below 0.65 (or worse than
the current model) is rejected and the old model stays active. Every run is logged in the training history.

### Which records are simulated, demo or real

| Kind | Where | Marked as | Counts in impact report? |
|------|-------|-----------|--------------------------|
| Simulated ML training data | `backend/ml/data/*.csv` only | `data_source=simulated` | Never |
| Demo accounts and demo donations | app database (`@foodshare.bd` accounts) | `dataSource: demo`, "demo" tag | Never |
| Everything users create | app database | `dataSource: real` | Only if completed and confirmed |

## Earlier features (version 4)

| Area | What it does |
|------|--------------|
| Contact numbers | Bangladeshi mobile validation (013–019), Call (`tel:`) and Copy buttons, "Verified/Unverified" badge. Numbers are sent **only** to the donor, receiver and assigned volunteer of an active donation (and admins). Fixes an old leak where every receiver could see donors' phone and email. |
| Donation form | Food type, servings, storage temperature, minutes outside fridge/hot holding, packaging, 8 allergens or "I don't know", handling notes, exact pickup pin (map click or GPS), photo, notes. Unknown fields stay empty and are marked as missing. |
| Food safety | Rule-based check with sources (WHO Five Keys, USDA danger-zone 2 h / 1 h above 32 °C, damaged packaging, FoodShare 12 h / 6 h rule). Statuses: *Safety Not Verified*, *Urgent Pickup*, *Caution — Review Required*, *Do Not Distribute — Safety Review Required* (held for an admin). Never says "safe". |
| Volunteer matching | Automatic offers to on-duty volunteers ranked by feasibility (spare time, time to donor, workload, service area, live location), accept/decline, timeout, atomic accept (only one volunteer can win). |
| Feasibility alerts | *Nearby / Feasible*, *Caution*, *High Risk / Not Feasible*, kept separate from food safety. |
| Reassignment | Volunteer cancels → next volunteers are offered automatically; nobody who declined is asked again; stops and alerts donor, receiver and admin if no delivery can make it in time. |
| Live location | Consent-based, only during an accepted task, only for that donor/receiver/admin; stale/denied/offline handling; ETA; deleted after 24 h. |
| Routes | OSRM road routes with alternatives (backend calls it, no key in the frontend), Google Maps / OpenStreetMap navigation links, clear fallback to an estimate. |
| Statuses | Available → Volunteer Assigned → Pickup In Progress → Collected From Donor → Delivery In Progress → Delivered To Receiver → **Completed only when the receiver confirms**. Also Cancelled, Expired, Safety Review Required. |
| Cancellations | Donor, receiver and volunteer, each with a reason, history kept, participants notified. |
| Reviews | Receiver rates donor (accuracy, packaging, communication, overall) and volunteer (punctuality, communication, handling, delivery), 1–5 stars, comment, one review each, report and admin moderation. |
| Reminders | Unclaimed-food reminders after posting and before the deadline, stored in the database, sent once, cancelled when obsolete. |
| NGO rescue | Unclaimed food near its deadline is offered to verified nearby organisations (registered receivers: NGOs, shelters, food banks, community kitchens …) that accept that food, have capacity and are open. Accepting is *not* delivering. |
| Admin console | New tabs: food safety queue (approve with note / reject), volunteer assignments + offers + cancellations, NGO rescue, deliveries and confirmations, reported reviews, notification channels and failures, reminders, audit log; phone verification; "Run background jobs now". |
| Background jobs | Every minute inside the server: expiry, capacity reset, food-risk re-check, offer timeouts/reassignment, rescue, reminders, email outbox, location retention. Idempotent, restart-safe, one runner at a time (database lease). |

## Run on Windows

Needs **Python 3.10+** (tick "Add python.exe to PATH"). The website is already built into `backend/web`
(self-contained, works offline except map tiles and fonts), so **Node.js is only needed if you change the frontend code**.

### Easiest: double-click

1. Double-click `start-windows.bat`.
   The first time it creates the Python environment, installs packages (including pandas and scikit-learn, a few
   minutes) and opens http://localhost:5000. If you edited the frontend, run `build-frontend-windows.bat` first.
2. Keep the black window open. Close it to stop the server.

### Manual (Command Prompt)

```bat
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --port 5000
```

Open http://localhost:5000 (API docs: http://localhost:5000/docs).

### Developer mode (hot reload)

Terminal 1:
```bat
cd backend
venv\Scripts\activate
uvicorn app.main:app --reload --port 5000
```
Terminal 2:
```bat
cd frontend
npm install
npm run dev
```
Open http://localhost:5173 (`frontend/.env` points to the API on port 5000). After changing frontend code run
`build-frontend-windows.bat` again so http://localhost:5000 serves the new version.

### Tests

Double-click `run-tests-windows.bat`, or:
```bat
cd backend
venv\Scripts\activate
pip install -r requirements-dev.txt
pytest -q
```
Tests use a temporary database; your `foodshare.db` is not touched. Latest results: `TEST_RESULTS.txt`
(67 automated tests passed). What was tested automatically, by browser, or not at all: `docs/TESTING_AND_TROUBLESHOOTING.md`.

Mac/Linux: `bash start-mac-linux.sh`, `bash build-frontend.sh`.

## Demo accounts (password for all: demo123)

| Role | Email |
|------|-------|
| Donor | donor@foodshare.bd, wedding@foodshare.bd |
| Receiver / organisation | receiver@foodshare.bd, ngo@foodshare.bd, night@foodshare.bd, kitchen@foodshare.bd, pantry@foodshare.bd |
| Volunteer (on duty) | volunteer@foodshare.bd, volunteer2@foodshare.bd |
| Admin | admin@foodshare.bd |
| Waiting for admin approval | newngo@foodshare.bd, newvol@foodshare.bd |

Demo phone numbers look like +8801700000001; they are made up. **To get the new demo data, stop the server and
delete `backend/foodshare.db`** (an existing database is upgraded instead and keeps its data; see below).

## How to test each new feature (about 15 minutes)

Use three browser windows (normal + private + another browser) to be donor, receiver and volunteer at the same time.

1. **Phone privacy**: log in as `ngo@` → Find food: cards show "Phone shown only while you work on this donation together". Accept one as `receiver@` → the donor (`donor@`, My donations) now sees the receiver's Call/Copy buttons, and the receiver sees the donor's.
2. **Profile and validation**: Profile → enter `12345` → error; `01712345678` → saved as +8801712345678, "Unverified". Admin → Users → "Mark verified".
3. **Food safety**: Post food as `donor@` with Storage *Room temperature*, Prepared 2 hours ago → the live check shows *Do Not Distribute*; after posting it is "Held for safety review" and hidden from receivers. Admin → Food safety → write a note → Approve (or Reject). Post with Storage *Not sure* → *Safety Not Verified* with the missing fields listed.
4. **Automatic volunteer offer**: `receiver@` accepts food with "request a volunteer" → `volunteer@` and `volunteer2@` see it under **Offered to you** with feasibility and ETA. Accept with `volunteer@`; `volunteer2@`'s offer disappears (only one can win).
5. **Statuses and confirmation**: as volunteer: Start trip → Mark as collected → Start delivery → Mark as handed over. The donation is *Delivered, waiting for receiver*; it becomes *Completed* only after the receiver clicks **Confirm food received**.
6. **Live location**: volunteer → "Live location sharing: Turn on" → allow the browser prompt. Donor/receiver → "Show volunteer live location" (map, last update, ETA). Deny the permission to see the error message. Complete the task → tracking stops.
7. **Volunteer cancellation and reassignment**: during an assigned task, volunteer → Cancel this delivery → reason. The donor and receiver are notified, and the other volunteer gets an offer automatically. Admin → Volunteer assignments shows both rows.
8. **Receiver / donor cancellation**: receiver → Cancel request → the food is available again (if there is time and no safety block). Donor → Cancel donation (reason required). After the food was collected the donor gets "sent to the admin team" instead.
9. **Reviews**: after completion the receiver reviews donor and volunteer. A second review is refused. The volunteer → Profile → Report the review. Admin → Reviews → Hide.
10. **Reminders and NGO rescue**: post food and leave it. After 30/60 min (or set `REMINDER_AFTER_POST_MIN=1,2` and `RESCUE_AFTER_POST_MIN=2` before starting, or press Admin → "Run background jobs now") the donor gets reminders and verified nearby organisations get a **rescue request** (log in as `night@` or `kitchen@`). Accepting makes it *accepted*, not delivered.

## Settings (environment variables)

Easiest: copy `backend/.env.example` to `backend/.env` and edit it (the server reads it at start-up; real
environment variables win). Or set them before starting, e.g. `set RESCUE_AFTER_POST_MIN=2`.
Version 5 settings (ML, handover codes, photos, events) are listed with comments in `backend/.env.example`.

| Name | Default | What it does |
|------|---------|--------------|
| `SECRET_KEY` | demo value | Signs login tokens. Change it before real use. |
| `DATABASE_URL` | `sqlite:///./foodshare.db` | Database. A PostgreSQL URL also works. |
| `SEED_DEMO_DATA` | `true` | Fill an empty database with demo accounts and food. |
| `INCLUDE_SAMPLE_BASELINE` | `true` | Impact page adds sample "before launch" figures. |
| `JOB_INTERVAL_SECONDS` | `60` | How often background jobs run. `RUN_BACKGROUND_JOBS=false` turns them off. |
| `VOLUNTEER_OFFER_BATCH` / `VOLUNTEER_OFFER_TIMEOUT_MIN` | `3` / `10` | Volunteers offered at once / minutes before the next ones are asked. |
| `CAUTION_SLACK_MIN`, `CAUTION_PICKUP_KM`, `HANDLING_MIN` | `30`, `8`, `10` | Feasibility thresholds. |
| `RUSH_HOURS`, `RUSH_HOUR_FACTOR` | `8-11,17-21`, `1.4` | Fixed rush-hour slow-down (an estimate, **not** live traffic). |
| `ROUTING_PROVIDER`, `OSRM_URL` | `osrm`, public demo server | `estimate` turns road routing off. Run your own OSRM for heavy use. |
| `AMBIENT_TEMP_C` | `32` | ≥ 32 °C uses the 1-hour danger-zone limit, otherwise 2 hours. |
| `PLANNED_HANDOVER_MIN`, `URGENT_SAFE_WINDOW_MIN` | `60`, `90` | Assumed time to reach a receiver; "Urgent" threshold. |
| `REMINDER_AFTER_POST_MIN`, `REMINDER_BEFORE_DEADLINE_MIN` | `30,60`, `60` | Donor reminder schedule. |
| `NO_VOLUNTEER_REMINDER_MIN` | `20` | Tell donor/receiver no volunteer was found yet. |
| `RESCUE_AFTER_POST_MIN`, `RESCUE_BEFORE_DEADLINE_MIN` | `60`, `90` | When automatic NGO rescue starts. |
| `RESCUE_OFFER_BATCH`, `RESCUE_OFFER_TIMEOUT_MIN`, `RESCUE_ORG_TYPES` | `3`, `15`, NGO,… | Rescue offers. |
| `LOCATION_RETENTION_HOURS` | `24` | Live-location points are deleted after this. |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM`, `SMTP_STARTTLS` | empty | Email copies of important notifications (only if `SMTP_HOST` is set). |
| `UPLOAD_DIR`, `MAX_IMAGE_BYTES` | `uploads`, 2 MB | Food photos. |

No API key is needed for anything that is turned on by default.

## Database changes

Nothing is deleted or reset. At start-up `app/migrations.py` compares the models with the database and runs
`ALTER TABLE … ADD COLUMN` for missing columns (SQLite: a copy `foodshare.db.backup-YYYYMMDD-HHMMSS` is saved first),
then `create_all` adds the new tables. Old volunteers are set "on duty" (they could take any task before), old
donations get a food type from their category, and valid phone numbers are stored as +8801XXXXXXXXX.

- **users** (new columns): phone_verified, phone_verified_at, accepting_rescue, service_radius_km, open_from, open_until, on_duty, service_areas, max_km, max_active_tasks, location_consent, last_lat, last_lng, last_location_at
- **donations** (new columns): servings, address, food_type, storage_temp_c, outside_fridge_min, packaging, handling_notes, allergens_unknown, image_path, notes, risk_level, risk_assessment, risk_checked_at, safe_until, safety_override_by, safety_override_note, assignment_state, assignment_round, picked_at, delivered_at, cancel_reason, cancelled_by_role, cancelled_at, rescue_state
- **notifications** (new columns): kind, important
- **Version 5 (donations, new columns)**: data_source (real/demo), expiry_date, event_id, ml_features, ml_unclaimed_prob, ml_unclaimed_level, ml_model_version, ml_scored_at; **task_offers**: ml_accept_prob, ml_model_version, ml_features
- **Version 5 new tables**: handover_codes (hashed code + token, single use, expiry, attempts), pickup_photos (file name, size, SHA-256, uploader), event_bookings (planned/confirmed/cancelled/completed), impact_reports (generation log), ml_training_runs (who, when, data source, version, metrics, result)
- **Inspect the database**: open `backend/foodshare.db` with *DB Browser for SQLite* (free), or `python -c "import sqlite3;print(sqlite3.connect('foodshare.db').execute('select name from sqlite_master where type=\'table\'').fetchall())"`. To start fresh, stop the server and delete `foodshare.db`; demo data is created again.
- **New tables (version 4)**: task_offers (unique per donation+volunteer), volunteer_assignments, cancellations, location_pings, delivery_confirmations, rescue_offers (unique per donation+organisation), reminders (unique per donation+user+kind), reviews (unique per donation+reviewer+subject), review_reports, audit_logs, notification_deliveries

## What is fully implemented, what needs configuration, known limitations

**Implemented and working locally (no external service):** everything in the "What is new" table, with backend
validation and authorization, database persistence, background jobs and frontend screens.

**Needs external configuration:**
- **Email** notifications: set the `SMTP_*` variables (e.g. a Gmail app password). Code is in place; it was not tested against a real mail server.
- **Road routes**: the public OSRM demo server needs internet and allows only light use; without it the app shows a labelled straight-line estimate.
- **Map tiles**: OpenStreetMap tiles need internet (fine for a demo, not for heavy production use).
- **Photo storage in production**: photos are stored on the server's disk (`PRIVATE_UPLOAD_DIR`). For cloud hosting,
  mount a persistent disk there (or replace `app/utils/images.py:save_private` with S3/Cloudinary). Photos are kept
  until an admin deletes the folder; there is no automatic retention job for evidence.

**Not implemented (said honestly, not faked):**
- **SMS / WhatsApp / mobile push** notifications and **SMS phone verification (OTP)**: need a paid provider account. Phones are verified manually by an admin; the admin page shows these channels as "Not implemented".
- **Live traffic**: OSRM has no traffic data. Times use typical Dhaka speeds per vehicle and a fixed rush-hour factor. A traffic-aware API (Google Routes, TomTom, Mapbox) would need a paid key.
- **Spoilage prediction by machine learning**: there is no validated training data, so the food check is transparent rules with sources. `waste_prediction.py` only converts quantities to meals/kg.
- **Browser alerts** work only while FoodShare is open in a tab (they are not push notifications). Live location also needs the volunteer's page to stay open (browsers stop GPS in background tabs).
- If a volunteer cancels **after collecting** the food, it is not reassigned automatically (nobody else can collect it from the donor); it goes to the admin team as "Safety review required" with everyone notified.
- The "rescue organisations" are the verified receivers already registered in FoodShare; no outside list is used.
- The old in-browser mock mode (`VITE_USE_MOCK=true`) does not support the new features; they show a clear "needs the real backend" message.
- **Bangla**: every screen label is translated (582 of 582 texts). Server messages are translated when they match a
  known sentence or pattern; rare ones fall back to English. The **PDF impact report is English only**. Names and food
  descriptions typed by users are shown as typed.
- **ML models** are trained on simulated data until enough real records exist; treat their scores as experimental.
- **OTP/QR** proves the receiver confirmed the handover with their account, not physical delivery by itself.
- One server process runs the jobs (database lease). On hosts that put the app to sleep when idle (free tiers), jobs pause until the next request wakes it.

## Food safety sources

- WHO, *Five Keys to Safer Food* (keep hot food above 60 °C, cold below 5 °C, cooked food not more than 2 h at room temperature).
- USDA FSIS, *Danger Zone (40–140 °F)*: 2 hours, or 1 hour above 90 °F (32 °C).
- USDA FSIS: do not use food from damaged, swollen or leaking packages.

## Backend folder map

```
backend/app/
  main.py         start-up (migration, seed), CORS, errors, background loop, serves backend/web and /api/uploads
  migrations.py   safe "add missing columns" upgrade with backup
  jobs.py         background jobs (expiry, food risk, offers/reassignment, rescue, reminders, email, retention)
  config.py       all settings
  models/         user, donation, notification, report, app_state, workflow (offers, assignments, cancellations,
                  location, confirmations, rescue offers, reminders), review, audit
  routes/         auth (+profile), donations (donor, details, tracking, route), receivers (+rescue),
                  volunteers, reviews, notifications, admin, public
  services/       matching_service (donation life cycle), volunteer_service (matching, offers, reassignment),
                  food_risk_service, rescue_service, reminder_service, review_service, tracking_service,
                  routing_service, notification_service, urgency_service (expiry), prediction_service, distance_service
  ai/             food_risk (rules + sources), feasibility (logistics), matching_model (receiver match score),
                  urgency_model (deadline countdown), waste_prediction (meal/kg units)
  utils/          security, helpers, serializers (contact privacy), phone, images, audit
tests/            test_rules.py (no server needed), test_frontend_contract.py, test_workflows.py
```

## Before real use

- Set a new `SECRET_KEY` and remove demo accounts (`SEED_DEMO_DATA=false`).
- Replace `allow_origins=["*"]` in `backend/app/main.py` with your frontend address.
- Use PostgreSQL for many users, and your own OSRM server for routing.
