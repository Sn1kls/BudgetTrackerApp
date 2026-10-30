# BudgetTracker

A personal finance app: an iOS client in SwiftUI and a REST API in Django.
You keep several accounts (cash, card, savings), record income and expenses,
and see totals for a week, a month or any date range.

This is my university course project (TNTU, 2025). It is a learning project, not
production software. I later cleaned it up: fixed several bugs (each one is a
separate commit with a test), added CI and wrote this README.

## Architecture

```
iOS app (SwiftUI)  ──HTTP/JSON + JWT──▶  Django REST API  ──▶  PostgreSQL
```

```
ios/        SwiftUI app, MVVM
backend/    Django 5 + Django REST Framework, Docker Compose
```

**Backend.** One Django app, `core`, with two models: `Account`, which belongs to
a user and has a balance, and `Transaction`, which is income or expense on an
account. Signals update the account balance whenever a transaction is created,
edited, moved to another account or deleted. Each request runs in a database
transaction, so a balance never changes without its transaction. Every query is
scoped to the logged-in user. Auth is JWT (`djangorestframework-simplejwt`) with
refresh-token rotation and a blacklist on logout.

**iOS app.** Views → ViewModels → `NetworkService` (async/await `URLSession`).
JWT tokens are stored in the Keychain. Screens: login, register, accounts,
transactions (list, form, detail), analytics and profile.

## API

Interactive docs: <http://localhost:8000/swagger/> once the backend is running.

| Method | Path | What it does |
| --- | --- | --- |
| POST | `/api/register/` | Create a user (Django password validators apply) |
| POST | `/api/login/` | Get an access and refresh token pair |
| POST | `/api/token/refresh/` | Get a new access token |
| POST | `/api/logout/` | Blacklist a refresh token |
| GET, POST | `/api/accounts/` | List or create your accounts |
| GET, PUT, PATCH, DELETE | `/api/accounts/{id}/` | One account |
| GET, POST | `/api/transactions/` | List or create your transactions |
| GET, PUT, PATCH, DELETE | `/api/transactions/{id}/` | One transaction |
| GET | `/api/analytics/` | Balance per account and the overall balance |
| GET | `/api/analytics/summary/` | Income, expense and net for `?start=&end=` or `?period=this_month\|this_week`; optional `account_id`, `group_by=month` |

Amounts are strings with two decimals (`"25.00"`). Dates are ISO 8601 in UTC
(`2025-06-19T00:00:00Z`). The transaction `type` is `IN` (income) or `EX` (expense).

## Running the backend

You need Docker.

```bash
cd backend
cp .env.example .env
# Fill in DJANGO_SECRET_KEY and POSTGRES_PASSWORD.
# Avoid "$" in values: Docker Compose treats it as a variable.
docker compose up --build        # or: make up
```

This starts Postgres and the API on <http://localhost:8000> and applies the
migrations. If port 5432 is already taken on your machine, run it with
`POSTGRES_HOST_PORT=5433 docker compose up --build`.

## Tests

```bash
cd backend
make test    # pytest inside the running container
make lint    # ruff check + ruff format --check
```

The tests cover auth, per-user data isolation, balance updates on
create/edit/move/delete, input validation and the analytics summary. GitHub Actions
runs ruff and pytest against Postgres on every push and pull request that
touches `backend/`.

To run them without Docker for the app, point them at any Postgres:

```bash
poetry install
POSTGRES_HOST=localhost POSTGRES_PORT=5433 poetry run pytest
```

## Running the iOS app

Open `ios/BudgetTracker.xcodeproj` in Xcode (iOS 17.2+) and run it on a simulator.
It talks to `http://localhost:8000/api` by default.

To use a real iPhone, the API has to be reachable from the phone:

1. Put your `NGROK_AUTHTOKEN` in `backend/.env` and add `.ngrok-free.app` to
   `DJANGO_ALLOWED_HOSTS`.
2. Run `make tunnel` and copy the https URL from <http://localhost:4040>.
3. In Xcode, open the scheme, go to Run → Arguments → Environment Variables, and set
   `API_BASE_URL` to `https://<your-subdomain>.ngrok-free.app/api`.

## What I'd improve

- **Balance model.** The balance is stored on the account and can also be edited
  directly through the API. A cleaner design would derive it from transactions or
  only allow an opening balance.
- **Analytics.** `group_by=month` runs two queries per month; one grouped query
  (`TruncMonth`) would do. The currency is hard-coded to USD.
- **API.** No pagination on list endpoints. Email is not required to be unique.
  The successful logout and the `period=` shortcuts have no tests yet.
- **Deployment.** Docker runs Django's development server. A real deployment would
  need gunicorn, static files and production settings.
- **iOS.** No automatic token refresh after the access token expires. Money is held
  as `Double` instead of `Decimal`. The test targets are still Xcode templates.
  There is some leftover code from the earlier SQLite version: an unused
  `SQLite.swift` package, `ContentView.swift` and the custom fonts.
