# Godot Input Wiring Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect all static Godot UI controls that currently ignore clicks.

**Architecture:** Keep existing scene signal connections. Add only missing connections in `Main.gd` through one idempotent helper, so runtime-created controls remain unchanged and duplicate connections are avoided.

**Tech Stack:** Godot 4.7, GDScript, headless SceneTree regression test.

## Global Constraints

- No Firebase integration in this fix.
- Preserve local save paths `user://save_data.json` and `user://leaderboard.json`.
- Do not alter gameplay formulas.

---

### Task 1: Add failing input-wiring regression test

**Files:**
- Create: `tests/input_wiring_test.gd`

- [x] **Step 1: Write test**

The test loads `main.tscn`, checks required buttons, and requires each to have a `pressed` connection targeting the expected `Main.gd` method.

- [x] **Step 2: Run test and verify failure**

Run: `godot --headless --path . --script res://tests/input_wiring_test.gd`

Expected: FAIL listing missing D-pad, combat, tower, PvP, raid, arena, soul, and black-market connections.

### Task 2: Connect missing controls

**Files:**
- Modify: `scripts/Main.gd:110-140`
- Test: `tests/input_wiring_test.gd`

- [x] **Step 1: Add idempotent connection helper**
- [x] **Step 2: Connect every missing static control to its existing handler**
- [x] **Step 3: Run regression test and verify PASS**

Run: `godot --headless --path . --script res://tests/input_wiring_test.gd`

Expected: `INPUT_WIRING_TEST_PASS` and exit code 0.

### Task 3: Verify project load and runtime safety

**Files:**
- No additional files.

- [x] **Step 1: Run project check**

Run: `godot --headless --path . --check-only --quit`

Expected: exit code 0.

- [x] **Step 2: Run main scene headlessly**

Run: `godot --headless --path . --quit-after 3`

Expected: exit code 0 with no script error.
