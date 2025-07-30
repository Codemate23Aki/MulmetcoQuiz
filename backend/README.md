# Quiz Question Generator API

A Flask-based API that generates quiz questions using OpenAI's GPT model, specifically tailored for the Ugandan curriculum.

## Features

- Generates 20 multiple-choice questions based on subject and level
- Uganda-focused curriculum and context
- Integrates with Firebase Firestore
- Fallback questions if AI generation fails
- CORS enabled for Flutter web integration

## Setup

### Prerequisites

- Python 3.8+
- OpenAI API key
- Firebase service account credentials

### Installation

1. Navigate to the backend directory:
```bash
cd backend
```

2. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Set up environment variables:
```bash
cp .env.example .env
```
Edit `.env` and add your OpenAI API key:
```
OPENAI_API_KEY=your_actual_openai_api_key_here
```

5. Add Firebase credentials:
   - Download your Firebase service account JSON file
   - Rename it to `firebase-service-account.json`
   - Place it in the backend directory

### Running the API

```bash
python app.py
```

The API will be available at `http://localhost:5000`

## API Endpoints

### Health Check
```
GET /health
```
Returns API status.

### Generate Questions
```
POST /generate-questions
```

**Request Body:**
```json
{
  "quiz_id": "firestore_document_id",
  "subject": "Mathematics",
  "level": "Primary 6"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Questions generated successfully",
  "questions_count": 20
}
```

### User Management

#### Get All Users
```
GET /users
```

**Response:**
```json
{
  "success": true,
  "users": [
    {
      "id": "user_id",
      "displayName": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "status": "active",
      "createdAt": "2025-01-30T10:00:00Z",
      "lastLoginAt": "2025-01-30T12:00:00Z",
      "averageScore": 85.5,
      "quizzesTaken": 10
    }
  ],
  "count": 1
}
```

#### Create User
```
POST /users
```

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "role": "user",
  "status": "active"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User created successfully",
  "user_id": "generated_user_id"
}
```

#### Update User
```
PUT /users/<user_id>
```

**Request Body:**
```json
{
  "name": "Updated Name",
  "email": "updated@example.com",
  "role": "admin",
  "status": "active"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User updated successfully"
}
```

#### Delete User
```
DELETE /users/<user_id>
```

**Response:**
```json
{
  "success": true,
  "message": "User deleted successfully"
}
```

### Quiz Management

#### Get All Quizzes
```
GET /quizzes
```

**Response:**
```json
[
  {
    "id": "quiz_id",
    "title": "Quiz Title",
    "description": "Quiz description",
    "concept": "Subject/Concept",
    "difficulty": "easy|medium|hard",
    "totalQuestions": 20,
    "timeLimit": 30,
    "participants": 0,
    "averageScore": 0,
    "createdAt": "2024-01-01",
    "updatedAt": "2024-01-01",
    "isActive": true,
    "createdBy": "Creator Name"
  }
]
```



## Question Format

Each generated question follows this structure:
```json
{
  "id": 1,
  "question": "What is the capital city of Uganda?",
  "options": [
    "A. Kampala",
    "B. Entebbe",
    "C. Jinja",
    "D. Mbarara"
  ],
  "correct_answer": "A",
  "explanation": "Kampala is the capital and largest city of Uganda.",
  "difficulty": "Primary 6",
  "subject": "Social Studies"
}
```

## Integration with Flutter

The Flutter app automatically calls this API when a quiz is created:

1. User creates a quiz in the Flutter app
2. Quiz document is created in Firestore with status "generating_questions"
3. Flutter app calls `/generate-questions` endpoint
4. API generates questions using OpenAI
5. Questions are saved to the quiz document
6. Quiz status is updated to "ready"

## Error Handling

- If OpenAI API fails, fallback questions are generated
- All errors are logged and returned with appropriate HTTP status codes
- Quiz document is updated with error status if generation fails

## Deployment

For production deployment, consider:

1. Using Gunicorn as WSGI server:
```bash
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

2. Setting up proper environment variables
3. Using a production database
4. Implementing rate limiting
5. Adding authentication/authorization

## Environment Variables

- `OPENAI_API_KEY`: Your OpenAI API key
- `FLASK_ENV`: Set to 'production' for production
- `API_HOST`: Host to bind to (default: 0.0.0.0)
- `API_PORT`: Port to bind to (default: 5000)