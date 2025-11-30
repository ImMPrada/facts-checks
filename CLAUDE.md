# CLAUDE.md

## Project Overview

This is a **fact-checking scraper project** designed to collect and document fact-checks from various fact-checking websites. The goal is to aggregate fact-check data from multiple sources to make this information more accessible and analyzable.

## Purpose

- Scrape fact-checking articles from dedicated fact-checking websites
- Store structured data about claims, verdicts, sources, and metadata
- Provide a centralized API to access fact-check information
- Support multiple fact-checking sources (starting with ColombiaCheck.com)

## Tech Stack

- **Framework**: Ruby on Rails 8.1 (API mode)
- **Database**: PostgreSQL
- **Job Queue**: Delayed Job (ActiveRecord backend)
- **Cache**: Solid Cache (Rails 8 default)
- **Testing**: RSpec, FactoryBot, Faker, Shoulda-Matchers, Timecop, WebMock
- **Deployment**: Kamal (Docker-based)
- **Scraping**: HTTParty, Nokogiri
- **AI Integration**: ruby-openai (OpenAI API client)
- **Environment**: dotenv-rails (for loading .env files)

## Project Status

**Current State**: Full scraping and AI-powered date parsing infrastructure complete
- ✅ Fresh Rails 8.1 application initialized
- ✅ Delayed Job installed and configured
- ✅ Database created and migrated
- ✅ ActiveJob configured for all environments
- ✅ RSpec, FactoryBot, Faker, Shoulda-Matchers, Timecop, and WebMock configured
- ✅ All models created and tested:
  - FactCheckUrl (19 tests)
  - FactCheck (14 tests)
  - Veredict (4 tests)
  - PublicationDate (4 tests)
- ✅ Scraping infrastructure:
  - Scraping::Document and Scraping::ElementSet (51 tests)
  - Scraping::ColombiaCheckScraperService (13 tests)
- ✅ Background jobs:
  - ScrapeColombiaCheckJob (7 tests)
  - MineFactCheckUrlJob (10 tests)
  - ProcessPublicationDatesJob (7 tests)
- ✅ Services:
  - FactCheck::CreationService (20 tests)
  - PublicationDates::ParseDateService (11 tests)
- ✅ OpenAI integration:
  - Openai::Client wrapper (11 tests)
  - AI-powered date parsing with timezone conversion
- ✅ **Total: 204 passing tests**
- Clean git history with feature branch `add-date-value-to-publication-dates`

**First Target**: https://colombiacheck.com/

## Technology Decisions

### Why Delayed Job?
- **Database-backed**: Uses PostgreSQL (no additional infrastructure like Redis needed)
- **Simple**: Easy to set up and maintain
- **Sufficient**: Perfect for periodic scraping jobs with moderate volume
- **Mature**: Battle-tested gem with reliable performance
- **Rails-integrated**: Works seamlessly with ActiveJob

### Why OpenAI?
- **Date Parsing**: Scraped dates come in various formats and languages
- **Timezone Conversion**: Automatically converts Colombia/Bogota timezone to UTC
- **Flexible**: Handles ambiguous date strings that regex patterns would miss
- **Future-proof**: Can be extended for other AI-powered features (content analysis, claim extraction, etc.)

## Architecture

### Models
- **FactCheckUrl** ✅
  - Tracks URLs to be scraped and their processing status
  - Fields: url (unique, indexed), digested (boolean, indexed), source (enum), digested_at, attempts, last_error
  - Enum source: `:colombia_check` (expandable for future sources)
  - Scopes: `undigested`, `digested`, `by_source`, `with_errors`
  - Methods: `mark_as_digested!`, `mark_as_failed!`, `full_url`

- **FactCheck** ✅
  - Main model storing individual fact-check articles
  - Fields: source_url (unique, indexed), title, reasoning, digested (boolean), digested_at
  - Associations: belongs_to :veredict (required), belongs_to :publication_date (optional)
  - Scopes: `undigested`, `digested`, `by_veredict`, `by_publication_date`
  - Methods: `mark_as_digested!`

- **Veredict** ✅
  - Standardized verdict types (FALSO, VERDADERO, CUESTIONABLE, etc.)
  - Fields: name (unique, uppercase, indexed)
  - Associations: has_many :fact_checks

- **PublicationDate** ✅
  - Publication date strings and their parsed UTC values
  - Fields: date (string, unique, indexed), value (date, nullable, indexed)
  - Associations: has_many :fact_checks
  - The `date` field stores the raw scraped date string
  - The `value` field stores the AI-parsed UTC date

- **Source** (Future - Optional)
  - Fact-checking organizations/websites metadata
  - Fields: name, url, base_url, active status, etc.

- **Category/Topic** (Future - Optional)
  - Classification of fact-checks
  - For organizing fact-checks by subject matter

### Scraping Architecture

**Reusable Scraping Classes** (`app/classes/scraping/`) ✅:
- **`Scraping::Document`** - HTML document wrapper using Nokogiri and HTTParty
  - Fetch HTML from URLs
  - Find elements by ID, CSS selector, or tag
  - Returns `ElementSet` for chaining operations
  - Methods: `fetch(url)`, `find_by_id(id)`, `find(selector)`, `find_all(selector)`

- **`Scraping::ElementSet`** - Collection of HTML elements
  - Chainable element queries within results
  - Extract text, HTML, attributes
  - Enumerable support for iteration
  - Methods: `find_by_id(id)`, `find(selector)`, `find_all(selector)`, `find_by_tag(tag)`, `text`, `attr(name)`, `pluck_attr(name)`

- **`Scraping::NoArticlesFoundError`** - Custom error for scraping failures

**Source-Specific Services** (`app/services/scraping/`) ✅:
- **`Scraping::ColombiaCheckScraperService`** - ColombiaCheck scraping logic
  - Consumes `Scraping::Document` and `Scraping::ElementSet`
  - Methods:
    - `get_list_of_fact_urls(page_number)` - Scrapes article links from listing pages
    - `create_fact_urls(article_links)` - Creates FactCheckUrl records
    - `mine_fact(url)` - Extracts full fact-check data from article pages

**Pattern**: Generic scraping classes + source-specific services
**Extensibility**: Add new sources by creating new scraper services (e.g., `Scraping::ChequeadoScraperService`)

### Services

**FactCheck Services** (`app/services/fact_check/`) ✅:
- **`FactCheck::CreationService`** - Creates FactCheck records with associated Veredict and PublicationDate
  - Methods: `build`, `save!`
  - Handles creation or lookup of Veredict and PublicationDate records

**PublicationDates Services** (`app/services/publication_dates/`) ✅:
- **`PublicationDates::ParseDateService`** - AI-powered date parsing
  - Uses OpenAI to parse date strings from Colombia/Bogota timezone to UTC
  - Validates parsed dates (year range 1900-2100)
  - Updates PublicationDate.value field
  - Error class: `PublicationDates::Errors::ParseDateServiceError`

### OpenAI Integration

**OpenAI Wrapper** (`app/classes/openai/`) ✅:
- **`Openai::Client`** - Wrapper around ruby-openai gem
  - Configurable model selection (default: gpt-4o-mini)
  - Method: `chat(messages:, temperature:, max_tokens:)`
  - Error handling and logging
  - Error class: `Openai::Errors::ClientError`

### Background Jobs ✅

All jobs use ActiveJob with Delayed Job backend and implement self-re-enqueueing:

- **`ScrapeColombiaCheckJob`** - Scrapes article listing pages
  - Fetches article links from paginated listing pages
  - Creates FactCheckUrl records for each article
  - Re-enqueues itself for next page (10-20 second delay)
  - On completion/error: re-enqueues in 1 week

- **`MineFactCheckUrlJob`** - Processes individual fact-check articles
  - Fetches first undigested FactCheckUrl
  - Scrapes article content using ColombiaCheckScraperService
  - Creates FactCheck with associated Veredict and PublicationDate
  - Re-enqueues itself immediately if more URLs exist
  - On no URLs: re-enqueues in 1 week

- **`ProcessPublicationDatesJob`** - Parses dates using OpenAI
  - Fetches first PublicationDate with nil value
  - Uses ParseDateService to convert to UTC date
  - Re-enqueues itself immediately if more dates exist
  - On no dates: re-enqueues in 1 week
  - Retry mechanism: 3 attempts, 5 minute wait

### Rake Tasks ✅

All tasks enqueue background jobs:

- **`rake scraping:enqueue_facts_to_check`** - Starts scraping article listings
  - Enqueues ScrapeColombiaCheckJob
  - Job self-manages pagination and re-enqueueing

- **`rake scraping:mine_fact_urls`** - Starts processing fact-check articles
  - Enqueues MineFactCheckUrlJob
  - Job processes all undigested URLs automatically

- **`rake publication_dates:process_dates`** - Starts AI date parsing
  - Enqueues ProcessPublicationDatesJob
  - Job processes all PublicationDates with nil value
  - Requires OPENAI_API_KEY environment variable

## Environment Variables

Required environment variables:
- **`OPENAI_API_KEY`** - OpenAI API key for date parsing (required for ProcessPublicationDatesJob)

Create a `.env` file in the project root:
```bash
OPENAI_API_KEY=your-openai-api-key-here
```

Note: The `.env` file is loaded automatically by the `dotenv-rails` gem in development and test environments.

## Development Guidelines

### Code Organization
- Follow Rails conventions and namespacing
- **One class per file** - No nested class definitions
- **Errors in separate files** - Use `module_name/errors/error_name.rb` pattern
  - Example: `Openai::Errors::ClientError` in `app/classes/openai/errors/client_error.rb`
  - Example: `PublicationDates::Errors::ParseDateServiceError` in `app/services/publication_dates/errors/parse_date_service_error.rb`
- **Avoid instance variables** - Use attr_accessor, attr_reader, and attr_writer instead
- Use `attr_accessor` in `private` section for internal instance variables
- Use `attr_reader` and `attr_writer` in public section for publicly exposed attributes
- Example:
```ruby
  class MyService
    attr_reader :publication_date, :openai_client  # Public read access
    attr_accessor :public_read_write_attribute

    def initialize(publication_date, openai_client: nil)
      publication_date = publication_date
      openai_client = openai_client || Openai::Client.new
    end

    private

    attr_accessor :parsed_result  # Private internal state
    attr_writer :publication_date, :openai_client
  end
```
- Use service objects for complex business logic
- Keep scrapers modular and source-specific
- Each fact-checking source should have its own scraper implementation

### Scraping Strategy
- Use Nokogiri for HTML parsing
- Handle pagination appropriately
- Include error handling and logging
- Store source URLs for data verification
- Respect rate limiting and robots.txt

### Data Integrity
- Use upsert pattern to avoid duplicates (match on source URL)
- Validate data before persisting
- Log scraping errors for review
- Track scraping metadata (last_scraped_at, etc.)

## Workflow

### Starting the Background Worker
```bash
bin/delayed_job start
```

### Scraping Workflow
1. **Scrape article listings**: `rake scraping:enqueue_facts_to_check`
   - Discovers article URLs and creates FactCheckUrl records
   - Job continues automatically across all pages

2. **Mine fact-check content**: `rake scraping:mine_fact_urls`
   - Extracts full content from each article
   - Creates FactCheck, Veredict, and PublicationDate records
   - Job processes all undigested URLs automatically

3. **Parse dates with AI**: `rake publication_dates:process_dates`
   - Converts date strings to UTC dates using OpenAI
   - Updates PublicationDate.value fields
   - Job processes all nil values automatically

### Monitoring
- Check Delayed Job queue: `rails console` → `Delayed::Job.count`
- Check processing status:
  - `FactCheckUrl.undigested.count` - URLs pending processing
  - `FactCheck.count` - Total fact-checks scraped
  - `PublicationDate.where(value: nil).count` - Dates pending AI parsing

## Future Considerations

- Support for additional fact-checking sources (architecture supports easy expansion)
- API endpoints for querying fact-checks
- Search and filtering capabilities
- GraphQL API for flexible querying
- Data export functionality (JSON, CSV)
- Scheduled/automated scraping (cron or scheduled jobs)
- Content analysis using AI (claim extraction, sentiment analysis)
- Duplicate detection and deduplication

## Git Workflow

- `main` branch is the primary branch
- Clean, focused commits
- Descriptive commit messages

## Notes

- This project was reset from a previous book-scraping project
- All old book-related code has been removed
- Starting completely fresh for fact-checking domain
