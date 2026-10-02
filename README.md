# Glow: Your Skin Companion

**Glow** is a mobile app that helps people build a simple, safe skincare routine. You take a quick photo of your face, answer a few questions, and Glow suggests a morning and evening routine for you. You can then save that routine, tick off your steps each day, and watch your streak grow.

This is a prototype made for **ENGR489 at Victoria University of Wellington (2026)**. The main question behind it:

> *How should an AI explain its advice, and how sure it is, so that people can understand and trust it appropriately?*

> **Important:** Glow gives general skincare guidance only. It is **not** a doctor and can't diagnose anything. If something looks or feels medically wrong, please see a healthcare professional.

---

## What you can do in Glow

**Scan your skin**
The camera guides you to take three photos (straight on, turned left, turned right). It waits until your face is in the right spot before letting you take each one.

**Answer a few questions**
Things like your age group, skin type, your main concern (acne, redness, dryness, irritation), and whether you're pregnant. Before anything is sent, Glow tells you exactly where your photo goes and asks for your OK.

**Get a routine**
Glow suggests simple morning and evening steps and tells you **how confident** it is, either in words ("Fairly confident") or as a percentage. You can switch between the two. If your answers suggest a higher-risk situation, Glow won't guess: it gently suggests seeing a professional instead.

**Chat instead, if you prefer**
Not in the mood for a photo? Just describe your skin in the chat. Glow asks follow-up questions like a friend would, then gives you a routine the same way.

**Save it and track it**
Save any routine you like. Each day, tick off the steps you've done. Your **streak** shows on the Home page and as a small flame badge on the Routine tab, and there's a calendar showing every day you kept it up.

**Make it yours**
Add a profile photo, pick a username, and note your skin type and any allergies. Glow uses these to tailor future suggestions and avoid ingredients you've said you react to.

---

## Your privacy

- Your scan photo is sent securely (over HTTPS) to Google's Gemini AI so it can be analysed.
- **Glow doesn't keep your scan photos.** They're deleted from your phone when you finish, and our server only holds them in memory long enough to get an answer.
- Your routines, logs and skin profile are stored in a database where **only you can see your own data**.
- No secret keys are stored inside the app.

---

## How to run it 

If you're new to Flutter. Just follow these steps in order.

### What you'll need
- A computer with **[Flutter](https://docs.flutter.dev/get-started/install)** installed
- **Android Studio** or **VS Code** (either is fine)
- An **Android phone** (with USB debugging turned on) or an Android emulator. A real phone works best, because the scan uses the camera.

### Step 1: Download the project
```bash
git clone <this-repo-url>
cd <the-project-folder>
```

### Step 2: Install the packages the app uses
```bash
flutter pub get
```

### Step 3: Plug in your phone and run
```bash
flutter run
```
The first build can take a few minutes. That's normal.

### Step 4: Create an account
When the app opens, sign up with any email and password, and you're in!

### Notes
- **The first AI response might be slow.** The server sleeps when nobody's using it, so the first scan or chat after a break can take 30–50 seconds while it wakes up. After that, it's quick.
- The app talks to the backend at the address in `lib/services/api_service.dart`. If you run your own backend, change `baseUrl` there.
- Accounts and data are handled by Supabase, set up in `lib/main.dart`.

---

## How it's built (for the curious)

- **App:** Flutter (tested on a Pixel 6)
- **AI:** Google Gemini, reached through our own FastAPI backend (in a separate repository)
- **Accounts and data:** Supabase (login, database, profile photos)
- **Face positioning:** Google ML Kit, running on the phone

### Where things live
```
lib/
├── main.dart          - Starts the app
├── screens/           - Every page you see (home, scan, chat, routine, profile…)
└── services/          - Talking to the backend and the database
```

A few handy files:
- `screens/scan_screen.dart`: the guided camera
- `screens/scan_questions_page.dart`: the questions, consent and result
- `screens/chat_conversation.dart`: the AI chat
- `screens/routine_page.dart`: daily routine ticking
- `services/api_service.dart`: everything that talks to the AI backend

---



---

Made with care for ENGR489, Victoria University of Wellington, 2026.