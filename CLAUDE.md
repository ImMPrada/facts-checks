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
- **Job Queue**: Solid Queue (Rails 8 default)
- **Cache**: Solid Cache (Rails 8 default)
- **Deployment**: Kamal (Docker-based)
- **Scraping**: Nokogiri (to be added)

## Project Status

**Current State**: Initial setup phase
- Fresh Rails 8.1 application initialized
- No models created yet
- No scraping logic implemented
- Clean git history (single "Initial commit")

**First Target**: https://colombiacheck.com/

## Planned Architecture

### Models (To Be Created)
- **FactCheck**: Main model storing individual fact-check articles
  - Fields: title, claim, verdict, date, url, author, content, etc.
- **Source**: Fact-checking organizations/websites
  - Fields: name, url, base_url, active status, etc.
- **Category/Topic**: Classification of fact-checks
  - Optional: for organizing fact-checks by subject matter
- **Verdict**: Standardized verdict types across sources
  - Different sources may use different rating systems

### Services Pattern
- Scraping services per source (e.g., `ColombiaCheck::ScrapService`)
- Upsert services for creating/updating records
- Extendable architecture for adding new sources

### Rake Tasks
- Tasks for running scrapers (e.g., `rake scrape:colombia_check`)
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
