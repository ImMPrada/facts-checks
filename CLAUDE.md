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

## Project Status

**Current State**: Scraping infrastructure complete and tested
- ✅ Fresh Rails 8.1 application initialized
- ✅ Delayed Job installed and configured
- ✅ Database created and migrated
- ✅ ActiveJob configured for all environments
- ✅ RSpec, FactoryBot, Faker, Shoulda-Matchers, Timecop, and WebMock configured
- ✅ FactCheckUrl model created with specs (19 passing tests)
- ✅ HTTParty and Nokogiri installed
- ✅ Scraping::Document and Scraping::ElementSet classes created with comprehensive specs (51 passing tests)
- ✅ **Total: 70 passing tests**
- ⏳ Additional models to be created (FactCheck, Source, etc.)
- ⏳ ColombiaCheckScraperService to be implemented
- Clean git history with feature branch `enqueue-facts-to-check`

**First Target**: https://colombiacheck.com/

## Technology Decisions

### Why Delayed Job?
- **Database-backed**: Uses PostgreSQL (no additional infrastructure like Redis needed)
- **Simple**: Easy to set up and maintain
- **Sufficient**: Perfect for periodic scraping jobs with moderate volume
- **Mature**: Battle-tested gem with reliable performance
- **Rails-integrated**: Works seamlessly with ActiveJob

## Planned Architecture

### Models
- **FactCheckUrl** ✅ (Created)
  - Tracks URLs to be scraped and their processing status
  - Fields: url (unique, indexed), digested (boolean, indexed), source (enum), digested_at, attempts, last_error
  - Enum source: `:colombia_check` (expandable for future sources)
  - Scopes: `undigested`, `digested`, `by_source`, `with_errors`
  - Methods: `mark_as_digested!`, `mark_as_failed!`

- **FactCheck** (To Be Created)
  - Main model storing individual fact-check articles
  - Fields: title, claim, verdict, date, url, author, content, etc.

- **Source** (Optional - To Be Created)
  - Fact-checking organizations/websites metadata
  - Fields: name, url, base_url, active status, etc.

- **Category/Topic** (Optional - To Be Created)
  - Classification of fact-checks
  - For organizing fact-checks by subject matter

- **Verdict** (Optional - To Be Created)
  - Standardized verdict types across sources
  - Different sources may use different rating systems

### Scraping Architecture

**Reusable Scraping Classes** (`app/classes/scraping/`):
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

**Source-Specific Services** (`app/services/scraping/`):
- **`Scraping::ColombiaCheckScraperService`** - ColombiaCheck scraping logic
  - Consumes `Scraping::Document` and `Scraping::ElementSet`
  - Implements ColombiaCheck-specific parsing and business logic

**Pattern**: Generic scraping classes + source-specific services
**Extensibility**: Add new sources by creating new scraper services (e.g., `Scraping::ChequeadoScraperService`)

### Background Jobs
- ActiveJob classes for scraping tasks
- Delayed Job for job processing
- Jobs can be enqueued via rake tasks, API endpoints, or scheduled
- Each source gets its own job class (e.g., `ScrapeColombiaCheckJob`)

### Rake Tasks
- Tasks for running scrapers (e.g., `rake scrape:colombia_check`)
- Tasks will enqueue jobs rather than running synchronously
- Scheduled/background job support for regular updates

## Development Guidelines

### Code Organization
- Follow Rails conventions and namespacing
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

## Future Considerations

- Support for multiple fact-checking sources (expandable architecture)
- Standardization of verdicts across different sources
- API endpoints for querying fact-checks
- Search and filtering capabilities
- Automated/scheduled scraping jobs
- Data export functionality

## Git Workflow

- `main` branch is the primary branch
- Clean, focused commits
- Descriptive commit messages

## Notes

- This project was reset from a previous book-scraping project
- All old book-related code has been removed
- Starting completely fresh for fact-checking domain
