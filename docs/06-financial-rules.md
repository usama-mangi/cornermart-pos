# Financial Rules: CornerMart POS

- Version: 0.1
- Date: 2026-11-17
- Refs: SRS BR-06; Domain #4 Payment; Order spec #5

## 1. Money representation
- `NUMBER(12, 2)` amounts + `currency CHAR(3)` (ISO 4217, v1 fixed `PKR`). Never FLOAT / BINARY_DOUBLE.
- Unit price and cost: `NUMBER(12, 4)` (cost from WAC needs precision).
- Currency column on order, payment, refund; no cross-currency math (NG2).
- Arithmetic only in PL/SQL package `money_api`; no ad-hoc ROUND in UI/SQL.

## 2. Rounding
- Mode: half-up (Oracle `ROUND`) to 2 dp.
- Level: tax rounded per line; line totals summed; no rounding on the sum.
- Cash rounding (if no small coins): at payment only, difference stored as `rounding_adj` line.

## 3. Tax
- Model: tax-inclusive shelf prices (retail norm); tax-exclusive stored internally.
- `tax_rate` table: code, rate %, valid_from, valid_to (effective dated). Product -> tax code.
- Rate captured on order line at placement (like price, BR-06).
- Inclusive formula: net = ROUND(gross / (1 + rate), 2); tax = gross - net.
- Tax exempt products: rate 0, code `EXEMPT`.

## 4. Discounts
- v1: manual line discount (amount or %) by Admin/Cashier with limit; no promo engine (NG4).
- Applied to gross line price before tax calc.
- Stored: `discount_amount` per line, `discount_reason`, `approved_by`.
- Max cashier discount 10%; above needs Admin.

## 5. Order total calculation
1. line_gross = qty x unit_price (tax-inclusive)
2. line_gross_after_disc = line_gross - discount_amount
3. line_net = ROUND(line_gross_after_disc / (1 + rate), 2)
4. line_tax = line_gross_after_disc - line_net
5. order_total = SUM(line_gross_after_disc) (+ delivery fee if any, v1 none)
6. order_tax = SUM(line_tax)

Example: 3 x "Sugar Bag 250g" @ 300, rate 10%, discount 20.00
- gross 900.00 -> after disc 880.00 -> net ROUND(880/1.1, 2)=800.00 -> tax 80.00
- total 880.00

Invariant: toatl = SUM(net) + SUM(tax). Verified by constraint/test.

## 6. Payments
- Methods: CASH (pickup/in-store), CARD (in-store terminal, external), ONLINE (gateway, TBD).
- Payment States: PENDING -> CONFIRMED | FAILED; CONFIRMED -> REFUNDED (partial/full).
- Online flow: create PENDING payment (idem_key) -> redirect to gateway -> webhook -> verify signature -> CONFIRMED -> `ordering_api.transaction(pay)`.
- Webhook: verify signature, check amount = order total, dedupe by gateway event id, respond 200 fast, process idempotently.
- Pay-at-pickup alternative: payment created at handover; order stays PLACED->READY; expiry rule changes (see Open questions).
- Payment amount must equal order total (no partial payment v1).

## 7. Refunds / returns
- Refund <= confirmed amount - already refunded.
- Full refund on cancel of PAID order (automatic request, staff confirms).
- Return (goods) after COMPLETED: Cashier records RETURN + refund; window 7 days with order_no.
- Refund is a new row (`refund`), never edits payment. Insert-only.
- Return restock: RETURN movement if resellable, else ADJUSTMENT DAMAGE.
- Refund to original method only.

## 8. Reconciliation
- Daily job: SUM(payment CONFIRMED) - SUM(refund) per method vs. cash drawer / terminal / gateway report.
- Cashier shift close: expected cash vs counted; variance logged.
- Order check: every COMPLETED order has CONFIRMED payment >= toatl (or cash at handover).
- Gateway settlement file matched by gateway reference; unmatched -> alert.

## 9. PCI DSS scope
- Goal: SAQ A (smallest scope): card data never touches servers.
- Online: hosted payment page/redirect from gateway; store only token, last4, brand, gateway ref.
- Never store PAN, CVV, expiry, magnetic data. Never log full payloads with card details.
- In-store card: standalone terminal, no integration; store only approval ref.
- TLS everywhere; gateway keys in APEX Web Credentials, not in code.

## 10. Open questions
- Which gateway (availability in Pakistan)? Pay at pickup first?
- Tax rate(s) and invoicing legal requirements (e.g. FBR/PRA POS integration)? Receipt format?
- Cash rounding needed?
