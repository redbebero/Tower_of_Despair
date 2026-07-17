# Firebase Realtime Database Migration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans (recommended) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace local JSON persistence and Mock authentication with Firebase Email/Password Auth and Realtime Database REST requests.

**Architecture:** `SaveManager.gd` owns Firebase Auth tokens, HTTP requests, character saves, and leaderboard cache. `Main.gd` reacts to auth/load signals; gameplay callers keep their existing save calls. Realtime Database paths use authenticated Firebase UID values.

**Tech Stack:** Godot 4.7 GDScript `HTTPRequest`, Firebase Auth REST API, Firebase Realtime Database REST API.

## Global Constraints

- Firebase project ID: `castle-4de5d`.
- Realtime Database URL: `https://castle-4de5d-default-rtdb.firebaseio.com`.
- No `user://save_data.json` or `user://leaderboard.json` persistence.
- Never include a Firebase Service Account private key in the client.

---

### Task 1: Add failing Firebase migration test

**Files:**
- Create: `tests/firebase_backend_test.gd`

- [x] **Step 1: Test Firebase constants and absence of local file persistence**
- [x] **Step 2: Run and verify RED**

Run: `godot --headless --path . --script res://tests/firebase_backend_test.gd`

Expected: FAIL because current `SaveManager.gd` still uses local JSON and has no Firebase configuration.

### Task 2: Replace SaveManager backend

**Files:**
- Modify: `scripts/SaveManager.gd`

- [x] **Step 1: Add Firebase Auth REST requests**
- [x] **Step 2: Add Realtime Database character CRUD**
- [x] **Step 3: Add Realtime Database leaderboard CRUD**
- [x] **Step 4: Remove all local JSON and Mock auth state**
- [x] **Step 5: Run Firebase migration test and verify GREEN**

### Task 3: Connect Main and PvP to asynchronous Firebase state

**Files:**
- Modify: `scripts/Main.gd`
- Modify: `scripts/CombatManager.gd`

- [x] **Step 1: Replace login/signup Mock timers with SaveManager auth calls**
- [x] **Step 2: Render character selection after remote saves load**
- [x] **Step 3: Fetch leaderboard before rendering rankings/PvP opponents**
- [x] **Step 4: Run project parse and headless launch checks**
