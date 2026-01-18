# Facts Checks

A Rails API application for scraping and aggregating fact-check articles from various fact-checking websites, with AI-powered entity extraction and date parsing.

## Overview

This project collects fact-check data from multiple fact-checking organizations to make this information more accessible and analyzable. The scraper extracts structured data about claims, verdicts, sources, and metadata from fact-checking websites, then enriches it using AI to extract topics, actors, and disseminators.

**Current Target**: [ColombiaCheck.com](https://colombiacheck.com/)

## Tech Stack

- **Ruby**: 3.3+ (see `.ruby-version`)
- **Rails**: 8.1.1 (API mode)
- **Database**: PostgreSQL
- **Job Queue**: Delayed Job (ActiveRecord backend)
- **Scraping**: HTTParty, Nokogiri
- **AI Integration**: OpenAI API (ruby-openai gem)
- **Testing**: RSpec, FactoryBot, Faker, Shoulda-Matchers, Timecop, WebMock

## Features

✅ **Automated Scraping** - Discovers and scrapes fact-check articles from ColombiaCheck
✅ **AI-Powered Date Parsing** - Converts Spanish date strings to UTC using OpenAI
✅ **AI Entity Extraction** - Extracts topics, actors, and disseminators from articles
✅ **Self-Managing Jobs** - Background jobs automatically re-enqueue themselves
✅ **Rich Data Model** - Captures verdicts, actors, topics, disseminators, platforms
✅ **Comprehensive Tests** - 299 passing tests with >90% coverage

## Prerequisites

- Ruby 3.3 or higher
- PostgreSQL 9.3 or higher
- Bundler
- OpenAI API key (for AI features)

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

3. **Configure environment variables**

   Create a `.env` file in the project root:
   ```bash
   OPENAI_API_KEY=your-openai-api-key-here
   ```

4. **Setup database**
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   ```

5. **Start the Delayed Job worker** (required for background jobs)
   ```bash
   bin/delayed_job start
   ```

6. **Start the Rails server** (optional - for API endpoints when implemented)
   ```bash
   bin/rails server
   ```

## Usage

### Complete Workflow

The scraping and enrichment process has 4 main steps:

#### 1. Discover Article URLs
```bash
rails scraping:enqueue_facts_to_check
```
- Scrapes article listing pages from ColombiaCheck
- Creates `FactCheckUrl` records for each article
- Job automatically processes all pages and re-enqueues weekly

#### 2. Extract Article Content
```bash
rails scraping:mine_fact_urls
```
- Scrapes full content from each article URL
- Creates `FactCheck` records with title, reasoning, verdict
- Creates `PublicationDate` records (raw date strings)
- Job processes all undigested URLs automatically

#### 3. Parse Dates with AI
```bash
rails publication_dates:process_dates
```
- Uses OpenAI to convert Spanish date strings to UTC
- Handles timezone conversion (Colombia/Bogota → UTC)
- Job processes all dates with nil values automatically

#### 4. Extract Entities with AI
```bash
rails ai:extract_entities
```
- Extracts topics, actors, and disseminators using OpenAI
- Creates associations between FactChecks and entities
- Populates Topic, Actor, Disseminator, Platform models
- Job processes all un-enriched FactChecks automatically
- **Cost**: ~$0.0009 per article (~$0.90 per 1000 articles)

### Monitoring Progress

Check processing status in Rails console:

```ruby
# URLs discovered and pending processing
FactCheckUrl.undigested.count

# FactChecks created
FactCheck.count

# Dates pending AI parsing
PublicationDate.where(value: nil).count

# FactChecks pending AI entity extraction
FactCheck.where(ai_enriched: false).count

# Extracted entities
Topic.count
Actor.count
Disseminator.count

# Check background job queue
Delayed::Job.count
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
├── classes/
│   ├── openai/              # OpenAI API wrapper
│   │   ├── client.rb        # OpenAI::Client
│   │   └── errors/          # Custom error classes
│   └── scraping/            # Reusable scraping utility classes
│       ├── document.rb      # Scraping::Document - HTML wrapper
│       └── element_set.rb   # Scraping::ElementSet - Element collection
├── controllers/             # API controllers
├── jobs/                    # ActiveJob classes for background tasks
│   ├── scrape_colombia_check_job.rb
│   ├── mine_fact_check_url_job.rb
│   ├── process_publication_dates_job.rb
│   └── extract_entities_job.rb
├── models/                  # ActiveRecord models
│   ├── fact_check_url.rb
│   ├── fact_check.rb
│   ├── veredict.rb
│   ├── publication_date.rb
│   ├── topic.rb
│   ├── actor.rb
│   ├── actor_type.rb
│   ├── actor_role.rb
│   ├── disseminator.rb
│   ├── platform.rb
│   └── ... (junction tables)
└── services/
    ├── ai/                  # AI-powered services
    │   └── extract_entities_service.rb
    ├── fact_check/          # FactCheck services
    │   ├── creation_service.rb
    │   └── associate_entities_service.rb
    ├── publication_dates/   # Date parsing services
    │   └── parse_date_service.rb
    └── scraping/            # Source-specific scraping services
        └── colombia_check_scraper_service.rb

lib/
└── tasks/                   # Rake tasks
    ├── ai/
    │   └── extract_entities.rake
    ├── publication_dates/
    │   └── process_dates.rake
    └── scraping/
        ├── enqueue_colombia_check_fact_urls_list.rake
        └── mine_fact_check_urls.rake

spec/
├── factories/               # FactoryBot factories
├── models/                  # Model specs
├── services/                # Service specs
├── jobs/                    # Job specs
└── classes/                 # Class specs
```

## Data Models

### Core Models

**FactCheckUrl** - Tracks URLs to be scraped
- Fields: `url`, `digested`, `source`, `digested_at`, `attempts`, `last_error`
- Scopes: `undigested`, `digested`, `by_source`, `with_errors`

**FactCheck** - Main fact-check article data
- Fields: `source_url`, `title`, `reasoning`, `digested`, `ai_enriched`, `ai_enriched_at`
- Associations: `veredict`, `publication_date`, `topics`, `actors`, `disseminators`

**Veredict** - Standardized verdict types (FALSO, VERDADERO, CUESTIONABLE, etc.)

**PublicationDate** - Publication date strings and parsed UTC values
- Fields: `date` (raw string), `value` (parsed UTC date)

### Entity Models

**Topic** - Subject matter categories (Health, Politics, COVID-19, etc.)

**Actor** - People, organizations, or entities mentioned in fact-checks
- Associations: `actor_type`, `actor_role` (via FactCheckActor)

**ActorType** - Types: person, government_entity, organization

**ActorRole** - Roles: target, mentioned, beneficiary, source

**Disseminator** - Accounts/profiles that spread claims
- Associations: `platform`, `disseminator_urls`

**Platform** - Social media platforms (Facebook, Twitter, Instagram, etc.)

### Junction Tables

**FactCheckTopic** - Links FactChecks to Topics (with confidence scores)

**FactCheckActor** - Links FactChecks to Actors (with role, title, description)

**FactCheckDisseminator** - Links FactChecks to Disseminators

## Testing

This project uses RSpec for testing along with FactoryBot, Faker, Shoulda-Matchers, Timecop, and WebMock.

**Current Status**: 299 passing tests

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

## AI Integration

### OpenAI Usage

This project uses OpenAI's GPT-4o-mini model for two purposes:

1. **Date Parsing** - Converts Spanish date strings to UTC
   - Handles various formats and ambiguous dates
   - Timezone conversion (Colombia/Bogota → UTC)
   - Cost: minimal (~$0.0001 per date)

2. **Entity Extraction** - Extracts structured data from articles
   - Topics with confidence scores (2-5 per article)
   - Actors with types, roles, titles, descriptions
   - Disseminators with platforms and URLs
   - Cost: ~$0.0009 per article

### Cost Estimates

For 1000 articles per month:
- Date parsing: ~$0.10
- Entity extraction: ~$0.90
- **Total: ~$1.00/month**

### AI Features

✅ **Intelligent Matching** - AI uses existing entities to avoid duplicates
✅ **Multi-language Support** - Handles Spanish/English variations
✅ **Self-Improving** - More data = better entity matching over time
✅ **Consistent** - Low temperature (0.3) for reliable extraction

## Deployment

This application is configured for deployment with Kamal (Docker-based deployment).

See `config/deploy.yml` for deployment configuration.

## Environment Variables

Required environment variables:

- **`OPENAI_API_KEY`** - OpenAI API key for AI-powered features (required for date parsing and entity extraction)

Create a `.env` file in the project root:
```bash
OPENAI_API_KEY=your-openai-api-key-here
```

Note: The `.env` file is loaded automatically by the `dotenv-rails` gem in development and test environments.

## Roadmap

### Completed ✅

- [x] Create FactCheckUrl model for tracking URLs
- [x] Create database models (FactCheck, Veredict, PublicationDate)
- [x] Create related entity models (Topic, Actor, Disseminator, Platform)
- [x] Implement ColombiaCheck scraper
- [x] Create background jobs for scraping
- [x] Add AI-powered date parsing
- [x] Add AI-powered entity extraction (Phase 1)
- [x] Comprehensive test suite (299 tests)

### Planned 🚀

- [ ] AI-powered claim extraction (Phase 2)
- [ ] AI sentiment analysis for actors (Phase 3)
- [ ] AI-generated summaries (Phase 3)
- [ ] Add API endpoints for querying fact-checks
- [ ] Add support for additional fact-checking sources (Chequeado, etc.)
- [ ] Implement scheduled/recurring scraping jobs
- [ ] Add search and filtering capabilities
- [ ] Vector embeddings and semantic search (pgvector)
- [ ] GraphQL API

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and code quality checks (`bin/ci`)
4. Ensure all tests pass (`bundle exec rspec`)
5. Submit a pull request

## Documentation

For detailed technical documentation, see:
- **[CLAUDE.md](./CLAUDE.md)** - Comprehensive project architecture and development guidelines
- **[docs/plans/](./docs/plans/)** - Implementation plans for upcoming features

## License

[Add your license here]

## Contact

[Add contact information here]
