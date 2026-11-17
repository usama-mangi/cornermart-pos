# ADR-0002: Oracle APEX as Platform

- Status: Accepted
- Date: 2026-11-16

## Context
Need POS with stock, orders, tracking. Small team, fast delivery, strong transactional integrity (anti-oversell).

## Decision
Build on Oracle APEX + Oracle Database; business logic in PL/SQL packages (thick DB); REST via ORDS.

## Alternatives considered
- Spring Boot + React: more flexible, slower to build, more infra
- Low-code other (Power Apps): weaker DB-level concurrency control

## Consequences
- Good: rapid UI, ACID locking in DB, logic reusable by UI and REST
- Bad: Oracle licensing/hosting, PL/SQL skill dependency, less UI freedom
