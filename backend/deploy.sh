#!/bin/bash

echo "🚀 Deploying Giyas.AI Backend v2.0.0..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from example..."
    cp env.example .env
    echo "📝 Please edit .env file with your actual configuration before deploying!"
    echo "   Required: JWT_SECRET, DB_*, GEMINI_API_KEY"
    echo "   Optional: FRONTEND_URL, NODE_ENV"
    exit 1
fi

# Check if PostgreSQL is running (basic check)
if ! pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
    echo "⚠️  PostgreSQL is not running or not accessible"
    echo "   Please ensure PostgreSQL is running on localhost:5432"
    echo "   Or update DB_HOST in your .env file"
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Check if dependencies installed successfully
if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo "✅ Dependencies installed successfully"

# Create uploads directory
echo "📁 Creating uploads directory..."
mkdir -p uploads/audio

# Database setup
echo "🗄️  Setting up database..."
echo "   Choose an option:"
echo "   1) Run migration (WARNING: This will drop existing tables)"
echo "   2) Skip migration (use existing database)"
echo "   3) Run seed script (populate with sample data)"
read -p "   Enter your choice (1-3): " db_choice

case $db_choice in
    1)
        echo "🔄 Running database migration..."
        npm run db:migrate
        ;;
    2)
        echo "⏭️  Skipping database migration"
        ;;
    3)
        echo "🌱 Running database seed..."
        npm run db:seed
        ;;
    *)
        echo "❌ Invalid choice. Skipping database setup."
        ;;
esac

# Start the server
echo "🌐 Starting server..."
echo "📊 Server will be available at: http://localhost:3000"
echo "📊 Health check: http://localhost:3000/api/health"
echo "📚 API docs: http://localhost:3000/api"
echo "🎤 Voice mood analysis: POST /api/mood/analyze-voice"
echo "💬 AI Chatbot: POST /api/chat/send"
echo "🔐 Authentication: POST /api/auth/login"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

npm start
