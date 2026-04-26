# 🗳️ UniVote - Election Awareness Mobile App

## 📌 Overview

UniVote is a Flutter-based mobile application designed to provide **election awareness and information** for citizens.
The app allows users to explore candidates, election campaigns, and polling stations — without offering any voting functionality.

---

## 🎯 Purpose

This application is built to:

* Educate voters about candidates and campaigns
* Provide information about polling stations
* Increase awareness before elections
* Deliver updates and notifications related to elections

> ⚠️ Important: This app **does NOT support voting**. It is strictly informational.

---

## 🚀 Features

### 🏠 Public Home Screen

* Campaign banners and promotional content
* Election updates and announcements
* Voter awareness information

### 👤 Authentication

* Login using:

  * National ID
  * Password
* No signup (accounts are managed externally)

### 👥 User Role System

* **Normal User**

  * View candidates
  * Explore campaigns
  * View polling stations (with map)
  * Receive notifications
  * View personal account info

* **Admin**

  * All user features
  * Add new candidates
  * Add polling stations
  * View statistics and analytics dashboard

---

## 📱 Main Screens

* Home Screen
* Login Screen
* Candidates List & Details
* Polling Stations (with map & GPS)
* Notifications Screen
* Account/Profile Screen
* Admin Dashboard

---

## 🧭 Navigation

* Persistent Bottom Navigation Bar:

  * Home
  * Candidates
  * Polling Stations
  * Notifications
  * Account

* Navigation adapts based on user login state

---

## 🎨 UI/UX

* RTL (Right-to-Left) support for Arabic
* Modern design with:

  * Gradients
  * Cards
  * Rich visual content
* Responsive layout for different screen sizes

---

## 🧠 Tech Stack

* Flutter (Dart)
* Firebase (planned for authentication & user data)
* Google Fonts (Cairo, Public Sans)

---

## 📂 Project Structure

```
lib/
 ┣ core/
 ┃ ┗ theme/
 ┣ presentation/
 ┃ ┣ screens/
 ┃ ┗ widgets/
 ┣ main.dart
```

---

## ⚙️ Getting Started

### 1. Install Flutter

Make sure Flutter is installed and configured:

```bash
flutter doctor
```

### 2. Run the App

```bash
flutter pub get
flutter run
```


