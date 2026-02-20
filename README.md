# Flutter Firebase Chat App

A real-time chat application built using Flutter and Firebase.  
This app allows users to register, log in, and send instant messages using Cloud Firestore streams.



## Overview

This project demonstrates how to integrate Flutter with Firebase services to build a secure, real-time messaging application.

The app supports:
- User authentication
- Real-time messaging
- Firestore database integration
- Session persistence



## Firebase Services Used

Firebase Authentication  
- Email and password sign-up and login  
- createUserWithEmailAndPassword  
- signInWithEmailAndPassword  

Cloud Firestore  
- Stores user profiles  
- Stores chat messages  
- Enables real-time updates  

Firebase Core  
- Initializes Firebase using firebase_options.dart  



## Authentication Workflow

Sign-Up (signup_screen.dart)
- User enters username, email, and password
- Firebase creates a new account
- A user document is added to the "users" collection in Firestore

Login (login_screen.dart)
- User enters email and password
- Firebase verifies credentials
- On success, user is navigated to the chat screen

Session Handling
- Firebase automatically manages login sessions
- User remains logged in unless manually signed out



## Firestore Database Structure

Users Collection (users)

Each document contains:
- uid
- email
- name
- createdAt
- (optional) profileImage

Messages Collection (messages)

Each document contains:
- senderId
- receiverId
- text
- timestamp

Messages are ordered using:
.orderBy("timestamp", descending: false)



## Real-Time Messaging

The chat screen uses:

StreamBuilder<QuerySnapshot>

This listens to changes in the messages collection and updates the UI instantly when:
- A new message is added
- A message is updated
- The message order changes

This creates real-time chat functionality similar to modern messaging apps.



## Challenges and Solutions

Firebase Initialization
- Configured Firebase correctly for Android and iOS using flutterfire configure.

Authentication Errors
- Handled weak passwords, existing emails, and invalid credentials using try/catch and FirebaseAuthException.

Firestore Structure
- Used a simple messages collection with senderId and receiverId for easier querying.

Message Sorting
- Applied orderBy("timestamp") to ensure correct chronological order.



## What I Learned

- Integrating Flutter with Firebase
- Building secure authentication workflows
- Designing NoSQL database structures in Firestore
- Using Streams for real-time updates
- Handling asynchronous programming in Flutter
- Managing user input and stateful widgets



## Tech Stack

Flutter  
Dart  
Firebase Authentication  
Cloud Firestore  
Firebase Core  



## How to Run the Project

1. Clone the repository
2. Run: flutter pub get
3. Add your Firebase configuration files
4. Run: flutter run



## Author

Omar Almahmoud
