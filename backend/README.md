# Giyas AI Backend

A comprehensive Node.js/Express backend for the Giyas AI student study assistant application, featuring user authentication, mood analysis, AI chatbot, and study session management.

## Features

- 🔐 **User Authentication**: JWT-based authentication with secure password hashing
- 😊 **Mood Analysis**: Text and voice-based mood detection using Google Gemini AI
- 💬 **AI Chatbot**: Contextual study assistance with conversation history
- 📚 **Study Sessions**: Complete study session management with analytics
- 🗄️ **Database**: PostgreSQL with Sequelize ORM
- 🔒 **Security**: Helmet, rate limiting, CORS, input validation
- 📊 **Analytics**: Comprehensive analytics for mood and study patterns

## Tech Stack

- **Runtime**: Node.js 16+
- **Framework**: Express.js
- **Database**: PostgreSQL with Sequelize ORM
- **Authentication**: JWT with bcrypt
- **AI**: Google Gemini API
- **File Upload**: Multer
- **Security**: Helmet, express-rate-limit
- **Validation**: express-validator

## Prerequisites

- Node.js 16+ and npm
- PostgreSQL 12+
- Google Gemini API key

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` with your configuration:
   ```env
   # Server Configuration
   PORT=3000
   NODE_ENV=development
   
   # JWT Configuration
   JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
   
   # Database Configuration
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=giyas_ai_dev
   DB_USER=postgres
   DB_PASSWORD=your-password
   
   # AI Service Configuration
   GEMINI_API_KEY=your-gemini-api-key-here
   ```

4. **Set up PostgreSQL database**
   ```bash
   npm run setup-db
   ```

5. **Start the server**
   ```bash
   npm start
   ```

## Database Setup

The application uses PostgreSQL with the following tables:

- **users**: User accounts and profiles
- **mood_sessions**: Mood analysis records
- **chat_sessions**: Chat conversation sessions
- **chat_messages**: Individual chat messages
- **study_sessions**: Study session records

### Automatic Setup

The server automatically:
- Creates tables on startup
- Creates a demo user (student@test.com / password123) in development
- Handles database migrations

### Manual Setup

If you prefer manual setup:

```bash
# Create database
createdb giyas_ai_dev

# Run migrations (if using sequelize-cli)
npx sequelize-cli db:migrate

# Seed data (optional)
npm run seed
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/profile` - Get user profile
- `PUT /api/auth/profile` - Update user profile
- `PUT /api/auth/change-password` - Change password
- `POST /api/auth/refresh-token` - Refresh JWT token
- `POST /api/auth/logout` - Logout user

### Mood Analysis
- `POST /api/mood/analyze-text` - Analyze mood from text
- `POST /api/mood/analyze-voice` - Analyze mood from voice recording
- `GET /api/mood/history` - Get mood history
- `GET /api/mood/:id` - Get specific mood session
- `PUT /api/mood/:id` - Update mood session
- `DELETE /api/mood/:id` - Delete mood session
- `GET /api/mood/analytics/summary` - Get mood analytics
- `POST /api/mood/:id/apply-to-plan` - Apply mood to study plan

### Chat
- `GET /api/chat/sessions` - Get chat sessions
- `POST /api/chat/sessions` - Create chat session
- `GET /api/chat/sessions/:id` - Get chat session with messages
- `PUT /api/chat/sessions/:id` - Update chat session
- `DELETE /api/chat/sessions/:id` - Delete chat session
- `POST /api/chat/send-message` - Send message to chatbot
- `GET /api/chat/sessions/:id/messages` - Get messages for session
- `PUT /api/chat/sessions/:id/mark-read` - Mark messages as read
- `GET /api/chat/unread-count` - Get unread message count
- `GET /api/chat/analytics` - Get chat analytics

### Study Sessions
- `GET /api/study/sessions` - Get study sessions
- `POST /api/study/sessions` - Create study session
- `GET /api/study/sessions/:id` - Get specific study session
- `PUT /api/study/sessions/:id` - Update study session
- `DELETE /api/study/sessions/:id` - Delete study session
- `POST /api/study/sessions/:id/start` - Start study session
- `POST /api/study/sessions/:id/complete` - Complete study session
- `GET /api/study/analytics` - Get study analytics
- `GET /api/study/upcoming` - Get upcoming study sessions

## Authentication

All endpoints (except `/api/health`) require authentication using JWT tokens.

Include the token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

## File Upload

Voice files are stored in the `uploads/voice/` directory and served statically at `/uploads/voice/`.

Supported formats: WAV, MP3, M4A, AAC, OGG
Maximum file size: 10MB

## Development

### Running in Development Mode
```bash
npm run dev
```

### Running Tests
```bash
npm test
```

### Linting
```bash
npm run lint
```

### Code Formatting
```bash
npm run format
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | 3000 |
| `NODE_ENV` | Environment | development |
| `JWT_SECRET` | JWT signing secret | Required |
| `DB_HOST` | Database host | localhost |
| `DB_PORT` | Database port | 5432 |
| `DB_NAME` | Database name | giyas_ai_dev |
| `DB_USER` | Database user | postgres |
| `DB_PASSWORD` | Database password | Required |
| `GEMINI_API_KEY` | Google Gemini API key | Required |
| `MAX_FILE_SIZE` | Max upload file size | 10485760 |
| `FRONTEND_URL` | Frontend URL for CORS | http://localhost:50224 |

## Security Features

- **Password Hashing**: bcrypt with salt rounds
- **JWT Tokens**: Secure token-based authentication
- **Rate Limiting**: Prevents abuse
- **Input Validation**: Comprehensive request validation
- **CORS**: Configured for specific origins
- **Helmet**: Security headers
- **SQL Injection Protection**: Sequelize ORM

## Error Handling

The API returns consistent error responses:

```json
{
  "error": "Error type",
  "message": "Human-readable message",
  "details": [] // Validation errors
}
```

## Database Models

### User
- Basic profile information
- Preferences (language, timezone, etc.)
- Authentication data

### MoodSession
- Mood analysis results
- Voice file references
- AI recommendations
- Study tips

### ChatSession
- Conversation metadata
- Context information
- Message counts

### ChatMessage
- Individual messages
- Message types (user/assistant)
- Context and metadata

### StudySession
- Study session details
- Time tracking
- Productivity metrics
- Subject and topic information

## Deployment

### Production Checklist

1. **Environment Variables**
   - Set `NODE_ENV=production`
   - Use strong `JWT_SECRET`
   - Configure production database
   - Set `FRONTEND_URL`

2. **Database**
   - Use production PostgreSQL instance
   - Enable SSL connections
   - Set up proper backups

3. **Security**
   - Use HTTPS
   - Configure proper CORS origins
   - Set up rate limiting
   - Use environment-specific secrets

4. **Monitoring**
   - Set up logging
   - Monitor database connections
   - Track API usage

### Docker Deployment

```dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Check the API documentation at `/api` endpoint
- Review the health check at `/api/health`
