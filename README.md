# password-manager

Small Rails application for managing passwords locally, without handing them to any external provider.

---

## Option A — Docker (recommended)

### Requirements

- Docker + Docker Compose
- No local Ruby or MongoDB installation needed

### Configuration

Copy `.env` and adjust the values (MongoDB credentials, secret key base, etc.) for your environment. The file already contains working defaults for development.

### Running the application

```bash
docker compose up -d mongo
docker compose up passwordmanager
```

The app will be available at http://localhost:3000.

### Running the test suite

**Unit and integration tests:**

```bash
docker compose run --rm passwordmanager rails test
```

**System tests (browser-based, require Selenium):**

```bash
docker compose up -d mongo selenium

docker compose run --rm \
  -e SELENIUM_REMOTE_URL=http://selenium:4444 \
  -e APP_HOST=passwordmanager-test \
  passwordmanager-test \
  rails test:system
```

Screenshots of failing tests are saved to `tmp/screenshots/`.

### Running generators and other Rails commands

Always run generators inside the container so the output lands in the mounted volume:

```bash
docker compose run --rm passwordmanager rails generate <generator> <args>
```

---

## Option B — Host (no Docker)

Run everything directly on the machine. Useful when Docker is unavailable or resource-constrained.

### System dependencies (Ubuntu/Debian)

```bash
sudo apt-get install -y libyaml-dev
```

### 1. Install Ruby 3.3.11 via `mise`

[`mise`](https://mise.jdx.dev) is a per-user version manager (no root, single binary) — the Ruby equivalent of `uv` for Python.

```bash
curl https://mise.run | sh
echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
source ~/.bashrc

# Use precompiled Ruby (no compiler needed)
mise settings ruby.compile=false

# Install Ruby 3.3.11 and pin it to this project
cd /path/to/password-manager
mise use ruby@3.3.11   # creates .mise.toml (gitignored)

ruby --version   # → ruby 3.3.11
```

### 2. Install MongoDB 7.0

```bash
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
  sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] \
  https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

sudo apt-get update && sudo apt-get install -y mongodb-org
sudo systemctl start mongod && sudo systemctl enable mongod
```

**Create the root user** (one-time, matches the password in `.env`):

```bash
mongosh --eval '
  use admin;
  db.createUser({
    user: "root",
    pwd: "example",
    roles: [{ role: "root", db: "admin" }]
  });
'

# Enable SCRAM authentication
sudo sed -i '/^#security:/a security:\n  authorization: enabled' /etc/mongod.conf
sudo systemctl restart mongod
```

### 3. Install gems

```bash
cd /path/to/password-manager
bundle install
```

### 4. Run the application

```bash
bin/dev-local            # binds to 0.0.0.0:3000 — reachable on the LAN
```

`bin/dev-local` (gitignored) sets the required environment variables and starts Puma bound to all interfaces. Find your LAN IP with `ip addr show` and open `http://<your-ip>:3000` from any device on the same network.

### 5. Run the test suite

```bash
bin/test-local                                    # all tests
bin/test-local test/models/api_token_test.rb      # specific file
```

`bin/test-local` (gitignored) sets `MONGODB_HOST=localhost` and the other required variables before running `bin/rails test`.

> **Note:** System tests (Capybara/Selenium) are not supported in the host setup without a local Selenium/ChromeDriver installation. Run `bin/test-local test/` to execute only unit and integration tests.
