# Mulmetco Quiz Application

A comprehensive quiz management system built with Flutter for mobile applications and React for web-based administration, powered by Firebase and Python backend services.

## 🎯 Project Overview

Mulmetco Quiz is a full-stack quiz application that enables administrators to create, manage, and monitor quiz sessions while providing students with an intuitive mobile interface for taking quizzes. The system features real-time scoring, user management, and comprehensive analytics.

## 🚀 Live Demo

- **Admin Dashboard**: [https://mulmetco-48a00.web.app](https://mulmetco-48a00.web.app)
- **Mobile APK**: Download `MulmetcoQuiz.apk` from the root directory to test the mobile application

### Demo Credentials
- **Email**: codetrials@gmail.com
- **Password**: root123

## 📱 Application Architecture

### Frontend Applications

#### 1. Flutter Mobile App (`/lib`)
- **Framework**: Flutter (Dart)
- **Purpose**: Student-facing quiz interface
- **Key Features**:
  - User authentication and registration
  - Interactive quiz interface with timer
  - Real-time score calculation
  - Results display with detailed feedback
  - Offline capability for downloaded quizzes

#### 2. React Admin Dashboard (`/dashboard`)
- **Framework**: React with TypeScript
- **Purpose**: Administrator interface for quiz management
- **Key Features**:
  - Quiz creation and editing with rich text support
  - User management and analytics
  - Real-time monitoring of quiz sessions
  - Score tracking and reporting
  - Responsive design for desktop and tablet use

### Backend Services

#### Python API Server (`/backend`)
- **Framework**: Flask
- **Purpose**: RESTful API for data processing and business logic
- **Key Features**:
  - Quiz data processing and validation
  - User authentication and authorization
  - Score calculation algorithms
  - Integration with external APIs (OpenAI for question generation)
  - Real-time data synchronization

#### Firebase Services
- **Firestore Database**: Real-time NoSQL database for storing quizzes, users, and scores
- **Firebase Authentication**: Secure user authentication across platforms
- **Firebase Hosting**: Hosting for the React admin dashboard
- **Cloud Functions**: Serverless functions for automated tasks

## 🔧 Technology Stack Integration

### How the Frameworks Work Together

1. **Data Flow Architecture**:
   ```
   Flutter App ←→ Firebase ←→ Python Backend ←→ External APIs
        ↓           ↓              ↓
   React Dashboard ←→ Firestore ←→ Authentication
   ```

2. **Real-time Synchronization**:
   - Firebase Firestore provides real-time data synchronization between all platforms
   - Changes made in the admin dashboard are instantly reflected in mobile apps
   - Live quiz sessions update scores and progress in real-time

3. **Authentication Flow**:
   - Firebase Authentication handles user sessions across Flutter and React
   - JWT tokens ensure secure API communication with the Python backend
   - Role-based access control separates admin and student functionalities

4. **Cross-Platform Consistency**:
   - Shared data models ensure consistency between Flutter (Dart) and React (TypeScript)
   - Python backend validates all data operations regardless of the client platform
   - Firebase rules provide additional security layer for data access

## 🛠️ Development Setup

### Prerequisites
- Flutter SDK (3.0+)
- Node.js (16+)
- Python (3.8+)
- Firebase CLI

### Backend Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

### Dashboard Setup
```bash
cd dashboard
npm install
npm start
```

### Flutter App Setup
```bash
flutter pub get
flutter run
```

## 📊 Key Features

### For Students (Flutter App)
- Secure login and profile management
- Browse available quizzes by category
- Take timed quizzes with multiple question types
- View detailed results and explanations
- Track progress and performance history

### For Administrators (React Dashboard)
- Create and manage quiz content
- Monitor live quiz sessions
- Generate comprehensive reports
- Manage user accounts and permissions
- Analytics dashboard with performance metrics

## 🔒 Security Features

- Firebase Authentication with email verification
- Secure API endpoints with JWT validation
- Role-based access control (Admin/Student)
- Data encryption in transit and at rest
- Input validation and sanitization
- Rate limiting on API endpoints

## 📈 Performance Optimizations

- **Flutter**: Efficient state management with Provider/Bloc patterns
- **React**: Component memoization and lazy loading
- **Backend**: Caching strategies and database query optimization
- **Firebase**: Efficient data structure design for minimal reads/writes

## 🚀 Deployment

- **Flutter App**: Built as APK/IPA for distribution
- **React Dashboard**: Deployed on Firebase Hosting
- **Python Backend**: Deployed on Vercel with serverless functions
- **Database**: Firebase Firestore with automatic scaling

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please read the contributing guidelines before submitting pull requests.

## 📞 Support

For support and questions, please contact the development team or create an issue in the repository.
