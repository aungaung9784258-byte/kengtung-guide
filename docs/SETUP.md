# Getting the app running on your machine

You already have VS Code and IntelliJ IDEA Community — both work fine.
IntelliJ **Community** Edition fully supports Flutter (unlike web/Java work,
Flutter does *not* need Ultimate).

---

## Fast path — see the app in 20 minutes (web only)

This needs **no Android Studio, no emulator, no phone**.

### 1. Install Git
<https://git-scm.com/downloads> — accept all defaults.
(Flutter uses git internally; it will not work without it.)

### 2. Install the Flutter SDK
1. Download from <https://docs.flutter.dev/get-started/install>
2. **Windows:** unzip to `C:\src\flutter`
   ⚠️ **Not** `C:\Program Files\` — spaces in the path break Flutter.
   **macOS/Linux:** unzip to `~/development/flutter`
3. Add to PATH:
   - **Windows:** Search "environment variables" → *Edit the system environment
     variables* → *Environment Variables* → under **User variables** select
     `Path` → *Edit* → *New* → `C:\src\flutter\bin` → OK.
     **Close and reopen your terminal.**
   - **macOS/Linux:** add to `~/.zshrc` or `~/.bashrc`:
     `export PATH="$HOME/development/flutter/bin:$PATH"`

### 3. Check it
```bash
flutter --version
flutter doctor
```
`flutter doctor` will show ❌ next to Android toolchain — **ignore that for now**.
You only need ✅ on *Flutter* and *Chrome*.

### 4. Install Chrome
<https://www.google.com/chrome/> — this is how you'll run the app.

### 5. Run the project
Put the `kengtung-guide` folder somewhere like `C:\projects\kengtung-guide`, then:

```bash
cd C:\projects\kengtung-guide
flutter create . --platforms=android,ios,web --org com.kengtung
flutter pub get
flutter run -d chrome
```

The app opens in Chrome. Press **`r`** in the terminal for hot reload,
**`R`** for full restart, **`q`** to quit.

> `flutter create .` only *adds* the missing `android/ ios/ web/` folders.
> It will not overwrite `lib/`, `assets/` or `pubspec.yaml`.

---

## Editor setup

### VS Code (recommended — lighter, faster)
1. Open VS Code → Extensions (`Ctrl+Shift+X`)
2. Install **"Flutter"** by Dart Code (it pulls in the Dart extension too)
3. `File → Open Folder` → select `kengtung-guide`
4. Press **F5** to run, or bottom-right device selector → *Chrome*

### IntelliJ IDEA Community
1. `File → Settings → Plugins` → Marketplace → install **Flutter**
   (it will prompt to install **Dart** too — accept)
2. Restart
3. `File → Settings → Languages & Frameworks → Flutter` → set
   *Flutter SDK path* to `C:\src\flutter`
4. `File → Open` → select `kengtung-guide`
5. Pick a device in the top toolbar → press ▶

**Use one or the other, not both at once** — two IDEs running `pub get` on the
same folder can clash.

---

## Running on a real Android phone (the good experience)

Web is fine for layout, but **GPS, offline download and the map feel right only
on a phone.** You do *not* need an emulator — a real phone over USB is faster
and uses far less RAM.

### 1. Install Android Studio
<https://developer.android.com/studio> — accept defaults.

You are installing it **for the Android SDK, not to write code in it.**
You'll keep using VS Code / IntelliJ. It's a ~1 GB download; this is the
unavoidable part of Android development.

During first launch its setup wizard downloads the SDK — let it finish.

### 2. Accept the licences
```bash
flutter doctor --android-licenses
```
Press `y` at every prompt.

### 3. Put your phone in developer mode
1. Settings → About phone → tap **Build number** 7 times
2. Settings → Developer options → enable **USB debugging**
3. Plug into the computer, tap **Allow** on the phone popup

### 4. Run
```bash
flutter devices        # your phone should be listed
flutter run            # installs and launches on the phone
```

### Emulator instead (if no spare phone)
Android Studio → *More Actions* → *Virtual Device Manager* → create a
**Pixel 6, API 34**. Needs ~8 GB RAM to be usable. A real phone is better.

---

## iPhone

Only possible on a **Mac** with Xcode — Apple's restriction, not Flutter's.
On Windows you can still write and ship the iOS code; you just can't build it.
Not a problem for now: Android + Web covers your users.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `'flutter' is not recognised` | PATH not set, or terminal not restarted. Close **all** terminals and reopen. |
| `flutter doctor` shows ❌ Android toolchain | Normal until you install Android Studio. Web still runs. |
| Map tiles blank on web | Normal in some corporate/school networks blocking OSM. Try mobile hotspot. |
| `pub get` fails / times out | Myanmar connections can be slow to pub.dev. Retry, or set `PUB_HOSTED_URL`. |
| Red screen "RenderFlex overflowed" | Layout bug — tell me the screen name and I'll fix it. |
| Location doesn't work on web | Browser geolocation requires HTTPS. `localhost` is exempt, so `flutter run -d chrome` is fine. |

---

## What to do first

1. Get `flutter run -d chrome` working — confirms the whole project is healthy.
2. Click through: Welcome → Let's Tour → Home → tap a place → View in Map.
3. Toggle **Language** and **Theme** in the Profile tab.
4. Then install Android Studio when you want GPS + offline download to work.
