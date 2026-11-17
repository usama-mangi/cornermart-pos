# SRS: CornerMart POS

- Version: 0.1
- Date: 2026-11-17
- Based on: 00-vision.md

## 1. Introduction
- Purpose: Define what CornerMart POS shall do.
- Scope: Stock, Inventory, Online order, Order status, Order tracking
- Definitions: see 02-glossary.md

## 2. Actors
| ID | Actor | Description |
| -- | ----- | ----------- |
| A1 | Cashier | In-store seller |
| A2 | Stock manager | Receives/counts/adjusts stock |
| A3 | Customer | Online buyer |
| A4 | Admin | Owner; users, prices |

## 3. Functional requirements
| ID | Priority (MoSCoW) | Statement ("The system shall...") | Source (Goal/Actor) |
| -- | ----------------- | --------------------------------- | ------------------- |
| FR-STK-01 | Must | System shall maintain product catalog (SKU, name, price, UoM, active flag). | A4 |
| FR-STK-02 | Must | System shall show on-hand, reserved, available (= on-hand - reserved) per product. | G1 |
| FR-INV-01 | Must | System shall record every stock change as an immutable ledger movement (type, qty, ref, user, timestamp). | G2 |
| FR-INV-02 | Must | System shall support receive, sale, adjustment, return movements. | A2 |
| FR-INV-03 | Should | System shall support cycle count producing adjustment movements for variance. | G2 |
| FR-INV-04 | Should | System shall alert when available <= reorder point. | A2 |
| FR-ORD-01 | Must | System shall let customer place order >=1 line from available stock. | A3 |
| FR-ORD-02 | Must | System shall reserve stock automatically at order placement. | G1 |
| FR-ORD-03 | Must | System shall release reservation on cancel or expiry. | G1 |
| FR-ORD-04 | Must | System shall complete in-store sale and deduct stock in one transaction. | A1 |
| FR-STS-01 | Must | System shall enforce order state transitions (#7) | G3 |
| FR-STS-02 | Must | System shall store every status change with timestamp and user. | G3 |
| FR-TRK-01 | Must | System shall view current status and history by order number + email/phone. | G3 |
| FR-TRK-02 | Could | System shall email customer on status change. | G3 |
| FR-SEC-01 | Must | System shall restrict features by role. | A4 |

## 4. User stories + acceptance criteria
### US-01 Prevent oversell
As a customer, I want only available products orderable, so that my order is not cancelled later.
Traces: FR-ORD-01, FR-ORD-02

```gherkin
Scenario: Last unit, two simultaneous order
	Given product "Sugar Bag 250g" has available quantity 1
	When two customers place an order for 1 unit at the same time
	Then exactly one order is confirmed
	And the other is rejected with "Insufficient stock"
	And available quantity is 0
```

### US-02 Cancel releases stock
As a customer, I want to cancel a placed order, so that I am not charged for it.
Traces: FR-ORD-03, FR-STS-01

```gherkin
Scenario: Cancel before packing
	Given order #1001 is in status "Placed" with 2 units reserved
	When the customer cancels the order
	Then status becomes "Cancelled"
	And the 2 units are released to available stock
```

### US-03 Receive stock
As a stock manager, I want to receive goods, so that on-hand is correct.
Traces: FR-INV-01, FR-INV-02

```gherkin
Scenario: Receive goods
	Given "Sugar Bag 250g" on-hand is 10
	When stock manager receives 20 units
	Then on-hand is 30
	And a ledger movement "RECEIPT +20" exists with user and timestamp.
```

### US-04 Track order
As a customer, I want to see my order status, history, so that I know when it is ready.
Traces: FR-TRK-01, FR-STS-02

```gherkin
Scenario: View tracking
	Given order #1001 changed Placed -> Paid -> Packed
	When customer opens tracking with order number and email
	Then the 3 statuses are shown with timestamps
	And the current status is "Packed"
```

### US-05 Invalid transition blocked
As an admin, I want illegal status jumps blocked, so that data stays consistent.
Traces: FR-STS-01

```gherkin
Scenario: Skip states
	Given order #1001 is "Placed"
	When a user sets status to "Completed"
	Then the change is rejected
```

## 5. Non-functional requirements
Format: quality attribute scenario (Source, Stimulus, Environment, Response, Measure)
| ID | Attribute (ISO 25010) | Scenario | Measure |
| -- | --------------------- | -------- | ------- |
| NFR-01 | Reliability (consistency) | 50 concurrent orders for stock of 10, normal load | Confirmed units <= 10; 0 negative available |
| NFR-02 | Performance efficiency | Customer opens tracking page, 200 orders/day load | p95 <= 2s |
| NFR-03 | Performance efficiency | Status change visible to customer | <= 5 s |
| NFR-04 | Security | Unauthenticated user calls internal page/API | Denied 100%; customer sees only own orders |
| NFR-05 | Auditability | Any stock change | Traceable to user + time + reason; ledger rows never updated/deleted |
| NFR-06 | Recoverability | DB failure | RPO <= 15 min, RTO <= 4 h |
| NFR-07 | Usability | New cashier, 30 min training | Completes sale <= 30 s |
| NFR-08 | Compatibility | Mobile browser (customer) | Works on latest Chrome/Safari/Firefox, 360 px width |

## 6. Business rules
| ID | Rule |
| -- | ---- |
| BR-01 | available = on_hand - reserved; never < 0. |
| BR-02 | Ledger rows are insert-only; corrections are new movements. |
| BR-03 | Reservation expires if unpaid after 30 min. |
| BR-04 | Only Placed/Paid orders may be cancelled. |
| BR-05 | Quantity > 0 on order lines; max 99 per line. |
| BR-06 | Price captured on order line at placement (not re-read later). |

## 7. Order state model
| From | Event | To | Guard |
| ---- | ----- | -- | ----- |
| (new) | place | Placed | stock reserved |
| Placed | pay | Paid | payment confirmed |
| Placed | cancel / expire | Cancelled | BR-03/04 |
| Paid | cancel | Cancelled | before Packed |
| Paid | pack | Packed | stock manager |
| Packed | mark ready | Ready |
| Ready | handover | Completed | stock deducted from on-hand, reservation consumed |

## 8. Out of scope
Accounting, multi-currency, carrier API, loyalty (Vision #4)

## 9. Traceability
| Goal | FR | US | NFR | Test |
| ---- | -- | -- | --- | ---- |
| G1 | FR-ORD-02, FR-STK-02 | US-01 | NFR-01 | T-001 (concurrency ) |
| G2 | FR-INV-01..03 | US-03 | NFR-05 | T-002 |
| G3 | FR-STS-01..02, FR-TRK-01 | US-04, US-05 | NFR-02, NFR-03 | T-003 |

## 10. Open questions
- Payment: cash on pickup or online gateway? (affects "Paid" state)
- Delivery in v1 or pickup only?
