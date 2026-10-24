# Regfate — Visual Life Timeline

[![Google Play](https://img.shields.io/badge/Google_Play-Download-green?logo=google-play&logoColor=white)](https://play.google.com/store/apps/details?id=com.regfate.life)

**Regfate** is a commercial mobile application published on the Google Play Store. It is a visual planner designed for people who think beyond today — turning long-term goals and life events into a continuous, interactive timeline. 

Built entirely solo with Flutter and Dart.

## 🚀 Features
*   **Period Ruler:** Place goals on a curved timeline arc.
*   **Year Ring:** Visualize your position within the current year.
*   **Entire Life:** A full life-span timeline view.
*   **24-Hour Clock:** Custom analog day view.
*   **Calendar Notes & Quotes:** Offline journaling and personal thoughts.

## 🛠 Tech Stack
*   **Framework:** Flutter
*   **Language:** Dart
*   **UI/UX:** CustomPainter (complex mathematical UI rendering), Custom Animations
*   **Data Storage:** SharedPreferences (100% Offline-first architecture)
*   **State Management:** setState, ValueListenableBuilder
*   **Tools:** Git, Google Play Console

## 🧠 Architecture & Engineering
The application is built with an offline-first approach. There are no backend requests, no user accounts, and no third-party tracking. All user data is securely stored locally on the device using `SharedPreferences`. 
A significant portion of the UI (like the curved ruler and clock faces) is drawn from scratch using `CustomPainter` and trigonometry to ensure high performance and a unique visual identity across all screen sizes.

## 📱 App Status
Published and available on Google Play. Actively maintained and developed.
