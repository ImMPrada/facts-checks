# Feature: [Add related entities]

## Status
- [ ] Planned
- [ ] In Progress
- [ ] Completed

## Overview
For analyzing facts, openAI will help us to analyze facts, and mine some information; here we are creatign tables, models, and its specs tests

## Requirements

### Functional Requirements
1. Create tables topics and fact_check_topics
2. Requirement 2
3. Requirement 3

## Technical Specifications

### Data Model
- create corresponding models
- add and test associations

## Database Changes

### Migrations Needed
- [ ] Create table `topics` with a name (index)
- [ ] Create table `fact_check_topics` with a topic_id (Fk), fact_check_id (FK)
- [ ] Create table `actors` with a name (index), actor_type_id (FK)
- [ ] Create table `actor_types` with a name (index), examples person, government_entity, organization
- [ ] Create table `fact_check_actors` with a topic_id (Fk), fact_check_id (FK), actor_role_id (FK)
- [ ] Create table `actor_roles` with a name, example target, mentioned, beneficiary, source
- [ ] Create table `disseminators` with a name, platform_id (FK)
- [ ] Create table `disseminator_urls` with disseminator_id (FK), url
- [ ] Create table `platforms` with a name (index)
- [ ] Create table `fact_check_disseminators` with a fact_check_id (FK), disseminator_id (FK)

## Testing Requirements

### Unit Tests
- All models for each new table

## Documentation Needs
- [ ] Update README
