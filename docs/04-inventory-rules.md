# Inventory Rules: CornerMart POS

- Version: 0.1
- Date: 2026-11-17
- Refs: SRS FR-INV-01..04, BR-01, BR-02; Domain #4

## 1. Ledger design
- Table `stock_movement`: id, product_id, location_id, type, qty (signed), unit_cost, ref_type, ref_id, reason, created_by, created_at.
- Insert-only: no UPDATE/DELETE grants; trigger raises error on both; corrections = reversing movements.
- `stock_level` (product, location, qty_on_hand, qty_reserved, version) = cached projection, updated in same transaction as movement insert.
- Nightly reconciliation: `stock_level.qty_on_hand = SUM(stock_movement.qty)`; mismatch -> alert.

## 2. Movement rules
| Type | Sign | Allowed by | Required | Rule |
| ---- | ---- | ---------- | -------- | ---- |
| RECEIPT | + | Stock manager | supplier ref, unit_cost | qty > 0 |
| SALE | - | System (checkout/handover) | order/sale ref | consumes reservation if online; qty <= on_hand |
| ADJUSTMENT | +- | Stock manager | reason code | reason ∈ {DAMAGE, LOSS, EXPIRED, COUNT, OTHER}; large qty needs Admin approval |
| RETURN | + | Cashier | sale ref | restock only if resellable, else ADJUSTMENT |
| TRANSER_OUT/IN | -/+ | Stock manager | pair ref | both rows in one transaction |

 ## 3. Reservation / ATP
 - available = on_hand - reserved.
 - Algorithm (in one DB transaction, lines sorted by product_id to avoid deadlock):
 	1. `SELECT ... FROM stock_level WHERE product_id=:p AND location_id=:l FOR UPDATE`
 	2. If on_hand -reserved < qty -> raise ReservationRejected.
 	3. Insert reservation (ACTIVE, expires_at = now + 30 min); reserved += qty.
 	4. Any line fails -> rollback entire order.
 - Release: status RELEASEd, reserved -= qty.
 - Consume: on handover, status CONSUMED, insert SALE movement, on_hand -= qty, reserved -= qty.
 - Expiry: DBMS_SCHEDULER job every 1 min releases expired ACTIVE reservations and cancels updaid orders. Idempotent (re-run safe).
 - In-store sale: no reservation; lock now, check on_hand >= qty, SALE movement directly.
 - Concurrency: pessimistic row lock (FOR UPDATE). Lock held for transaction only. Use NOWAIT/WAIT 5 for fail-fast.

 ## 4. Costing
 - Method v1: Weighted Average Cost (WAC) per product per location.
 - Formula on RECEIPT: new_avg = (on_hand x old_avg + qty x unit_cost) / (on_hand + qty).
 - SALE/ADJUSTMENT uses current avg, avg unchanged.
 - Stored: `unit_cost` on every movement (frozen at time).
 - FIFO deferred; ADR-0005 if expiry/lots needed.

 ## 5. Replenishment
 - Reorder point = avg_daily_demand x lead_time_days + safety_stock.
 - Safety stock = z x σ_daily_demand x √lead_time_days (z=1.65 for 95% service).
 - Demand from SALE movements, last 90 days.
 - Review: nightly job; sets low-stock flag when available <= reorder_point.
 - v1 fallback: manual reorder_point per product.

 ## 6. Cycle count
 1. Stock manager open count for a product set (snapshot system qty).
 2. Enters counted qty per line.
 3. System computes variance = counted - snapshot_adjusted_for_movement_since.
 4. |variance value| <= threshold -> auto ADJUSTMENT (reason COUNT); above -> Admin approval.
 5. Count closed, immutable.
 - Frequency: ABC (A weekly, B monthly, C quarterly).

 ## 7. Classification
 - ABC by annual sales value (last 12 months): A = top 80% value, B = next 15%, C = last 5%. Recomputed monthly.

 ## 8. Edge-case policies
 | Case | Policy |
 | ---- | ------ |
 | Negative stock | Forbidden. Reject movement that makes on_hand < 0 |
 | Sale while count open | Allowed; variance compensates movements since snapshot |
 | Expiry/lots | Out of v1. Grocery risk: log as risk, ADR later (FEFO) |
 | Partial fulfilment | Not supported; whole order or none |
 | UoM fractional (kg) | qty NUMBER(12, 3); each = integer |
 | Price change after order | No effect (BR-06) |
 | Duplicate request (retry) | Idempotency key on movement ref; unique constraint |
 | Deleted product | Soft delete only (active = N) |

 ## 9. Open questions
 - Perishables (molesis, dehydrated food): need lots/expiry in v1?
 - Multi-location in v1 or single `MAIN`?
