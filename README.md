# Smart Expense Manager

A full-stack expense management application with AI-powered smart categorization.

## Tech Stack

- **Frontend**: Flutter (Web, Android, iOS) with Material Design 3
- **Backend**: ASP.NET Core 10 Web API
- **Database**: Amazon DynamoDB
- **Authentication**: AWS Cognito (JWT-based)
- **AI**: Claude API for intelligent expense categorization

## Features

- User authentication (sign up, sign in, sign out) via AWS Cognito
- Full CRUD operations for expenses
- AI-powered smart expense categorization using Claude
- Rule-based fallback categorization when AI is unavailable
- Dashboard with spending summary and pie chart visualization
- Filter expenses by category and date range
- 10 built-in expense categories with icons and colors
- Dark mode support
- Responsive Material Design 3 UI

## Project Structure

```
SmartExpenseManager/
├── frontend/                          # Flutter app
│   └── lib/
│       ├── main.dart                  # App entry point
│       ├── models/                    # Data models
│       ├── services/                  # API & auth services
│       ├── providers/                 # State management
│       ├── screens/                   # App screens
│       └── widgets/                   # Reusable widgets
├── backend/                           # ASP.NET Core API
│   └── SmartExpenseManager.Api/
│       ├── Controllers/               # API endpoints
│       ├── Models/                    # Request/response models
│       ├── Services/                  # Business logic
│       └── Program.cs                 # App configuration
└── README.md
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/auth/signup | Register new user |
| POST | /api/auth/confirm | Confirm email |
| POST | /api/auth/signin | Sign in |
| GET | /api/expense | Get all expenses |
| POST | /api/expense | Create expense |
| PUT | /api/expense/{id} | Update expense |
| DELETE | /api/expense/{id} | Delete expense |
| GET | /api/expense/summary | Get spending summary |
| GET | /api/category | Get categories |
| POST | /api/ai/categorize | AI categorize expense |

## Setup

### Prerequisites

- .NET 10 SDK
- Flutter 3.x
- AWS Account (for DynamoDB and Cognito)
- Anthropic API Key (for AI categorization)

### Backend

1. Update `backend/SmartExpenseManager.Api/appsettings.json` with your AWS and Anthropic credentials
2. Create a DynamoDB table named `SmartExpenseManager_Expenses` with:
   - Partition Key: `UserId` (String)
   - Sort Key: `ExpenseId` (String)
3. Run the API:
   ```bash
   cd backend/SmartExpenseManager.Api
   dotnet run
   ```

### Frontend

1. Update the API base URL in `frontend/lib/services/api_service.dart`
2. Run the app:
   ```bash
   cd frontend
   flutter run -d chrome    # for web
   flutter run              # for mobile
   ```

## Expense Categories

| Category | Icon | Color |
|----------|------|-------|
| Food & Dining | restaurant | #FF6B6B |
| Transportation | directions_car | #4ECDC4 |
| Shopping | shopping_bag | #45B7D1 |
| Bills & Utilities | receipt_long | #96CEB4 |
| Entertainment | movie | #FFEAA7 |
| Healthcare | local_hospital | #DDA0DD |
| Travel | flight | #98D8C8 |
| Education | school | #F7DC6F |
| Personal | person | #BB8FCE |
| Other | more_horiz | #AEB6BF |
