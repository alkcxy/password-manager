# password-manager

Self-hosted Rails password manager — credentials never leave the user's own server. Runs in production on a Raspberry Pi 4.

## Stack

Ruby 3.3.11, Rails 8, Mongoid (MongoDB ODM), Turbo + Stimulus, importmap-rails, Puma. Tests via Minitest, Capybara + Selenium for system tests.

## Running everything through Docker

The dev/test environment is containerized. **Never run `rails`/`bin/rails` directly on the host** — always go through `docker compose run --rm`:

```bash
# unit / integration / controller tests
docker compose run --rm passwordmanager bundle exec rails test

# system tests (Capybara + remote Selenium) — note the different service
docker compose run --rm passwordmanager-test bundle exec rails test:system

# generators and any other rails command
docker compose run --rm passwordmanager rails generate <generator> <args>
```

`passwordmanager-test` (not `passwordmanager`) is required for system tests: it's the only service wired with `SELENIUM_REMOTE_URL` and `APP_HOST`, which `application_system_test_case.rb` needs to reach the remote Selenium container. Running system tests against `passwordmanager` fails with `Errno::ECONNREFUSED` (no local ChromeDriver in that container).

Bring up dependencies first when needed: `docker compose up -d mongo` (always) and `docker compose up -d mongo selenium` (for system tests).

## MongoDB version ceiling — do not propose upgrades

Production hardware is a Raspberry Pi 4 (Cortex-A72, ARMv8.0-A). MongoDB ≥ 4.4.19 and all 5.0+ releases require ARMv8.2-A instructions (ATOMICS/LSE) and crash with **SIGILL** on this CPU. The maximum safe version is **MongoDB 4.4.18** — this is a hardware limit, not configurable. If a CVE or feature seems to require a newer version, flag it as blocked by hardware rather than proposing the upgrade.

## Repository layout

- `app/` — the Rails application (controllers, models, views, Stimulus controllers in `app/javascript`)
- `extension/` — companion browser extension (Manifest V3, vanilla JS); see `extension/AGENTS.md` for its conventions — different stack, different testing approach
- `docs/` — story plans and ADRs
- `test/` — Minitest suite (`models`, `controllers`, `integration`, `system`)
