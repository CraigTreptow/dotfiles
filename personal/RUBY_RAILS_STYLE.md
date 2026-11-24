# Ruby & Rails Style Guide

Goal: good-quality code, meaningful tests, maintainable apps. Sandi Metz's work is the baseline.

## Sandi Metz's Rules

1. A class is no longer than **100 lines**.
2. A method is no longer than **5 lines**.
3. A method takes no more than **4 parameters** (a hash of options counts as parameters).
4. A controller instantiates only **one object**, and a view knows about only **one instance variable**.

### When code would break a rule

- **Default:** stop and refactor until it complies before moving on.
- **Justified exception:** stop and state (1) which rule is broken, (2) why breaking it is
  better here, and (3) what you're doing instead. Then continue — no need to wait for approval.
- **Record the exception in the code** so it stays settled:
  `# rubocop:disable Metrics/MethodLength -- <reason>` before the method and
  `# rubocop:enable Metrics/MethodLength` after it. A justification only stated in chat gets
  flagged again on the next turn.
- Reasonable exceptions: framework DSL blocks (`validates`, associations, routes), migrations
  (excluded automatically), unmodified generator output such as scaffold `create`/`update`
  actions, and splits that would only add noise. "It was faster" is not a justification.
  Once you edit generated code, it's yours — make it comply.
- Rules 1–3 are checked by the Stop hook (see Quality Gate). Rule 4 is your judgment — wrap
  what a view needs in a single presenter/facade object rather than adding instance variables.

## Testing — "The Magic Tricks of Testing"

Test the public interface; let the message type decide what to assert.

| Message | Query (returns a value, no side effects) | Command (changes something) |
|---|---|---|
| **Incoming** (public API of the object under test) | Assert the **return value** | Assert the **direct public side effect** |
| **Sent to self** (private methods) | Don't test | Don't test |
| **Outgoing** (to collaborators) | Don't test; stub if needed, never expect | **Expect it was sent** (mock) |

- Use verified doubles (`instance_double`, `class_double`) so mocks fail when the real interface changes.
- A test that breaks on a refactor that didn't change behavior is testing implementation — fix the test.
- Write the failing test first (TDD); name tests after behavior, not methods.
- Prefer a few meaningful examples over exhaustive permutations; cover edge cases that matter to users.
- **Shared role tests:** when several classes play the same role (a duck type or a domain
  concern), write one shared example group that checks the interface, and include it in each
  player's spec so a renamed or missing method fails in tests, not in production.
- **Integration tests only for workflows that cross domains.** Everything else is a fast unit
  test of one object through its public interface.

## Design Principles (POODR / 99 Bottles)

- **Single responsibility:** if describing a class needs "and" or "or", split it.
- **Depend on behavior, inject dependencies:** pass collaborators in; don't hard-code class names deep inside methods.
- **Law of Demeter:** talk to immediate neighbors; avoid `a.b.c.d` chains across object boundaries.
- **Composition over inheritance:** inherit only for true is-a relationships with shallow hierarchies.
- **Depend on things that change less often than you do.**
- **Shameless green first:** get the simplest passing solution, then refactor.
- **Refactor only under green tests**, in small steps, keeping tests passing after each step.
- Name things for what they mean in the domain, not how they're implemented.

## Boundaries & Modularity

Adapted from David Silva's *Modular Rails*, applied inside a conventional Rails app.

- **Organize by business capability, not technical layer.** Group code under domain namespaces
  (`Billing::Invoice` in `app/models/billing/`, `Billing::InvoiceGenerator` in
  `app/services/billing/`), not a flat `app/services/` pile.
- **Central models are composition points, not god objects.** `User` includes one concern per
  domain it takes part in (`include Billing::Billable`); the domain's behavior lives in that
  concern, inside the domain's namespace.
- **Cross a boundary only through its public interface:** a concern, a public method on the
  domain's entry-point object, or an event. Don't reach into another domain's internals, and
  across domains refer to records by ID rather than chaining through associations.
- **No dependency cycles between domains; depend toward stability.** Feature domains may depend
  on a small, stable core, never the reverse, and not on each other without a clear reason.
  Break a cycle with an event or by inverting the dependency.
- **Engines are earned, not default.** Don't start with mountable engines. Suggest extracting
  one only when a domain's boundary is clear and stable and the overhead pays for itself.

## Quality Gate

A Stop hook runs on changed Ruby files (uncommitted vs `HEAD`) when Claude finishes a turn:

- `bundle exec standardrb`
- `bundle exec rubocop -c ~/.claude/metz-rubocop.yml` (Metz rules 1–3)

If it reports violations, fix them: run `bundle exec standardrb --fix` first, then fix the rest
by hand, applying the rule-break protocol above to any Metz violation you intend to keep.
