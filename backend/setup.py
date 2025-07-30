#!/usr/bin/env python3
"""
Setup script for the Quiz Question Generator API
"""

import os
import sys
import subprocess

def check_python_version():
    """Check if Python version is 3.8 or higher"""
    if sys.version_info < (3, 8):
        print("Error: Python 3.8 or higher is required")
        sys.exit(1)
    print(f"✓ Python {sys.version_info.major}.{sys.version_info.minor} detected")

def create_virtual_environment():
    """Create virtual environment if it doesn't exist"""
    if not os.path.exists('venv'):
        print("Creating virtual environment...")
        subprocess.run([sys.executable, '-m', 'venv', 'venv'])
        print("✓ Virtual environment created")
    else:
        print("✓ Virtual environment already exists")

def install_dependencies():
    """Install required dependencies"""
    print("Installing dependencies...")
    
    # Determine the correct pip path based on OS
    if os.name == 'nt':  # Windows
        pip_path = os.path.join('venv', 'Scripts', 'pip')
    else:  # Unix/Linux/macOS
        pip_path = os.path.join('venv', 'bin', 'pip')
    
    try:
        subprocess.run([pip_path, 'install', '-r', 'requirements.txt'], check=True)
        print("✓ Dependencies installed successfully")
    except subprocess.CalledProcessError:
        print("Error: Failed to install dependencies")
        sys.exit(1)

def check_env_file():
    """Check if .env file exists and has required variables"""
    if not os.path.exists('.env'):
        print("⚠️  .env file not found. Please create one based on .env.example")
        print("   Make sure to add your OPENAI_API_KEY")
        return False
    
    with open('.env', 'r') as f:
        content = f.read()
        if 'OPENAI_API_KEY=your_openai_api_key_here' in content:
            print("⚠️  Please update your OPENAI_API_KEY in .env file")
            return False
        elif 'OPENAI_API_KEY=' not in content:
            print("⚠️  OPENAI_API_KEY not found in .env file")
            return False
    
    print("✓ .env file configured")
    return True

def check_firebase_credentials():
    """Check if Firebase service account file exists"""
    if not os.path.exists('firebase-service-account.json'):
        print("⚠️  firebase-service-account.json not found")
        print("   Please download your Firebase service account key and save it as 'firebase-service-account.json'")
        return False
    
    print("✓ Firebase credentials found")
    return True

def main():
    print("Quiz Question Generator API Setup")
    print("=" * 40)
    
    check_python_version()
    create_virtual_environment()
    install_dependencies()
    
    env_ok = check_env_file()
    firebase_ok = check_firebase_credentials()
    
    print("\nSetup Summary:")
    print("=" * 20)
    
    if env_ok and firebase_ok:
        print("✅ Setup completed successfully!")
        print("\nTo start the API server:")
        if os.name == 'nt':  # Windows
            print("   venv\\Scripts\\activate")
        else:  # Unix/Linux/macOS
            print("   source venv/bin/activate")
        print("   python app.py")
        print("\nAPI will be available at: http://localhost:5000")
    else:
        print("⚠️  Setup incomplete. Please address the warnings above.")
        sys.exit(1)

if __name__ == '__main__':
    main()