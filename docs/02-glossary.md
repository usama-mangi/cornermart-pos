# Glossary: CornerMart POS

- Version: 0.1
- Date: 2026-11-17

Rules:
- One term = one meaning. No synonyms in code, DB, UI, docs.
- Use the term exactly as written here in table/column/package names.
- Mark banned synonyms.

## 1. Terms
| Term | Definition | Context | Avoid (synonyms) | Code name |
| ---- | ---------- | ------- | ---------------- | --------- |
| Product | Sellable item definition (what), not its quantity | Catalog | Item, Article | `product` |
| SKU | Unique business code of a product | Catalog | Barcode (different thing), Code | `sku` |
| Barcode | Scannable code mapped to a SKU; many per SKU possible | Checkout | SKU | `product_barcode` |
| UoM | Unit of measure (each, kg, litre) | Catalog | Unit | `uom` |
| Location | Place where stock is held (shop floor, backroom) | Inventory | Warehouse, Store | `location` |
| Stock level | Quantity of one product at one location | Inventory (ambiguous) | `stock_level` |
| Inventory | The activity/process of managing stock (receive, count, adjust) | Process | Stock (as process) | n/a (module name) |
| Stock movement | Immutable ledger row recording one change of quantity | Inventory | Transaction, Stock entry | `stock_movement` |
| Reservation | Quantity held for an order, not yet sold | Order | Hold, Allocation | `stock_reservation` |
| Receipt | Goods arriving from supplier | Inventory | Purchase, Goods in | `RECEIPT` (movement) |
| Adjustment | Manual correction (damage, loss, count variance) | Inventory | Write-off, Correction | `ADJUSTMENT` |
| Cycle count | Counting a subset of stock and comparing to system | Inventory | Stocktake, Audit | `cycle_count` |
| Reorder point | Available level that triggers a low-stock alert | Inventory | Min stock | `reorder_point` |
| Customer | Person placing an online order | Order | User, Client, Buyer | `customer` |
| User | Staff member with login (cashier, stock manager, admin) | Security | Employee | `app_user` |
| Order | Customer's request to buy products, online | Order | Sale (in-store), Purchase | `sales_order` |
| Order line | One product + quantity + price on an order | Order | Item, Detail | `sales_order_line` |
| Sale | Completed in-store checkout, paid immediately | POS | Order (online) | `pos_sale` |
| Order number | Human-readable unique order identifier | Tracking | Order ID (internal PK) | `order_no` |
| Status history | Append-only log of order status changes | Tracking | Audit, Log | `order_status_history` |
| Fulfilment | Packing and handing over an order | Order | Shipping, Delivery (v1: pickup only) | `fulfilment` |
| Pickup | Customer collects order in store | Order | Collection | `PICKUP` (movement) |
| Payment | Money received for an order or sale | Finance | Transaction (ambiguous) | `payment` |
| Refund | Money returned to customer | Finance | Reversal | `refund` |
| Return | Godos coming back from customer | Inventory | Refund (money only) | `RETURN` (movement) |

## 2. Quantities (stock)
| Term | Definition / formula | Code name |
| ---- | -------------------- | --------- |
| On-hand | Physical quantity = SUM(stock_movement.qty) | `qty_on_hand` |
| Reserved | SUM(active reservations) | `qty_reserved` |
| Available | on-hand - reserved (ATP). Never < 0 | `qty_available` |

## 3. Statuses
| Entity | Status | Meaning |
| ------ | ------ | ------- |
| Order | PLACED | Created, stock reserved, unpaid |
| Order | PAID | Payment confirmed |
| Order | PACKED | Items picked and packed |
| Order | READY | Awaiting pickup |
| Order | COMPLETED | Handed over; stock deducted |
| Order | CANCELLED | Cancelled or expired; reservation released |
| Reservation | ACTIVE | Holding stock |
| Reservation | CONSUMED | Converted to sale movement |
| Reservation | RELEASED | Freed (cancel/expiry) |

## 4. Movement types
| Type | Sign | Meaning |
| ---- | ---- | ------- |
| RECEIPT | + | Supplier delivery |
| SALE | - | Completed order/sale |
| ADJUSTMENT | +- | Manual/count correction |
| RETURN | + | Customer return restocked |
| TRANSFER_OUT / TRANSFER_IN | - / + | Between locations (v1 optional) |

## 5. Acronyms
| Acronym | Expansion |
| ------- | --------- |
| SRS | Software Requirements Specification |
| ATP | Available to Promise |
| ADR | Architecture Decision Record |
| UoM | Unit of Measure |
| SKU | Stock Keeping Unit |
| POS | Point of Sale |
| ORDS | Oracle REST Data Service |
