![CipherBench logo: an open C and a highlighted cipher tile](docs/branding/cipherbench-mark.svg)

# CipherBench

**A Windows workbench for Science Olympiad Codebusters practice.** Solve aristocrats, patristocrats, and xenocrypts with a physical keyboard. Adjust puzzle zoom, use hints and word-pattern lookup, and track your progress.

CipherBench is a Windows-focused fork of an earlier cryptogram project. See [credits and upstream provenance](CREDITS.md).

> **Release status:** We can keep improving and building the Windows app locally, but there is no public binary release. The upstream README calls the code MIT-licensed without providing the complete notice, and rights to several bundled assets remain unverified. Public release publication stays gated until those issues are resolved; see [licensing and credits](#licensing-and-credits).

---

## 🚀 Features

- 🖥️ **Windows desktop play**
  - Resize or maximize the window; puzzle rows use the available width and stay centered.
  - Zoom puzzles from 75% to 200% in 5% steps. Row spacing is increased at the new 100% baseline without growing further as you zoom.
  - Use a physical keyboard (no on-screen game keyboard), shortcut help, and mouse-accessible Undo and Reset. Reset asks for confirmation.
  - A second launch brings the running window back instead of opening another copy.

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

## 🖥️ Windows (build locally)

Install Flutter and Visual Studio's **Desktop development with C++** workload, then run from the repository root:

```powershell
flutter pub get
flutter build windows --release
```

Launch `build\windows\x64\runner\Release\cipherbench.exe`. Keep the entire `Release` folder together: the executable requires the neighboring DLLs and `data` directory. If running a copy elsewhere, replace that entire folder after rebuilding. No prebuilt Windows download is provided here yet. On a PC without the required Visual C++ runtime, install the current Microsoft Visual C++ Redistributable (x64).

The window opens at a 1100 × 720 client area, adjusted to fit the monitor's work area at its current DPI. It can be resized or maximized, with a minimum client area of 800 × 600 logical pixels. Windows uses a physical keyboard without an on-screen game keyboard.

To check single-instance behavior and shutdown, review and run `powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File test\windows_shutdown_test.ps1`. This execution policy applies only to that PowerShell process and cannot override an enforced organization policy.

### Local single-file installer

After building the Windows Release folder, install [Inno Setup 6](https://jrsoftware.org/isinfo.php) on the build PC and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File installer\build.ps1
```

This creates `build\windows-installer\CipherBench-2.0.0-Windows-x64-Setup.exe`. Copy **just that one EXE** to another Windows 10+ x64 PC and run it there; it installs per user and adds a Start Menu shortcut. Flutter, Visual Studio, and a separate Visual C++ redistributable are not needed on the destination PC. The build PC needs Visual Studio's C++ workload to provide the app-local runtime DLLs. The installer is unsigned and intended only for personal use while the original license notice and bundled-asset rights remain unresolved; it is **not** a public release.

---

## 🛠 Tech Stack

Built with:

- **Flutter**
- **Riverpod** – for state management
- **Hive** – for local storage and persistence

---

## 📦 Windows release status

The [Windows release workflow](.github/workflows/windows-release.yml) can check builds on manual runs without publishing them. Packaging and draft-release creation require a version tag and explicit approval. The local installer above is **not** a published GitHub Release.

Before enabling public release packaging, obtain the original MIT copyright and permission notice or written authorization, add an accurate root `LICENSE`, and verify the rights to bundled audio, quotes, word lists, and the original image (or replace assets whose rights cannot be established). Complete the [third-party notices](THIRD_PARTY_NOTICES.md) and remove its `RELEASE_BLOCKED` marker only after those checks. Then set `WINDOWS_RELEASE_APPROVED` to `true` and push a tag such as `v2.0.0`; its version must match `pubspec.yaml` and `installer\CipherBench.iss`. The workflow creates a **draft** Windows-only release for review, not an automatically published one.

---

## Licensing and credits

Maintained by [@lostinsea](https://github.com/lostinsea). See [credits and upstream provenance](CREDITS.md) and [third-party notices](THIRD_PARTY_NOTICES.md).

The upstream README describes its code as MIT-licensed, but it does not include the complete copyright and permission notice required with MIT-licensed copies. **Do not publish a Windows binary until the original notice or authorization is obtained and bundled-asset rights are confirmed.** Adding our own MIT file or crediting the original creators would not resolve missing upstream permissions or third-party asset licenses. Local development can continue while we work through these checks.

---

## 📌 Note

This app is not affiliated with or officially endorsed by Science Olympiad. It is a fan-made educational tool designed to support students competing in the Codebusters event.
