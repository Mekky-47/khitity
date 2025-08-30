const { GoogleGenerativeAI } = require('@google/generative-ai');

class AIService {
  constructor() {
    this.genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    this.model = this.genAI.getGenerativeModel({ model: "gemini-pro" });
  }

  // Analyze voice for mood detection
  async analyzeVoiceMood(audioTranscription, userId) {
    try {
      const prompt = `As an AI study advisor, analyze the student's voice transcription to detect their emotional state and recommend appropriate study hours.

Student's voice transcription: "${audioTranscription}"

Please analyze the emotional content, tone, and context to determine:
1. Primary mood (happy, excited, tired, stressed, bored, anxious, focused, relaxed, or other)
2. Confidence level (0.0 to 1.0) in your mood assessment
3. Recommended study hours (0.5 to 8.0 hours) based on the detected mood
4. Brief explanation of why this duration is recommended
5. 3-5 personalized study tips based on the mood

Return ONLY a JSON response in this exact format:
{
  "moodType": "<detected_mood>",
  "confidence": <confidence_score>,
  "recommendedStudyHours": <study_hours>,
  "explanation": "<explanation>",
  "studyTips": ["<tip1>", "<tip2>", "<tip3>"],
  "moodContext": {
    "emotionalTone": "<tone_description>",
    "energyLevel": "<energy_level>",
    "stressIndicators": ["<indicator1>", "<indicator2>"]
  }
}`;

      const result = await this.model.generateContent(prompt);
      const response = await result.response;
      const text = response.text();
      
      try {
        return JSON.parse(text);
      } catch (parseError) {
        console.warn('Failed to parse AI response, using fallback:', parseError);
        return this._getFallbackVoiceAnalysis(audioTranscription);
      }
    } catch (error) {
      console.error('Voice mood analysis error:', error);
      return this._getFallbackVoiceAnalysis(audioTranscription);
    }
  }

  // Analyze mood from text
  async analyzeTextMood(moodDescription) {
    try {
      const prompt = `As an AI study advisor, analyze the student's mood description to recommend appropriate study hours.

Student's mood description: "${moodDescription}"

Please analyze the emotional content and context to determine:
1. Primary mood (happy, excited, tired, stressed, bored, anxious, focused, relaxed, or other)
2. Confidence level (0.0 to 1.0) in your mood assessment
3. Recommended study hours (0.5 to 8.0 hours) based on the detected mood
4. Brief explanation of why this duration is recommended
5. 3-5 personalized study tips based on the mood

Return ONLY a JSON response in this exact format:
{
  "mood": "<detected_mood>",
  "confidence": <confidence_score>,
  "recommendedHours": <study_hours>,
  "explanation": "<explanation>",
  "studyTips": ["<tip1>", "<tip2>", "<tip3>"],
  "moodContext": {
    "emotionalTone": "<tone_description>",
    "energyLevel": "<energy_level>",
    "stressIndicators": ["<indicator1>", "<indicator2>"]
  }
}`;

      const result = await this.model.generateContent(prompt);
      const response = await result.response;
      const text = response.text();
      
      try {
        return JSON.parse(text);
      } catch (parseError) {
        console.warn('Failed to parse AI response, using fallback:', parseError);
        return this._getFallbackTextAnalysis(moodDescription);
      }
    } catch (error) {
      console.error('Text mood analysis error:', error);
      return this._getFallbackTextAnalysis(moodDescription);
    }
  }

  // Chatbot response with context awareness
  async generateChatResponse(userMessage, conversationHistory, userMood, studyContext, userId) {
    try {
      const contextPrompt = this._buildContextPrompt(userMessage, conversationHistory, userMood, studyContext);
      
      const result = await this.model.generateContent(contextPrompt);
      const response = await result.response;
      const text = response.text();
      
      try {
        const parsed = JSON.parse(text);
        return {
          content: parsed.response,
          suggestions: parsed.suggestions || [],
          studyRecommendations: parsed.studyRecommendations || [],
          moodInsights: parsed.moodInsights || {}
        };
      } catch (parseError) {
        console.warn('Failed to parse chat response, using fallback:', parseError);
        return this._getFallbackChatResponse(userMessage, userMood);
      }
    } catch (error) {
      console.error('Chat response generation error:', error);
      return this._getFallbackChatResponse(userMessage, userMood);
    }
  }

  // Build context-aware prompt for chatbot
  _buildContextPrompt(userMessage, conversationHistory, userMood, studyContext) {
    const recentMessages = conversationHistory.slice(-5).map(msg => 
      `${msg.messageType}: ${msg.content}`
    ).join('\n');

    return `You are Giyas.AI, an intelligent study assistant. Consider the following context to provide personalized, helpful responses.

STUDENT'S CURRENT MOOD: ${userMood?.moodType || 'unknown'} (${userMood?.confidence || 0} confidence)
${userMood?.explanation ? `MOOD CONTEXT: ${userMood.explanation}` : ''}

STUDY CONTEXT: ${JSON.stringify(studyContext)}

RECENT CONVERSATION:
${recentMessages}

STUDENT'S MESSAGE: ${userMessage}

INSTRUCTIONS:
- Provide helpful, encouraging study advice
- Consider the student's current mood when giving recommendations
- If they seem stressed/tired, suggest shorter sessions and breaks
- If they seem excited/focused, encourage longer, challenging sessions
- Be conversational but professional
- Include specific, actionable study tips
- Keep responses concise but comprehensive

Return ONLY a JSON response in this format:
{
  "response": "<your helpful response>",
  "suggestions": ["<suggestion1>", "<suggestion2>"],
  "studyRecommendations": ["<recommendation1>", "<recommendation2>"],
  "moodInsights": {
    "moodImpact": "<how mood affects study>",
    "encouragement": "<motivational message>"
  }
}`;
  }

  // Fallback voice analysis
  _getFallbackVoiceAnalysis(transcription) {
    const moodKeywords = {
      happy: ['happy', 'excited', 'great', 'wonderful', 'amazing', 'fantastic'],
      tired: ['tired', 'exhausted', 'sleepy', 'drained', 'weary'],
      stressed: ['stressed', 'anxious', 'worried', 'nervous', 'overwhelmed'],
      bored: ['bored', 'uninterested', 'dull', 'monotonous'],
      focused: ['focused', 'concentrated', 'determined', 'motivated']
    };

    let detectedMood = 'neutral';
    let confidence = 0.5;
    let recommendedHours = 3.0;

    for (const [mood, keywords] of Object.entries(moodKeywords)) {
      const matches = keywords.filter(keyword => 
        transcription.toLowerCase().includes(keyword)
      ).length;
      
      if (matches > 0) {
        detectedMood = mood;
        confidence = Math.min(0.8, 0.5 + (matches * 0.1));
        break;
      }
    }

    // Adjust study hours based on mood
    switch (detectedMood) {
      case 'happy':
      case 'focused':
        recommendedHours = 4.0;
        break;
      case 'tired':
      case 'stressed':
        recommendedHours = 2.0;
        break;
      case 'bored':
        recommendedHours = 3.0;
        break;
      default:
        recommendedHours = 3.0;
    }

    return {
      moodType: detectedMood,
      confidence: confidence,
      recommendedStudyHours: recommendedHours,
      explanation: `Based on voice analysis, you seem ${detectedMood}.`,
      studyTips: [
        'Take regular breaks to maintain focus',
        'Set achievable study goals',
        'Create a comfortable study environment'
      ],
      moodContext: {
        emotionalTone: detectedMood,
        energyLevel: detectedMood === 'tired' ? 'low' : 'moderate',
        stressIndicators: detectedMood === 'stressed' ? ['voice tension'] : []
      }
    };
  }

  // Fallback text analysis
  _getFallbackTextAnalysis(moodDescription) {
    const moodKeywords = {
      happy: ['happy', 'excited', 'great', 'wonderful', 'amazing', 'fantastic', 'joyful', 'cheerful'],
      tired: ['tired', 'exhausted', 'sleepy', 'drained', 'weary', 'fatigued'],
      stressed: ['stressed', 'anxious', 'worried', 'nervous', 'overwhelmed', 'tense', 'pressured'],
      bored: ['bored', 'uninterested', 'dull', 'monotonous', 'unmotivated'],
      focused: ['focused', 'concentrated', 'determined', 'motivated', 'energized']
    };

    let detectedMood = 'neutral';
    let confidence = 0.5;
    let recommendedHours = 3.0;

    for (const [mood, keywords] of Object.entries(moodKeywords)) {
      const matches = keywords.filter(keyword => 
        moodDescription.toLowerCase().includes(keyword)
      ).length;
      
      if (matches > 0) {
        detectedMood = mood;
        confidence = Math.min(0.8, 0.5 + (matches * 0.1));
        break;
      }
    }

    // Adjust study hours based on mood
    switch (detectedMood) {
      case 'happy':
      case 'focused':
        recommendedHours = 4.0;
        break;
      case 'tired':
      case 'stressed':
        recommendedHours = 2.0;
        break;
      case 'bored':
        recommendedHours = 3.0;
        break;
      default:
        recommendedHours = 3.0;
    }

    return {
      mood: detectedMood,
      confidence: confidence,
      recommendedHours: recommendedHours,
      explanation: `Based on your description, you seem ${detectedMood}.`,
      studyTips: [
        'Take regular breaks to maintain focus',
        'Set achievable study goals',
        'Create a comfortable study environment'
      ],
      moodContext: {
        emotionalTone: detectedMood,
        energyLevel: detectedMood === 'tired' ? 'low' : 'moderate',
        stressIndicators: detectedMood === 'stressed' ? ['text indicators'] : []
      }
    };
  }

  // Fallback chat response
  _getFallbackChatResponse(userMessage, userMood) {
    const mood = userMood?.moodType || 'neutral';
    
    let response = "I'm here to help you with your studies! ";
    let suggestions = [];
    
    if (mood === 'tired' || mood === 'stressed') {
      response += "I notice you might be feeling a bit overwhelmed. Let's take this step by step.";
      suggestions = [
        "Take a 5-minute break",
        "Start with easier subjects",
        "Set smaller, achievable goals"
      ];
    } else if (mood === 'happy' || mood === 'focused') {
      response += "Great energy! You're in a perfect state for productive studying.";
      suggestions = [
        "Tackle challenging topics first",
        "Plan longer study sessions",
        "Set ambitious but realistic goals"
      ];
    } else {
      response += "How can I help you optimize your study plan today?";
      suggestions = [
        "Review your current schedule",
        "Set study priorities",
        "Plan your next session"
      ];
    }

    return {
      content: response,
      suggestions: suggestions,
      studyRecommendations: [],
      moodInsights: {
        moodImpact: `Your ${mood} mood can influence study effectiveness.`,
        encouragement: "Remember, every study session brings you closer to your goals!"
      }
    };
  }
}

module.exports = new AIService();
