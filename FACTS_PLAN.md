# Facts System — Plan

## Overview

Giki has ~814 climate actions from the Transition Actions Library. The system narrows these to the 50-100 relevant to a specific company through a **questions -> facts -> rules -> actions** pipeline:

1. **Questions** are asked throughout the UI (some during onboarding, more as the user explores)
2. Answers set **facts** (~60) about the company
3. **Rules** (~500) derive additional facts from answered ones
4. **Actions** (~716, up to 5k) are filtered based on fact conditions

The schema is not final — new question types, rule types, fact types may be added. Design for flexibility.

Source data lives in `../facts/data/*.json`. See `../facts/README.md` and `../facts/CLAUDE.md` for full documentation.

The FE dev has written an API spec at `~/Downloads/api-spec.md` for the admin React app. It may have inaccuracies and the approach has changed significantly (see Storage below).

## Two layers of data

### 1. Facts engine (dataset blob)

The interdependent core: **facts**, **questions**, **rules**, and **action conditions**. These change together — editing a fact often requires editing related questions, rules, and the action conditions that reference it. Stored as a single JSONB blob per dataset with draft/publish workflow.

### 2. Surrounding data (normal tables)

Everything else: **action metadata** (titles, descriptions, GHG categories, tags, etc.), **reference values** (industries, business sizes, etc.), **hotspots**, and eventually more. These are larger, independently managed, and use standard CRUD with normal DB tables.

The facts engine blob references surrounding data by ID (e.g. industry IDs in rule conditions, action IDs for action conditions). Action metadata in normal tables is linked to action conditions in the blob by action ID/key.

## Concepts

### Facts

Properties about a company. ~60 total, three types:
- `boolean_state` — true/false/unknown/not_applicable (e.g. `has_company_vehicles`)
- `enum` — single value from a reference values group (e.g. `size`)
- `array` — multiple values from a reference values group (e.g. `industries`)

Facts are either **core** (set directly by questions) or **derived** (computed by rules). Derived facts include:
- **Composite facts**: `uses_buildings` (from `owns_buildings OR leases_buildings`)
- **Relevance facts**: `cat_6_relevant` (combines operational truth + industry materiality to gate actions)

Facts are disabled (`enabled: false` in the blob) rather than removed. This keeps the key reserved (prevents reuse with different semantics), leaves company data untouched, and allows re-enabling. The evaluation engine skips disabled facts. Same pattern applies to questions, rules, and action conditions in the blob.

### Questions

Questions are asked throughout the UI — some during onboarding, others as the user explores different areas. Four current types (may evolve):
- `boolean_state` — yes/no/not sure, sets one fact
- `single-select` — pick one from a list, sets one fact
- `multi-select` — pick many from a list, sets one array fact
- `checkbox-radio-hybrid` — pick options (some exclusive), sets multiple facts via a mapping

Questions link to facts in two ways:
- `fact` (string) — sets a single fact (boolean_state, single-select, multi-select)
- `facts` (object) — maps option values to fact assignments (checkbox-radio-hybrid), includes a `defaults` key

Questions have:
- `show_when` / `hide_when` — conditions controlling visibility (same shape as rule conditions)
- `options_ref` — reference to a reference values group_key for the option list
- `options` — inline options (for checkbox-radio-hybrid)
- `unknowable` — whether "Not sure" / "Don't know" is offered
- `description` — optional help text

### Rules

Fire automatically when facts are known. Each rule has:
- `sets` — target fact key
- `value` — what to set it to
- `when` — trigger condition

Three condition shapes (may evolve):
- Simple: `{ "remote_only": true }`
- Array match (by ID): `{ "industries": [1, 3, 7] }`
- Any-of (OR): `{ "any": [{ "owns_buildings": true }, { "leases_buildings": true }] }`

Two sources:
- **General rules** — hand-written: derivation, mutual exclusion, logical constraints, relevance derivation
- **Hotspot rules** — generated from industry materiality data: suppress relevance facts to `not_applicable`

Hotspot rules have higher precedence (earlier in the ordered list). Earlier rules win when multiple target the same fact.

### Action Conditions

Each action has `include_when` and `exclude_when` conditions that determine whether it's relevant to a company, plus optional `dismiss_options` that let users set facts when dismissing an action (e.g. "We don't fly for work" sets `travel_includes_flying: false`). Action enablement is also controlled in the blob (`enabled: true/false`) — an action is only active when the live dataset has it enabled. This means new actions are inert until a dataset containing them is published.

Action metadata (title, description, GHG categories, tags, etc.) lives in normal tables, linked to conditions in the blob by action key. The actions table has no `enabled` column — the blob is the single source of truth for what's active.

### Constants

Option lists (industries, business sizes, building types, etc.) stored in the blob alongside facts, questions, and rules. ~7 groups, ~130 values total. Each value has a numeric ID (scoped per group), name, optional description, and enabled flag.

IDs are stable across dataset versions — they carry over when a draft is created. IDs are never reused within a group (monotonically increasing). The FE manages ID assignment during blob editing.

Referenced by numeric ID in rule conditions, action conditions, and company facts. The in-memory cache can build compact lookup structures from the blob on load.

### Hotspots (not yet in scope)

Per-industry GHG materiality ratings. Used to generate hotspot suppression rules. Will be designed later.

## Storage: Single JSONB Blob per Dataset

The facts engine (facts, questions, rules, action conditions, constants) is stored as a **single JSONB blob** in one row per dataset.

This is the simplest approach because:
- The data is tiny — reading/writing the whole blob is negligible
- No need for separate tables, FKs, or `dataset_id` on every row
- Matches the current architecture (static JSON files), just in Postgres
- Diffing is trivial — compare two JSON blobs
- Export/import is the blob itself
- Atomic by nature — every write saves the complete state
- Fact key changes are reflected in action conditions atomically

The admin React app loads the full blob into client-side state, makes edits locally (with localStorage for work-in-progress), and saves the whole thing back.

Concurrent write safety: `SELECT ... FOR UPDATE` locks the dataset row during save.

### FactsDataset Model (`facts_datasets` table)

```
facts_datasets
├── id          (integer PK)
├── status      (string: "draft", "live", "archived")
├── data        (jsonb — facts, questions, rules, action conditions, constants)
├── test_cases  (jsonb — regression test cases)
├── timestamps
```

- One `live` dataset at any time — this is what the evaluation engine uses
- **One draft at a time** — enforced at creation. Prevents merge conflicts and test case inconsistencies. Future: auto-rebase (apply clean diffs only, reject on conflict).
- Archived datasets are kept for history/rollback

### Actions Model

```
actions
├── id            (integer PK)
├── external_id   (string, unique — ID from upstream TAL/POT data)
├── title         (string)
├── timestamps
```

- ~716 rows (up to 5k). More metadata columns will be added later.
- `external_id` used to sync with upstream data source.
- Action conditions (include_when/exclude_when) live in the dataset blob, keyed by a stable action key that maps to this table's `id` or a generated key.

### Dataset JSON Structure

The `data` JSONB column contains the facts engine:

```json
{
  "facts": {
    "has_company_vehicles": { "type": "boolean_state", "core": true, "category": "transport-travel", "enabled": true },
    "size": { "type": "enum", "core": true, "values_ref": "business_size" },
    "industries": { "type": "array", "core": true, "values_ref": "industry" }
  },
  "questions": [
    {
      "type": "boolean_state",
      "label": "Does your company own or lease any vehicles?",
      "fact": "has_company_vehicles",
      "hide_when": { "scope_1_mobile_relevant": "not_applicable" }
    },
    {
      "type": "checkbox-radio-hybrid",
      "label": "Which of these apply?",
      "options": [
        { "label": "We own our buildings", "value": "own_buildings" },
        { "label": "Not sure", "value": "not_sure", "exclusive": true }
      ],
      "facts": {
        "defaults": { "owns_buildings": false, "leases_buildings": false },
        "own_buildings": { "owns_buildings": true },
        "not_sure": { "owns_buildings": "unknown", "leases_buildings": "unknown" }
      }
    }
  ],
  "rules": [
    { "sets": "uses_buildings", "value": true, "source": "general", "when": { "any": [{ "owns_buildings": true }, { "leases_buildings": true }] } },
    { "sets": "scope_1_mobile_relevant", "value": "not_applicable", "source": "hotspot", "when": { "industries": [1, 3, 7] } }
  ],
  "constants": {
    "industry": [
      { "id": 1, "name": "Advertising", "description": null, "enabled": true },
      { "id": 2, "name": "Broadcasting", "description": null, "enabled": true }
    ],
    "business_size": [
      { "id": 1, "name": "Self Employed", "description": "Sole traders", "enabled": true },
      { "id": 2, "name": "Small", "description": "10-50 employees", "enabled": true }
    ]
  },
  "action_conditions": {
    "action_key_1": {
      "enabled": true,
      "include_when": { "cat_6_relevant": true, "travel_includes_flying": true },
      "exclude_when": {},
      "dismiss_options": [
        { "label": "We don't fly for work", "sets": { "travel_includes_flying": false } },
        { "label": "Not relevant right now", "sets": null }
      ]
    },
    "action_key_2": {
      "enabled": true,
      "include_when": { "uses_buildings": true, "size": [3, 4, 5] },
      "exclude_when": { "remote_only": true }
    }
  }
}
```

### Blob Validation

On save, the API validates the blob both structurally and semantically:
- **Structural**: facts is a map, questions is an array, rules have `sets`/`value`/`when`, action conditions have `include_when`/`exclude_when`
- **Semantic**: questions reference facts that exist, `values_ref` points to a real group_key, action conditions reference valid fact keys, no duplicate fact keys
- **Smoke test**: run the rules engine against a stub company to verify the dataset doesn't produce errors

Validation errors are returned to the FE. A blob that fails validation cannot be published (but can be saved as a draft for work-in-progress).

### Admin Workflow: Draft/Publish

1. **Start new version** — copies live dataset's blob into a new draft row
2. **Edit locally** — FE loads the blob, admin edits in the React UI, work-in-progress saved to localStorage
3. **Save draft** — FE writes the full blob back to the API (locked with SELECT FOR UPDATE, validated)
4. **Preview** — pick a company, run evaluation engine against draft data, compare results with live
5. **Run tests** — execute test cases against draft, review pass/fail/diffs
6. **Go live** — mark draft as live, old live as archived. One transaction, atomic. Blob must pass validation.
7. **Rollback** — swap back to an archived dataset if needed

### Test Cases

Regression tests for reference data. Stored in the dataset's `test_cases` JSONB column (so they travel with the dataset on copy).

```json
[
  {
    "name": "Small advertising agency",
    "input_facts": { "size": 2, "industries": [1], "owns_buildings": true },
    "expected_actions": ["action_key_1", "action_key_2"]
  }
]
```

When editing a draft:
- Run test suite: feed each test case's `input_facts` through the evaluation engine with draft data
- Compare resulting actions against `expected_actions`
- Show diffs: "3 new actions, 2 removed" per test case
- Admin updates expectations for deliberate changes, investigates unintended ones

### Dataset Diffing

Two levels of diff between any two datasets:

1. **Reference data diff** — what changed in the definitions (facts added/removed/modified, questions reordered, rules changed, action conditions changed, etc.). Just compare the two JSON blobs.
2. **Impact diff** — what those changes mean for companies. Run test cases against both datasets and compare the resulting action lists.

## Architecture: In-Memory Caching

The live dataset's JSONB blob is cached in memory at the Rails level. Everything is in the blob — no separate caches needed.

- On boot: load the live dataset blob into Ruby objects
- Evaluation engine: operates purely on cached Ruby objects, never queries DB for reference data
- DB queries in the hot path: only reading/writing CompanyFact data

### Cache Invalidation

Each Rails process tracks the `id` of the live facts dataset it last loaded. On each request, a single query checks the current live id: `SELECT id FROM facts_datasets WHERE status = 'live'`. If it differs, reload.

When a dataset is published, a new row becomes live (different `id`), so all processes pick up the new data on their next request.

This avoids pub/sub, DB triggers, or cross-process signalling. Each process independently detects staleness. Works cleanly with multi-process deployments (multiple ECS tasks, Puma workers, etc.).

## Admin API Endpoints

### Facts Datasets
```
GET    /admin/facts_datasets/live         — the live blob + test cases
GET    /admin/facts_datasets/draft        — the current draft blob + test cases
POST   /admin/facts_datasets/draft        — create new draft (copies live)
PATCH  /admin/facts_datasets/draft        — save draft blob (locked write, validated)
DELETE /admin/facts_datasets/draft        — delete the draft
POST   /admin/facts_datasets/draft/publish — validate, run test cases, go live if all pass
```

No individual CRUD endpoints for facts/questions/rules. The FE manages all editing as client-side state against the blob.

No separate reference values API — constants are managed as part of the blob.

## Design Principles

1. **Two layers** — facts engine (blob, versioned) vs surrounding data (normal tables, standard CRUD).
2. **Reference data is tiny** — one JSONB blob per dataset. Don't over-engineer.
3. **In-memory caching** — cache the live dataset + reference values. Evaluation engine never hits DB for reference data.
4. **CompanyFact is the scale problem** — 1M companies x 100 facts. Design separately.
5. **Schema is evolving** — the JSONB blob structure can evolve without migrations.
6. **Admin-only API** — `Admin::` controller namespace.
7. **Fact keys are meaningful strings** — used throughout conditions in the blob.
8. **Constants use numeric IDs** — industries, sizes, etc. in the blob with stable IDs per group. Referenced by ID in conditions and company facts, resolved to names client-side.
9. **FE owns editing UX** — API just stores and retrieves the blob. All editing logic is client-side.
10. **Enabled/disabled everywhere** — blob items use `"enabled": false`. Keys stay reserved, data untouched. No hard deletes.
11. **Validate on save** — structural + semantic validation of the blob. Smoke test with rules engine. Must pass validation to publish.

## Open Questions

### Derived facts: store or recompute? (TBD)

When a company's facts are evaluated, do we store derived facts or recompute them on the fly?

- **Recompute on the fly**: only store core facts (user's actual answers). Derived facts computed from cached rules every time. Simpler, avoids mass-recompute on dataset publish. ~500 rules is microseconds.
- **Store derived facts**: faster reads, enables querying "which companies have this derived fact". But every dataset publish potentially invalidates derived facts for 1M companies.

Leaning toward recompute. But storing makes "which companies have X" queries easier. Needs further discussion.

## TODO

### FactsDataset model + API
- [x] Add FactsDataset model and migration
- [x] Add factory
- [x] Add seed task (import from `../facts/data/*.json` into initial live dataset, converting industry/size strings to IDs)
- [x] Add admin controller (GET live/draft, POST/PATCH/DELETE draft, POST publish)
- [ ] Add blob validation (structural + semantic + smoke test)
- [x] Add admin serializer
- [x] Add controller tests

### Evaluation engine
- [ ] In-memory cache loader (parse live dataset blob into Ruby objects)
- [ ] Cache invalidation (check live dataset id per request)
- [ ] Rule evaluation engine (apply rules to a set of input facts)
- [ ] Action filtering engine (apply action conditions to determine relevant actions)

### Test cases + diffing
- [ ] Test runner command (evaluate test cases against a dataset)
- [ ] Dataset diff command (compare two datasets)
- [ ] Admin endpoints for test + diff

### Actions
- [ ] Add Action model and migration
- [ ] Add factory
- [ ] Add seed task (import from `../facts/data/actions.json`)
- [ ] Add admin controller for action metadata CRUD
- [ ] Add admin serializer
- [ ] Add controller tests

### CompanyFact (TBD)
- [ ] Design approach (JSONB blob per company? Store derived facts or recompute?)
- [ ] Implementation

## Seed/Import Notes

The initial live dataset must be built from the JSON files in `../facts/data/`. The import order matters:

1. **Reference values first** — import `constants.json`. Each key becomes a `group_key`, each value becomes a `ReferenceValue` row. Map group names: `BUSINESS_SIZE_OPTIONS` → `business_size`, `INDUSTRY_OPTIONS` → `industry`, `BUILDING_TYPE_OPTIONS` → `building_type`, `SUPPLY_CHAIN_CHALLENGE_OPTIONS` → `supply_chain_challenge`, `MEASURES_EMISSIONS_OPTIONS` → `measures_emissions`, `REDUCTION_TARGETS_OPTIONS` → `reduction_targets`. INDUSTRY_OPTIONS values have `{label, value}` shape; others are plain strings.

2. **Build the blob** — combine:
   - `facts.json` → `data.facts` (add `category` and `enabled: true` to each)
   - `questions.json` → `data.questions` (array, ordered)
   - `general_rules.json` + `hotspot_rules.json` → `data.rules` (hotspot rules first, then general rules; add `source` field)
   - `actions.json` → `data.action_conditions` (extract `include_when`/`exclude_when` from each action, keyed by a generated action key)
   - In all conditions, convert industry name strings to reference value IDs (e.g. `"Advertising"` → `1`)
   - In all conditions, convert size strings to reference value IDs

3. **Create initial dataset** — one row with `status: "live"`, the built blob as `data`, empty `test_cases: []`.

### Source file sizes (for reference)
- `facts.json` — 4.3KB (~60 facts)
- `questions.json` — 11KB (~25 questions)
- `general_rules.json` — 2.8KB (~30 rules)
- `hotspot_rules.json` — 3.4KB (~15 rules)
- `actions.json` — 339KB (~716 actions, mostly industry string lists — will shrink dramatically with IDs)
- `constants.json` — 16KB (~7 groups, ~130 values)
- `hotspots.json` — 17KB (per-industry GHG ratings, used to generate hotspot_rules)

### Action key generation
Actions in the current CSV/JSON don't have stable keys. The seed task will need to generate them (e.g. slugified title, or sequential `action_1`, `action_2`). These keys link action conditions in the blob to action metadata in the actions table. Once assigned, keys must be stable.
