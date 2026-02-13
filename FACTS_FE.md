# Facts Engine — Frontend Guide

## What this is

Giki narrows ~800 climate actions down to the ~50-100 relevant to a specific company. It does this through a pipeline: **questions** set **facts** about a company, **rules** derive additional facts, and **actions** are filtered based on those facts.

Questions are asked throughout the UI — some during onboarding, others as the user explores different areas of the platform.

The admin UI lets admins edit this pipeline and test the effects before going live.

## Key decisions

### Two layers of data

**Facts engine (dataset blob)** — the interdependent core: facts, questions, rules, and action conditions. Stored as a single JSONB blob per dataset. Versioned with draft/publish workflow.

**Surrounding data (normal tables)** — action metadata (titles, descriptions, tags), reference values (industries, sizes), hotspots. Standard CRUD, independently managed.

Action conditions live in the blob (versioned with facts they reference). Action metadata lives in normal tables, linked by action key.

### Everything in the engine is one JSON blob

The facts engine data (facts, questions, rules, action conditions) is stored as a single JSONB blob in Postgres, one row per "dataset." This is because:
- The data is tiny (~50KB)
- Facts, questions, rules, and action conditions are deeply interdependent — changing a fact key must be reflected in all conditions atomically
- It enables draft/publish workflow and diffing

### Draft/publish workflow

There's always one **live** dataset. Admins create a **draft** (copied from live), make changes, test them, and publish when ready. Publishing atomically swaps the live dataset. Only one draft can exist at a time.

### Editing happens client-side

The API doesn't have individual CRUD endpoints for facts/questions/rules. Instead:
1. FE loads the full blob from the API
2. Admin edits in the React UI (all state management is client-side)
3. Work-in-progress saves to localStorage
4. When the admin explicitly saves, the full blob is written back to the API
5. Concurrent saves are prevented with row-level locking

### Reference values are separate

Options lists (industries, business sizes, building types, etc.) live in a normal DB table (`reference_values`), not in the blob. They're stable, rarely change, and are referenced by numeric ID everywhere. The FE loads them once and resolves IDs to display names client-side.

### Soft delete everywhere

Items in the blob (facts, questions, rules, action conditions) are disabled by setting `"enabled": false` rather than removing them. Reference values use an `enabled` boolean column. This keeps keys reserved, prevents reuse, and leaves company data untouched. The admin UI should show disabled items visually (greyed out / strikethrough) and allow re-enabling. The evaluation engine skips disabled items.

### Blob validation

The API validates the blob on save:
- **Structural**: correct shape (facts is a map, questions is an array, etc.)
- **Semantic**: questions reference existing facts, `values_ref` points to real groups, action conditions reference valid fact keys
- **Smoke test**: runs the rules engine against a stub company

Validation errors are returned to the FE. A blob that fails validation can be saved as a draft but cannot be published.

## API endpoints

### Facts Datasets
```
GET    /admin/facts_datasets/live         — the live blob + test cases
GET    /admin/facts_datasets/draft        — the current draft blob + test cases
POST   /admin/facts_datasets/draft        — create new draft (copies live)
PATCH  /admin/facts_datasets/draft        — save draft blob (validated)
DELETE /admin/facts_datasets/draft        — delete the draft
POST   /admin/facts_datasets/draft/publish — validate, run test cases, go live if all pass
```

### Reference Values
```
GET    /admin/reference_values      — all reference values (grouped by group_key)
POST   /admin/reference_values      — create a value
PATCH  /admin/reference_values/:id  — update a value
DELETE /admin/reference_values/:id  — soft delete a value
```

## Dataset blob structure

The blob returned by `GET /admin/facts_datasets/:id` has this shape:

```json
{
  "data": {
    "facts": {
      "has_company_vehicles": {
        "type": "boolean_state",
        "core": true,
        "category": "transport-travel",
        "enabled": true
      },
      "size": {
        "type": "enum",
        "core": true,
        "values_ref": "business_size"
      },
      "industries": {
        "type": "array",
        "core": true,
        "values_ref": "industry"
      }
    },
    "questions": [
      {
        "type": "boolean_state",
        "label": "Does your company own or lease any vehicles?",
        "description": "Company cars, vans, trucks...",
        "fact": "has_company_vehicles",
        "hide_when": { "scope_1_mobile_relevant": "not_applicable" }
      },
      {
        "type": "checkbox-radio-hybrid",
        "label": "Which of these apply to your company?",
        "options": [
          { "label": "We own our buildings", "value": "own_buildings" },
          { "label": "We rent or lease", "value": "lease_buildings" },
          { "label": "Not sure", "value": "not_sure", "exclusive": true }
        ],
        "facts": {
          "defaults": { "owns_buildings": false, "leases_buildings": false },
          "own_buildings": { "owns_buildings": true },
          "lease_buildings": { "leases_buildings": true },
          "not_sure": { "owns_buildings": "unknown", "leases_buildings": "unknown" }
        }
      }
    ],
    "rules": [
      {
        "sets": "uses_buildings",
        "value": true,
        "source": "general",
        "when": { "any": [{ "owns_buildings": true }, { "leases_buildings": true }] }
      },
      {
        "sets": "scope_1_mobile_relevant",
        "value": "not_applicable",
        "source": "hotspot",
        "when": { "industries": [1, 3, 7] }
      }
    ],
    "action_conditions": {
      "action_key_1": {
        "include_when": { "cat_6_relevant": true, "travel_includes_flying": true },
        "exclude_when": {}
      },
      "action_key_2": {
        "include_when": { "uses_buildings": true, "size": [3, 4, 5] },
        "exclude_when": { "remote_only": true }
      }
    }
  },
  "test_cases": [
    {
      "name": "Small advertising agency",
      "input_facts": { "size": 2, "industries": [1], "owns_buildings": true },
      "expected_actions": ["action_key_1", "action_key_2"]
    }
  ]
}
```

## Data types in the blob

### Fact types
- `boolean_state` — values: `true`, `false`, `unknown`, `not_applicable`
- `enum` — single value from a reference values group (by ID)
- `array` — multiple values from a reference values group (by ID)

`values_ref` on a fact points to a `group_key` in the reference values table.

### Question types
- `boolean_state` — yes/no/not sure, sets one fact via `fact` key
- `single-select` — pick one from `options_ref` group, sets one fact via `fact` key
- `multi-select` — pick many from `options_ref` group, sets one array fact via `fact` key
- `checkbox-radio-hybrid` — inline `options` with `exclusive` flags, sets multiple facts via `facts` mapping

### Rule condition shapes
Rules are ordered — earlier rules take priority. Hotspot rules come before general rules.

```json
{ "remote_only": true }
{ "industries": [1, 3, 7] }
{ "any": [{ "owns_buildings": true }, { "leases_buildings": true }] }
```

New shapes may be added over time.

### Action conditions
Each action key maps to `include_when` (conditions that must be met) and `exclude_when` (conditions that make the action irrelevant). Same condition shapes as rules.

### show_when / hide_when
Questions can have `show_when` (only display when condition met) and `hide_when` (suppress when condition met). Same condition shapes as rules. `hide_when` takes priority over `show_when`.

## Admin workflow

1. Admin clicks "Start new version" — API creates a draft copied from live
2. FE loads the blob into local state
3. Admin edits facts/questions/rules/action conditions in the UI
4. Work-in-progress auto-saves to localStorage
5. Admin can save the draft to the API at any point (validated on save)
6. Admin picks a company and previews the effects of their changes
7. Admin runs the test suite — sees pass/fail/diffs
8. Admin updates test expectations for deliberate changes
9. Admin clicks "Go live" — draft becomes the new live dataset (must pass validation)
10. Previous live dataset is archived (available for rollback)

## Reference values

Loaded separately from the blob. Each value has:

```json
{
  "id": 1,
  "group_key": "industry",
  "name": "Advertising",
  "description": null,
  "position": 0
}
```

Group keys include: `industry`, `business_size`, `building_type`, `supply_chain_challenge`, `measures_emissions`, `reduction_targets`.

The blob references these by `id` (in rule conditions, action conditions) and by `group_key` (in fact `values_ref` and question `options_ref`).

Soft-deleted values are hidden from new selections but still resolve by ID for existing data.
