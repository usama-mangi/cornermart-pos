# ADR-0001: Record Architecture Decisions

- Status: Proposed
- Date: 2026-11-16

## Context
Architecture decisions get forgotten. Need lightweight, versioned record.

## Decision
Record each significant decisions as MADR file docs/adr, numbered sequentially, stored in Git.

## Alternatives considered
- Wiki: drifts from code, no review history
- No records: rationale lost

## Consequences
- Good: rationale traceable, reviewable in PRs
- Bad: small writing overhead per decision
- Rule: ADRs immutable; change by superseding
