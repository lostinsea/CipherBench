# 🧠 Scioly Codebusters

A feature-rich mobile app designed to help students prepare for the **Science Olympiad Codebusters** event. It includes a wide variety of practice problems and innovative support features such as a **word pattern dictionary**, **stats tracking**, and a **modern UI** built for fast, effective learning.

---

## 🎥 Demo / Tutorial

📺 **Watch the tutorial or trailer on YouTube:**  
[Watch the video](https://www.youtube.com/watch?v=pFcTj_l7BiU)

> *The tutorial video explains how to solve a common puzzle type and showcases some of the app’s learning tools.*

---

## 🚀 Features

- 🔍 **Word Pattern Dictionary**  
  Search a word and see all words matching the same cryptogram pattern. Supports both English and Spanish.

- 📊 **Stats Tracker**  
  Compare your puzzle-solving performance across **this week**, **last week**, and **all time**.

- 🧾 **Quote History**  
  View all quotes you’ve solved, how many stars you earned, and your favorites.

- 🎮 **Multiple Game Modes**  
  Three game types: **Aristocrats**, **Patristocrats**, and **Xenocrypts** — each available in:
  - Assisted mode (with hints and tools)
  - Manual mode (to simulate real test conditions)

- 💡 **Built-In Assistance**  
  Integrated hints, dictionary suggestions, and "show correct" options to speed up learning.

---

## 📱 Installation

You can **download the app for free** on the App Store:

> 🔗 https://apps.apple.com/us/app/scioly-codebusters/id6642683299

### Windows (local build)

With Flutter and Visual Studio's **Desktop development with C++** workload installed, run `flutter pub get` and `flutter build windows --release` from this repository. Open `build\windows\x64\runner\Release\scioly_codebusters.exe` to play. Keep the entire `Release` folder together: the executable needs its neighboring DLLs and `data` directory. The Windows window starts at a 1100 × 720 client area (or fits the monitor's work area at its current DPI); drag its edges to resize or maximize it to fill the usable desktop. The minimum client area is 800 × 600 logical pixels. A second launch restores the already-running Windows window instead of starting another instance. Play using a physical keyboard; the on-screen game keyboard is not shown on Windows. Compact shortcut help and mouse-accessible Undo and Reset buttons share the bottom row; resetting by button or Ctrl+Backspace asks for confirmation before clearing answers. Puzzle rows use the available window width as it grows and are centered within it. The puzzle title bar has Zoom In and Zoom Out buttons that change puzzle size in 5% steps from 75% to 200% and reflow its rows; the new 100% baseline is 140% of the original puzzle size. At that baseline, puzzle rows have 25% more separation; the added gap stays fixed as zoom changes. The selected cell has a distinct amber outline without changing its fill. The mobile app retains its on-screen keyboard.

After reviewing the test script, run `powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File test\windows_shutdown_test.ps1` to check that a second launch exits while the first window stays open, and that closing the first window removes its process from Windows process lists. This execution policy applies only to that PowerShell process and cannot override an enforced organization policy. A build does not update copies at other locations; replace the entire old `Release` folder if you launch the app from elsewhere.

---

## 🛠 Tech Stack

Built with:

- **Flutter**
- **Riverpod** – for state management
- **Hive** – for local storage and persistence

---

## 📝 License

This project is licensed under the **MIT License** — feel free to use or adapt it with credit.

---

## 👤 Author

Created by Suvan and Manoj  
📺 YouTube Channel: YouTube Channel: [@SciolyCodebusters](https://www.youtube.com/@SciolyCodebusters)

---

## 📌 Note

This app is not affiliated with or officially endorsed by Science Olympiad. It is a fan-made educational tool designed to support students competing in the Codebusters event.
