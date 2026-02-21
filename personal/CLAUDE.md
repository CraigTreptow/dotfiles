# Global Claude Code Preferences

These instructions apply across all projects.

## Documentation First

Before implementing with any SDK, framework, or external API:
- Look up the official docs (use Context7 MCP tools when available)
- Verify actual field names, return types, and API contracts
- Don't assume behavior based on naming or pattern-matching to similar APIs

## Working Style

- Ask clarifying questions before making assumptions on ambiguous tasks until you are 98% sure of what to do
- Prefer small, focused changes over large sweeping rewrites
- Verify before claiming completion — run tests, check builds, confirm the fix works
- When multiple valid approaches exist, briefly explain the trade-offs and ask which to use

## Code Quality

- Delete unused code rather than commenting it out
- Avoid over-engineering: the minimum complexity that solves the problem is the right amount
- Don't add error handling for scenarios that can't happen
- Don't add backwards-compatibility shims unless explicitly asked

## 🛠 Tech Stack Preferences
- **Backend:** Ruby on Rails (latest stable), PostgreSQL, Redis.
- **Frontend:** Hotwire (Turbo/Stimulus), Bootstrap CSS, vanilla JS/ES6.
- **Testing:** RSpec, Capybara, FactoryBot (prefer TDD).
- **Standards:** StandardRB.

## Style Guide

Follow the Ruby & Rails OOP guidelines defined in the shared style guide located at: ~/.claude/RUBY_RAILS_STYLE.md

## 💎 Ruby & Rails Guidelines
- **Stay Conventional:** Follow "The Rails Way." Use Scaffolding and standard MVC patterns.
- **ActiveRecord:** Always check `db/schema.rb` before suggesting migrations or queries. Fix N+1 issues using `.includes`.
- **Slim Controllers:** Keep logic in Models or Service Objects; use `app/services` for complex business logic.
- **Syntax:** Use modern Ruby (3.x+) syntax: required keyword arguments, pattern matching, and shorthand hash syntax `{ name: }`.
- **Background Jobs:** Prefer `Solid Queue` for Rails 8+ projects.

## 🎨 Frontend & UI Guidelines
- **CSS:** Use Bootstrap. Avoid inline styles or custom CSS files unless necessary.
- **JS:** Lean on Stimulus controllers. Only use heavy JS frameworks if explicitly requested.
- **HTML:** Use semantic HTML5 and Rails View Components for reusable UI elements.

## 🤖 Interaction Rules
- **Plan First:** Before coding, provide a brief bulleted plan of changes.
- **Be Succinct:** Omit conversational filler. Just show the code or the fix.
- **Error Handling:** Always include basic error handling and validation in Models.
- **Verification:** Run `bundle exec rspec` or `bin/rails test` to verify changes before finalizing.

