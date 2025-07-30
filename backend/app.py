from flask import Flask, request, jsonify
from flask_cors import CORS
import openai
import os
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore
import json
import random

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter web

# Initialize Firebase Admin SDK
try:
    # Try to initialize Firebase (will fail if already initialized)
    cred = credentials.Certificate('firebase-service-account.json')
    firebase_admin.initialize_app(cred)
except ValueError:
    # Firebase already initialized
    pass

db = firestore.client()

# Initialize OpenAI
openai.api_key = os.getenv('OPENAI_API_KEY')

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'message': 'Quiz API is running'})

@app.route('/users', methods=['GET'])
def get_users():
    try:
        print("\n=== Fetching Users from Firebase ===")
        
        # Get all users from Firestore
        users_ref = db.collection('users')
        users_docs = users_ref.stream()
        
        users = []
        for doc in users_docs:
            user_data = doc.to_dict()
            user_data['id'] = doc.id
            users.append(user_data)
        
        print(f"Found {len(users)} users")
        
        return jsonify({
            'success': True,
            'users': users,
            'count': len(users)
        })
        
    except Exception as e:
        error_msg = f"Error fetching users: {str(e)}"
        print(f"!!! ERROR: {error_msg}")
        return jsonify({'error': str(e)}), 500

@app.route('/users', methods=['POST'])
def create_user():
    try:
        print("\n=== Creating New User ===")
        data = request.get_json()
        print(f"Request data: {data}")
        
        # Validate required fields
        required_fields = ['name', 'email']
        for field in required_fields:
            if field not in data:
                error_msg = f'Missing required field: {field}'
                print(f"Validation error: {error_msg}")
                return jsonify({'error': error_msg}), 400
        
        # Create user document
        user_data = {
            'displayName': data['name'],
            'email': data['email'],
            'role': data.get('role', 'user'),
            'status': data.get('status', 'active'),
            'createdAt': firestore.SERVER_TIMESTAMP,
            'lastLoginAt': firestore.SERVER_TIMESTAMP,
            'averageScore': 0.0,
            'quizzesTaken': 0,
            'totalScore': 0,
            'achievements': [],
            'preferences': {
                'categories': [],
                'difficulty': 'medium',
                'notifications': True
            }
        }
        
        # Add user to Firestore
        users_ref = db.collection('users')
        doc_ref = users_ref.add(user_data)
        user_id = doc_ref[1].id
        
        print(f"User created with ID: {user_id}")
        
        return jsonify({
            'success': True,
            'message': 'User created successfully',
            'user_id': user_id
        })
        
    except Exception as e:
        error_msg = f"Error creating user: {str(e)}"
        print(f"!!! ERROR: {error_msg}")
        return jsonify({'error': str(e)}), 500

@app.route('/users/<user_id>', methods=['PUT'])
def update_user(user_id):
    try:
        print(f"\n=== Updating User {user_id} ===")
        data = request.get_json()
        print(f"Request data: {data}")
        
        # Update user document
        user_ref = db.collection('users').document(user_id)
        
        # Only update provided fields
        update_data = {}
        if 'name' in data:
            update_data['displayName'] = data['name']
        if 'email' in data:
            update_data['email'] = data['email']
        if 'role' in data:
            update_data['role'] = data['role']
        if 'status' in data:
            update_data['status'] = data['status']
        
        user_ref.update(update_data)
        print(f"User {user_id} updated successfully")
        
        return jsonify({
            'success': True,
            'message': 'User updated successfully'
        })
        
    except Exception as e:
        error_msg = f"Error updating user: {str(e)}"
        print(f"!!! ERROR: {error_msg}")
        return jsonify({'error': str(e)}), 500

@app.route('/users/<user_id>', methods=['DELETE'])
def delete_user(user_id):
    try:
        print(f"\n=== Deleting User {user_id} ===")
        
        # Delete user document
        user_ref = db.collection('users').document(user_id)
        user_ref.delete()
        
        print(f"User {user_id} deleted successfully")
        
        return jsonify({
            'success': True,
            'message': 'User deleted successfully'
        })
        
    except Exception as e:
        error_msg = f"Error deleting user: {str(e)}"
        print(f"!!! ERROR: {error_msg}")
        return jsonify({'error': str(e)}), 500

@app.route('/quizzes', methods=['GET'])
def get_quizzes():
    try:
        print("\n=== Fetching Quizzes from Firebase ===")
        
        # Get all quizzes from Firestore
        quizzes_ref = db.collection('quizzes')
        quizzes_docs = quizzes_ref.stream()
        
        quizzes = []
        for doc in quizzes_docs:
            quiz_data = doc.to_dict()
            quiz_data['id'] = doc.id
            quizzes.append(quiz_data)
        
        print(f"Found {len(quizzes)} quizzes")
        return jsonify(quizzes)
        
    except Exception as e:
        print(f"Error fetching quizzes: {str(e)}")
        return jsonify({'error': 'Failed to fetch quizzes'}), 500

@app.route('/quizzes/<quiz_id>', methods=['DELETE'])
def delete_quiz(quiz_id):
    try:
        print(f"\n=== Deleting Quiz {quiz_id} ===")
        
        # Delete quiz document
        quiz_ref = db.collection('quizzes').document(quiz_id)
        quiz_ref.delete()
        
        print(f"Quiz {quiz_id} deleted successfully")
        
        return jsonify({
            'success': True,
            'message': 'Quiz deleted successfully'
        })
        
    except Exception as e:
        error_msg = f"Error deleting quiz: {str(e)}"
        print(f"!!! ERROR: {error_msg}")
        return jsonify({'error': str(e)}), 500

@app.route('/scores', methods=['GET'])
def get_scores():
    try:
        print("\n=== Fetching Scores from Firebase ===")
        
        # Get all scores from Firestore (using quiz_scores collection)
        scores_ref = db.collection('quiz_scores')
        scores_docs = scores_ref.stream()
        
        scores = []
        for doc in scores_docs:
            score_data = doc.to_dict()
            score_data['id'] = doc.id
            scores.append(score_data)
        
        print(f"Found {len(scores)} scores")
        return jsonify(scores)
        
    except Exception as e:
        print(f"Error fetching scores: {str(e)}")
        return jsonify({'error': 'Failed to fetch scores'}), 500



@app.route('/generate-questions', methods=['POST'])
def generate_questions():
    try:
        print("\n=== Question Generation Request ===")
        data = request.get_json()
        print(f"Request data: {data}")
        
        # Validate required fields
        required_fields = ['quiz_id', 'subject', 'level']
        for field in required_fields:
            if field not in data:
                error_msg = f'Missing required field: {field}'
                print(f"Validation error: {error_msg}")
                return jsonify({'error': error_msg}), 400
        
        quiz_id = data['quiz_id']
        subject = data['subject']
        level = data['level']
        print(f"Processing quiz {quiz_id}: {subject} - {level}")
        
        # Generate questions using AI
        questions = generate_ai_questions(subject, level)
        print(f"Generated {len(questions)} questions successfully")
        
        # Update quiz document in Firestore
        print(f"Updating Firestore document: {quiz_id}")
        quiz_ref = db.collection('quizzes').document(quiz_id)
        quiz_ref.update({
            'questions': questions,
            'status': 'ready',
            'questionsGenerated': True
        })
        print("Firestore update completed")
        
        response_data = {
            'success': True,
            'message': 'Questions generated successfully',
            'questions_count': len(questions)
        }
        print(f"Sending response: {response_data}")
        return jsonify(response_data)
        
    except Exception as e:
        error_msg = f"Error generating questions: {str(e)}"
        print(f"\n!!! ERROR: {error_msg}")
        print(f"Exception type: {type(e).__name__}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return jsonify({'error': str(e)}), 500

def generate_ai_questions(subject, level):
    """
    Generate 20 quiz questions using OpenAI based on subject and level
    Focused on Uganda-based curriculum
    """
    
    prompt = f"""
    Generate exactly 20 multiple choice questions for a {level} level {subject} quiz.
    The questions should be based on the Ugandan curriculum and context.
    
    Requirements:
    - Questions should be appropriate for {level} level students in Uganda
    - Include Ugandan examples, places, and context where relevant
    - Each question should have 4 options (A, B, C, D)
    - Clearly indicate the correct answer
    - Questions should be educational and challenging but fair
    - Cover different topics within {subject}
    
    Format each question as a JSON object with this structure:
    {{
        "question": "Question text here?",
        "options": [
            "A. Option 1",
            "B. Option 2", 
            "C. Option 3",
            "D. Option 4"
        ],
        "correct_answer": "A",
        "explanation": "Brief explanation of why this is correct"
    }}
    
    Return only a valid JSON array of 20 questions, no additional text.
    """
    
    try:
        print(f"Generating questions for {subject} - {level}...")
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are an expert educator creating quiz questions for Ugandan students. Always respond with valid JSON only."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=4000,
            temperature=0.7
        )
        
        questions_text = response.choices[0].message.content.strip()
        print(f"Raw OpenAI response length: {len(questions_text)} characters")
        print(f"Raw OpenAI response preview: {questions_text[:200]}...")
        
        # Validate response is not empty
        if not questions_text:
            raise ValueError("OpenAI returned empty response")
        
        # Clean up response - remove markdown code blocks if present
        if questions_text.startswith('```json'):
            questions_text = questions_text[7:]
        if questions_text.endswith('```'):
            questions_text = questions_text[:-3]
        questions_text = questions_text.strip()
        
        # Parse the JSON response
        try:
            questions = json.loads(questions_text)
            print(f"Successfully parsed JSON with {len(questions)} questions")
        except json.JSONDecodeError as json_err:
            print(f"JSON parsing failed: {json_err}")
            print(f"Problematic content: {questions_text[:500]}")
            raise
        
        # Validate that we have at least 20 questions, take first 20 if more
        if len(questions) < 20:
            print(f"Warning: Only got {len(questions)} questions, expected at least 20")
            raise ValueError(f"Expected at least 20 questions, got {len(questions)}")
        
        # Take only the first 20 questions if we got more
        if len(questions) > 20:
            print(f"Got {len(questions)} questions, taking first 20")
        questions = questions[:20]
        
        # Add question IDs and shuffle options
        for i, question in enumerate(questions):
            question['id'] = i + 1
            question['difficulty'] = level
            question['subject'] = subject
        
        return questions
        
    except json.JSONDecodeError as e:
        print(f"JSON parsing error: {e}")
        print("Falling back to sample questions...")
        return generate_fallback_questions(subject, level)
    except Exception as e:
        print(f"AI generation error: {e}")
        print("Falling back to sample questions...")
        return generate_fallback_questions(subject, level)

def generate_fallback_questions(subject, level):
    """
    Fallback questions in case AI generation fails
    """
    print(f"Generating fallback questions for {subject} - {level}")
    
    # Subject-specific question templates
    question_templates = {
        "Mathematics": [
            ("What is 2 + 2?", ["A. 3", "B. 4", "C. 5", "D. 6"], "B", "Basic addition: 2 + 2 = 4"),
            ("What is 10 - 3?", ["A. 6", "B. 7", "C. 8", "D. 9"], "B", "Basic subtraction: 10 - 3 = 7"),
            ("What is 3 × 4?", ["A. 10", "B. 11", "C. 12", "D. 13"], "C", "Basic multiplication: 3 × 4 = 12"),
        ],
        "English": [
            ("What is the plural of 'child'?", ["A. childs", "B. children", "C. childes", "D. child"], "B", "The plural of child is children"),
            ("Which is a noun?", ["A. run", "B. quickly", "C. book", "D. beautiful"], "C", "A book is a thing, making it a noun"),
            ("What is a verb?", ["A. action word", "B. describing word", "C. naming word", "D. joining word"], "A", "A verb is an action word"),
        ],
        "Science": [
            ("What do plants need to grow?", ["A. only water", "B. only sunlight", "C. water and sunlight", "D. only soil"], "C", "Plants need both water and sunlight to grow"),
            ("How many legs does a spider have?", ["A. 6", "B. 8", "C. 10", "D. 12"], "B", "Spiders have 8 legs"),
            ("What is the largest planet?", ["A. Earth", "B. Mars", "C. Jupiter", "D. Venus"], "C", "Jupiter is the largest planet in our solar system"),
        ]
    }
    
    # Get templates for the subject, or use generic ones
    templates = question_templates.get(subject, question_templates["Mathematics"])
    
    fallback_questions = []
    
    for i in range(20):
        # Cycle through available templates
        template_index = i % len(templates)
        question_text, options, correct_answer, explanation = templates[template_index]
        
        # Add question number to make them unique
        if i >= len(templates):
            question_text = f"Question {i + 1}: {question_text}"
        
        question = {
            "id": i + 1,
            "question": question_text,
            "options": options,
            "correct_answer": correct_answer,
            "explanation": explanation,
            "difficulty": level,
            "subject": subject
        }
        fallback_questions.append(question)
    
    print(f"Generated {len(fallback_questions)} fallback questions")
    return fallback_questions

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)