# password-manager

Small Rails application for managing passwords locally, without handing them to any external provider.

## Requirements

- Docker + Docker Compose
- No local Ruby installation needed — everything runs inside containers

## Configuration

Copy `.env.example` to `.env` and fill in the required values (MongoDB credentials, secret key base, etc.).

## Running the application

```bash
docker compose up -d mongo
docker compose up passwordmanager
```

The app will be available at http://localhost:3000.

## Running the test suite

### Unit and integration tests

```bash
docker compose run --rm passwordmanager rails test
```

No extra services needed — these tests use the MongoDB container only.

### System tests (browser-based)

System tests drive a real browser via Selenium. Start the required services first, then run:

```bash
# Start MongoDB and the Selenium browser container
docker compose up -d mongo selenium

# Run system tests
docker compose run --rm \
  -e SELENIUM_REMOTE_URL=http://selenium:4444 \
  -e APP_HOST=passwordmanager-test \
  passwordmanager-test \
  rails test:system
```

Screenshots of any failing tests are saved to `tmp/screenshots/`.

### All tests at once

```bash
docker compose up -d mongo selenium
docker compose run --rm passwordmanager rails test
docker compose run --rm \
  -e SELENIUM_REMOTE_URL=http://selenium:4444 \
  -e APP_HOST=passwordmanager-test \
  passwordmanager-test \
  rails test:system
```

## Running generators and other Rails commands

Always run generators inside the container so the output lands in the mounted volume:

```bash
docker compose run --rm passwordmanager rails generate <generator> <args>
```
