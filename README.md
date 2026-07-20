Here is a clean, professional, and comprehensive `README.md` formatted specifically for GitHub. It highlights your new architecture, documents the commands, and properly attributes the addon's lineage.

---

# FastCS2

An elegant, lightweight framerate uncap utility for **Ashita v4**.

FastCS2 monitors active cutscenes, transitional events, and zone boundaries in *Final Fantasy XI* to automatically disable the default frame rate cap (`/fps 0`), restoring your configured default frame rate immediately when you return to control of your character.

Based on the Ashita v4 port by Spike2D (originally a Windower plugin by Cairthenn), this version features a **completely rewritten packet-handling and zoning engine** designed to eliminate persistent frame rate leaks, specifically during mounted transitions, transport lines, and multi-stage cutscenes.

---

## 🚀 Key Enhancements in This Rewrite

* **Deterministic Zoning Lifecycle:** Replaced volatile status-mask parsing with a rock-solid network-and-memory bridge. The addon triggers acceleration immediately upon receiving a `0x00A` map initialization packet and safely recaps the frame rate only after verifying your character's data is stable in the client's memory.
* **Chocobo & Mount Edge-Case Fix:** Resolves the classic "stuck uncapped" bug that occurs when entering a new zone while actively mounted or renting a Chocobo.
* **Typo & Exclusion Fix:** Corrected an exclusion list processing crash, ensuring that targets like Home Points, Survival Guides, and Waypoints filter out cleanly.

---

## 🛠️ Installation

1. Download or clone this repository.
2. Place the `FastCS2` folder into your Ashita v4 directory under `/addons/`.
3. Load the addon ingame using the Ashita command:
```text
/addon load FastCS2

```



*(To ensure it always runs, add `/addon load FastCS2` to your Ashita boot script).*

---

## 🎮 Commands & Configuration

FastCS2 provides a dynamic in-game configuration menu. All changes are saved automatically to your settings file.

| Command | Description |
| --- | --- |
| `/fastcs help` | Displays the command menu in the chat log. |
| `/fastcs fps 30 , 60 , uncapped` | Sets your default preferred frame rate after an event ends. |
| `/fastcs frameratedivisor 2 , 1 , 0` | Alternately sets your preferred frame rate via Ashita divisor metrics (`2` = 30 FPS, `1` = 60 FPS, `0` = Uncapped). |
| `/fastcs exclusion add "Target Name"` | Appends an NPC/Object to the exclusion list (e.g., `/fastcs exclusion add "Home Point"`). |
| `/fastcs exclusion remove "Target Name"` | Removes an NPC/Object from the active exclusion list. |

---

## 📜 Technical Details

FastCS2 intercepts inbound packets to evaluate state transitions safely before they render to your screen:

* **`0x00A` (Map Initialization):** Instantly forces an uncap to accelerate zone loading times.
* **`0x032` / `0x034` (Event Init):** Detects interactive cutscenes and validates them against your custom exclusion targets before engaging the frame uncap.
* **`0x037` & Memory Interception:** Smoothly handles post-cutscene transitions and standard idling checks.
* **`0x052` (Event Finish):** Serves as a definitive hardware boundary to safely drop the engine back down to your preferred default frame rate.

---

## 👥 Credits

* **War3zlod3r** — Core engine rewrite, memory validation architecture, and mount state handling.
* **Spike2D** — Initial Ashita v4 translation boilerplate.
* **Cairthenn** — Original concept and implementation for the Windower platform.
