# Facts Checks

A Rails API application for scraping and aggregating fact-check articles from various fact-checking websites.

## Overview

This project collects fact-check data from multiple fact-checking organizations to make this information more accessible and analyzable. The scraper extracts structured data about claims, verdicts, sources, and metadata from fact-checking websites.

**Current Target**: [ColombiaCheck.com](https://colombiacheck.com/)

## Tech Stack

- **Ruby**: 3.3+ (see `.ruby-version`)
- **Rails**: 8.1.1 (API mode)
- **Database**: PostgreSQL
- **Job Queue**: Delayed Job (ActiveRecord backend)
- **Scraping**: Nokogiri (to be added)

## Prerequisites

- Ruby 3.3 or higher
- PostgreSQL 9.3 or higher
- Bundler

## Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd facts-checks
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Setup database**
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   ```

4. **Start the Rails server**
   ```bash
   bin/rails server
   ```

5. **Start the Delayed Job worker** (in a separate terminal)
   ```bash
   bin/delayed_job start
   ```

## Development

### Running in Development Mode

Start the Rails server:
```bash
bin/rails server
```

Start the Delayed Job worker:
```bash
bin/delayed_job start
```

Or use the development runner to start both:
```bash
bin/dev
```

### Database Commands

```bash
# Create databases
bin/rails db:create

# Run migrations
bin/rails db:migrate

# Reset database (drop, create, migrate)
bin/rails db:reset

# Rollback last migration
bin/rails db:rollback
```

### Background Jobs

This application uses Delayed Job for background job processing. Jobs are stored in the PostgreSQL database.

**Start worker:**
```bash
bin/delayed_job start
```

**Stop worker:**
```bash
bin/delayed_job stop
```

**Restart worker:**
```bash
bin/delayed_job restart
```

**Run in foreground (useful for debugging):**
```bash
bin/delayed_job run
```

### Code Quality

Run RuboCop:
```bash
bin/rubocop
```

Run Brakeman security scan:
```bash
bin/brakeman
```

Run bundle audit:
```bash
bin/bundler-audit
```

Run all checks:
```bash
bin/ci
```

## Project Structure

```
app/
├── controllers/    # API controllers
├── jobs/          # ActiveJob classes for background tasks
├── models/        # ActiveRecord models
└── services/      # Business logic and scraping services

config/
├── environments/  # Environment-specific configurations
└── ...

db/
├── migrate/       # Database migrations
└── ...

lib/
└── tasks/         # Rake tasks for scraping and maintenance
```

## Testing

This project uses RSpec for testing along with FactoryBot, Faker, Shoulda-Matchers, and Timecop.

Run the full test suite:
```bash
bundle exec rspec
```

Run specific test files:
```bash
bundle exec rspec spec/models/fact_check_spec.rb
```

Run tests matching a pattern:
```bash
bundle exec rspec spec/models
```

Run with documentation format:
```bash
bundle exec rspec --format documentation
```

## Deployment

This application is configured for deployment with Kamal (Docker-based deployment).

See `config/deploy.yml` for deployment configuration.

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and code quality checks (`bin/ci`)
4. Submit a pull request

## Current Models

### FactCheckUrl
Tracks URLs to be scraped and their processing status.

**Fields:**
- `url` - The fact-check article URL (unique, indexed)
- `digested` - Whether the URL has been processed (boolean, indexed)
- `source` - Source website (enum: `:colombia_check`)
- `digested_at` - When it was processed
- `attempts` - Number of scraping attempts
- `last_error` - Last error message if failed

**Scopes:**
- `.undigested` - URLs not yet processed
- `.digested` - Already processed URLs
- `.by_source(source)` - Filter by source
- `.with_errors` - URLs that failed processing

## Roadmap

- [x] Create FactCheckUrl model for tracking URLs
- [ ] Create database models (FactCheck, Source, Verdict)
- [ ] Implement ColombiaCheck scraper
- [ ] Create background jobs for scraping
- [ ] Add API endpoints for querying fact-checks
- [ ] Add support for additional fact-checking sources
- [ ] Implement scheduled/recurring scraping jobs
- [ ] Add search and filtering capabilities

## License

[Add your license here]

## Contact

[Add contact information here]
