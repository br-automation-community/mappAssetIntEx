---
description: Comprehensive code review comparing the current branch against the default branch (origin/main).
argument-hint: "Optional: specify focus areas or files to review"
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

Perform a complete code review on the current branch compared to origin/main (or the default branch).

$ARGUMENTS

Focus on the following categories:

## Security & Vulnerabilities

- OWASP Top 10 vulnerabilities
- Data leakage risks
- Insecure dependencies or imports
- Improper error handling that could expose sensitive information
- Path traversal, injection, or unsafe deserialization

## Performance & Efficiency

- O(n²) or worse algorithms in hot paths
- Unnecessary object allocations or memory leaks
- Blocking I/O operations
- Missing caching opportunities

## Maintainability & Code Quality

- DRY (Don't Repeat Yourself) violations
- SOLID principle adherence
- Function/variable naming clarity
- Component modularity and separation of concerns
- Dead code or unused variables

## Correctness & Edge Cases

- Off-by-one errors
- Null/undefined access risks
- Race conditions
- Improper state management
- Missing input validation

## Testing Coverage & Quality

- Missing or inadequate test cases for new code
- Tests that don't validate edge cases

## Documentation & Communication

- Missing or outdated comments
- Lack of inline comments for complex logic
- README or documentation not updated for new features

## Configuration & Secrets Management

- Hardcoded configuration values
- Secrets or API keys in code (even if commented)

## Breaking Changes & Compatibility

- Potential breaking changes in public APIs
- Backward compatibility issues

## Code Style & Conventions

- Inconsistency with project style guidelines (see CLAUDE.md and `.github/instructions/`)
- Naming convention violations (see as-project-code.instructions.md)

## Positive Patterns Section

- Explicitly call out well-implemented features
- Highlight clever solutions or good architectural decisions
- Reinforce good practices for encouragement

## Guidelines

- **Do not hallucinate issues.** Only report high-confidence findings.
- If the code is simple and safe, it is acceptable to return nothing or a positive insight.
- Organize findings by severity (High, Medium, Low).
- Provide specific file locations and line numbers for each issue.
- Include code snippets and recommended fixes where applicable.
- Summarize findings in a table at the end.
