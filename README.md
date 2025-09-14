# BreakBuddy - VIT Chennai Timetable & Friend Tracker

BreakBuddy is a Flutter application designed specifically for students of VIT Chennai. It allows you to manage your daily class schedule and instantly check if your friends are currently in a class or free, helping you find the perfect time to connect.



---

## ✨ Features

- **User Authentication**: Secure sign-up and login using Firebase Authentication (Email & Password).
- **Custom Student ID**: Users register with their unique VIT Chennai student ID (e.g., `22BCE1234`).
- **Daily Timetable Management**:
    - Add, view, and manage your class schedule for each day of the week.
    - Automatically calculates class end times based on type: **Theory (50 mins)** or **Lab (100 mins)**.
    - Store class details like subject name, room number, and teacher's name.
- **Friend Status Tracking**:
    - Add friends using their student ID.
    - See a real-time status indicator next to each friend's name on your home screen.
    - **Green Dot**: Your friend is currently free.
    - **Red Dot**: Your friend is currently in a class.
- **Clean & Simple UI**: An intuitive interface to quickly view your schedule and your friends' availability.

---

## ⚙️ How It Works

The core "Friend Status" feature works by:
1.  Fetching the current day and time.
2.  Accessing the timetable data of a friend from the Firestore database for that specific day.
3.  Iterating through their scheduled classes.
4.  Comparing the current time with the `startTime` and `endTime` of each class.
5.  If the current time falls within any class duration, the friend's status is marked as "In Class" (🔴). Otherwise, they are "Free" (🟢).

---

## 🛠️ Tech Stack & Firebase Structure

The app is built with a modern stack, relying on Google's Firebase for its backend.

- **Frontend**: Flutter
- **Backend**:
    - **Firebase Authentication**: For user management.
    - **Cloud Firestore**: A NoSQL database for storing user, timetable, and friend data.

### Firestore Data Model:

1.  **Users Collection**: Stores basic user information.
    ```
    /users/{auth_uid}/
      - id: "22BCE1234" (Student ID)
      - name: "Student Name"
      - email: "student@example.com"
    ```

2.  **Friends Sub-collection**: Stores a user's list of friends.
    ```
    /users/{auth_uid}/friends/{friend_doc_id}
      - fid: "22BCE5678" (Friend's Student ID)
      - Name: "Friend Name"
    ```

3.  **Timetable Collection**: Stores the timetable for each user, identified by their student ID.
    ```
    /timetable/{student_id}/{day_of_week}/{class_doc_id}
      - className: "Data Structures"
      - startTime: "09:00"
      - endTime: "09:50"
      - classType: "Theory"
      - ...
    ```

---

## 🚀 Getting Started

To run this project locally:

1.  **Set up Firebase**: Create a new Firebase project and enable **Authentication (Email/Password)** and **Cloud Firestore**.
2.  **Configure Project**:
    - **Android**: Add your `google-services.json` file to `android/app/`.
    - **iOS**: Add your `GoogleService-Info.plist` file to `ios/Runner/`.
3.  **Clone the repository**:
    ```sh
    git clone <your-repo-url>
    cd timetabel
    ```
4.  **Install dependencies**:
    ```sh
    flutter pub get
    ```
5.  **Run the app**:
    ```sh
    flutter run
    ```

