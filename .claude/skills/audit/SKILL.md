---
name: audit
description: Audit the codebase for violations of CLAUDE.md patterns and common mistakes. Use when checking code quality or preparing for code review.
disable-model-invocation: true
context: fork
agent: Explore
---

# Codebase Audit

Audit this codebase for pattern violations and common mistakes.

## Audit Scope

If arguments are provided ($ARGUMENTS), audit only those specific files or directories. Otherwise, audit the entire codebase.

## Step 1: Read CLAUDE.md

First, read the CLAUDE.md file to understand all the coding standards and patterns for this project. Then systematically check each guideline is being followed throughout the codebase.

## Step 2: Check Common Mistakes

In addition to CLAUDE.md violations, specifically check for these frequent issues:

- **Hardcoded Locales**: Search for hardcoded locale strings like `"en"`, `"de"`, `"es"`, `:en`, `:de`, etc. in application code. These should typically use `I18n.locale` or be configurable.
- **User Data Access Pattern**: Search for `user.data.` read patterns (not updates). Per CLAUDE.md, you should use `user.some_method` not `user.data.some_method` for reading because User delegates via `method_missing`. Updates via `user.data.update!(...)` are acceptable. The only exception for reads is when there's a name clash (e.g., `user.data.id`).
- **Duplicate Tests**: Look for test methods that test the same functionality or have very similar assertions. Also check for copy-pasted test code that should be extracted into helpers.
- **Command Test Scope**: Command tests should only test functionality within that command. Sub-commands should be mocked rather than having their internals tested. Look for command tests that assert on behavior belonging to other commands.
- **Controller Test Assertions**: Controller tests should use `assert_json_response` with serializers, not manually check individual hash keys. Look for patterns like `json_response[:key]` or `response.parsed_body["key"]` assertions instead of full response comparisons.
- **Repeated duplicate setup in tests**: Could we use factory traits instead or creating then updating records?

## Output Format

Only include sections that have findings. Do not include "no issues found" or similar filler content.

```
## CLAUDE.md Violations
...

## Common Mistakes
...
```

End with a brief summary of total violations and prioritized recommendations.
