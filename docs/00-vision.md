# Vision: CornerMart POS

- Version: 0.1
- Date: 2026-11-16
- Owner: Usama Mangi

## 1. Problem
Small grocery shop tracks stock in spreadsheets; counts drift and orders get accepted for items already sold in-store. Customers phone to ask where their order is.

## 2. Users / Roles
| Role | Description | Main need |
| ---- | ----------- | --------- |
| Cashier | Sells in-store | Fast checkout, correct price/stock |
| Stock manager | Receives, counts, adjusts stock | Accurate stock, low-stock alerts |
| Customer | Order online | See availability, track order |
| Admin | Owner | Users, prices, reports |

## 3. Goals (measurable)
- G1: Zero oversells (no order confirmed for unavailable stock).
- G2: Stock quantity = sum of ledger movements, 100% recnocilable.
- G3: Customer sees order status change within 5 s.

## 4. Non-goals
- NG1: Accounting/general ledger.
- NG2: Multi-currency.
- NG3: Courier/carrier API integration (status updated manually).
- NG4: Loyalty/promotions engine.

## 5. Scope v1
| Capability | One-line description |
| ---------- | -------------------- |
| Stock | Product catalog, price, on-hand quantity per location |
| Inventory | Receive, adjust, cycle count, reorder alerts; immutable movement ledger |
| Online order | Customer places order; stock reserved automatically. |
| Order status | Lifecycle: Placed -> Paid -> Packed -> Ready/Dispatched -> Completed/Cancelled. |
| Order tracking | Customer views status history by order number. |

## 6. Constraints
- Platform: Oracle APEX + Oracle DB (ADR-0002)
- Team: 1 developer.
- Deadline: 1 week.
- Budget: Oracle Cloud free tier / APEX service.

## 7. Assumptions and risks
| # | Type | Statement | Mitigation |
| - | ---- | --------- | ---------- |
| 1 | Assumption | Single store, <=2,000 SKUs, <=200 orders/day | Revisit if exceeded. |
| 2 | Risk | Concurrent orders oversell last unit | Row locking, reservation ledger, load test. |
| 3 | Scope creep (payments, delivery) | Non-goals list, ADR for changes. |

### 8. Success metrics
| Metric | Target | How measured |
| ------ | ------ | ------------ |
| Oversell incidents | 0 | Concurrency test + prod audit query |
| Stock reconciliation variance | 0 after cycle count | Ledger sum vs on-hand report |
| Status propagation delay | <= 5 s | Timestamp diff: status change vs customer view |
| Checkout time (in-store) | <=30 s/transaction | Manual timing in UAT |
