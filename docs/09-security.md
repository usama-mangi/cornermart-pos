# Security Spec: CornerMart POS

- Version: 0.1
- Date: 2026-11-18
- Refs: NFR-04, NFR-05; Architecure #8; Financial #9
- Standard: OWASP ASVS Level 1 baseline, Level 2 for auth, payment audit

## 1. Assets and threats
| Asset | Threat | Impact |
| ----- | ------ | ------ |
| Stock ledger | Staff tampering / fraud | Loss, wrong stock |
| Orders / PII | Data leak, enumeration of order_no | Privacy breach |
| Payment webhook | Forged callback marks order PAID | Free goods |
| Staff accounts | Weak password, shared login | Unauthorized changes |
| Prices / discounts | Unauthorized edit | Revenue loss |
| Storefront | Bots reserving all stock (reservation DoS) | Lost sales |
| Gateway keys | Leak in code/logs | Financial fraud |
| APEX app | SQL injection, XSS, broken access (IDOR) | Full compromise |

## 2. Roles
| Role | Description | Auth |
| ---- | ----------- | ---- |
| GUEST | Anonymous storefront user | None (order_no + email for tracking |
| CUSTOMER | Registered buyer (if account adopted) | APEX auth / social SSO |
| CASHIER | In-store | APEX account |
| STOCK MANAGER | Inventory ops | APEX account |
| ADMIN | Owner | APEX account + MFA |
| SYSTEM | Scheduler/webhook | DB job / signature |

## 3. Permission matrix
| Function | Guest | Customer | Cashier | Stock manager | Admin |
| -------- | ----- | -------- | ------- | ------------- | ----- |
| Browse products | ✓ | ✓ | ✓ | ✓ | ✓ |
| Place order | ✓ | ✓ | | | |
| Track own order | ✓ | ✓ | | | |
| Cancel own PLACED order | ✓ | ✓ | | | |
| In-store sale | | | ✓ | | ✓ |
| Handover order | | | ✓ | | ✓ |
| Pack / mark ready | | | ✓ | ✓ |
| Receive / adjust stock | | | ✓ | ✓ |
| Large adjustment approval | | | | | ✓ |
| Cycle count submit | | | | ✓ | ✓ |
| Cycle count approve | | | | | ✓ |
| Discount <= 10% | | | | ✓ | ✓ |
| Discount >= 10% | | | | | ✓ |
| Refund / return | | | ✓ (<= limit) | | ✓ |
| Change price / products | | | | | ✓ |
| Manage users | | | | | ✓ |
| View cost / margin | | | | ✓ | ✓ |
| View audit logs | | | | | ✓ |

Segregation of duties: person who submits a count/adjustment above threshold cannot approve it.

## 4. Authentication
- Back office (app 200): APEX built-in accounts v1; password min 12 chars, lockout after 5 failures, session idle timeout 15 min, max 8 h. Admin MFA (TOTP) or OIDC SSO later (ADR).
- Storefront (app 100): public; no login for guest; if customer accounts: email verification.
- No shared accounts; each staff member own login.
- Webhook: HMAC signature + timestamp tolerance (replay window 5 min) + event id dedupe.
- Secrets: APEX Web Credentials; never in code/Git.

## 5. Authorization implementation
- Deny by default. Every back-office page and process has an APEX authorization scheme calling `security_api.has_role(...)`.
- Server-side enforcement in DB APIs too (`ordering_api.transition` checks actor role vs command). UI hiding is not security.
- Schemas: `POS_APP` has EXECUTE on APIs only, no table privileges (Data #6).
- Row-level:
	- Customer/guest reads only through `v_order_tracking`, filtered by order_no + email match.
	- VPD/RLS policy on `sales_order` for CUSTOMER role (customer_id = session user) as defense in depth. Staff bypass via role context.
- IDOR prevention: all lookups verify ownership; non-sequential order_no; generic "Order not found".
- Principle of least privilege for DB users, ORDS, scheduler jobs.

 ## 6. Data protection
- Transit: TLS 1.2+ end to end, HSTS.
- At rest: Oracle TDE (default in Autonomous DB); backups encrypted.
- Passwords: APEX hashed (never stored plain); handover code stored as hash (Data #3).
- PII: name, email, phone only. Mask phone/email in staff lists except where needed. No PII in logs.
- Card data: none stored (Financial #9).
- Cost/margin columns hidden from CASHIER via views.

## 7. Application security controls
- SQL injection: bind variables only; no dynamic SQL with concatenation; use `DBMS_ASSERT` where dynamic unavoidable.
- XSS: APEX output escaping on all items/columns (escape special characters); no unescaped HTML from users.