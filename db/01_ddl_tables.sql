-- =====================================================================
-- CornerMart POS: DDL v0.2
-- Target: Oracle 19c+ (parsing/data schema POS_DATA)
-- Conventions: Data Design §1 + PM rules
--   PM1: attribute1..attribute10 (VARCHAR2(240)) flex columns, only on tables
--        expected to gain attributes: product, customer, supplier, employee,
--        location, sales_order, sales_order_line
--   PM2/5: EMPLOYEE + SUPPLIER roles (app_role, employee, supplier ...)
--   PM3: WHO columns on every table (trigger-populated)
--   PM4: explicit indexes only on transactional / >1000-row tables
--        (PK/UK implicit indexes still exist)
-- Run order: tables -> indexes -> triggers -> seed
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. REFERENCE / SECURITY TABLES
-- ---------------------------------------------------------------------
CREATE TABLE app_role (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  code             VARCHAR2(30)  NOT NULL,
  name             VARCHAR2(100) NOT NULL,
  description      VARCHAR2(400),
  active           CHAR(1) DEFAULT 'Y' NOT NULL,
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_app_role PRIMARY KEY (id),
  CONSTRAINT uk_app_role_code UNIQUE (code),
  CONSTRAINT ck_app_role_active CHECK (active IN ('Y','N'))
);

CREATE TABLE app_config (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  config_key       VARCHAR2(60)  NOT NULL,
  config_value     VARCHAR2(500) NOT NULL,
  description      VARCHAR2(400),
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_app_config PRIMARY KEY (id),
  CONSTRAINT uk_app_config_key UNIQUE (config_key)
);

CREATE TABLE location (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  code             VARCHAR2(20)  NOT NULL,
  name             VARCHAR2(100) NOT NULL,
  active           CHAR(1) DEFAULT 'Y' NOT NULL,
  attribute1        VARCHAR2(240),
  attribute2        VARCHAR2(240),
  attribute3        VARCHAR2(240),
  attribute4        VARCHAR2(240),
  attribute5        VARCHAR2(240),
  attribute6        VARCHAR2(240),
  attribute7        VARCHAR2(240),
  attribute8        VARCHAR2(240),
  attribute9        VARCHAR2(240),
  attribute10       VARCHAR2(240),
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_location PRIMARY KEY (id),
  CONSTRAINT uk_location_code UNIQUE (code),
  CONSTRAINT ck_location_active CHECK (active IN ('Y','N'))
);

CREATE TABLE tax_rate (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  code             VARCHAR2(20) NOT NULL,
  rate_pct         NUMBER(5,2)  NOT NULL,
  valid_from       DATE NOT NULL,
  valid_to         DATE,
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_tax_rate PRIMARY KEY (id),
  CONSTRAINT uk_tax_rate_code_from UNIQUE (code, valid_from),
  CONSTRAINT ck_tax_rate_pct CHECK (rate_pct BETWEEN 0 AND 100),
  CONSTRAINT ck_tax_rate_valid CHECK (valid_to IS NULL OR valid_to > valid_from)
);

CREATE TABLE supplier (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  code             VARCHAR2(30)  NOT NULL,
  name             VARCHAR2(200) NOT NULL,
  contact_name     VARCHAR2(200),
  email            VARCHAR2(254),
  phone            VARCHAR2(30),
  active           CHAR(1) DEFAULT 'Y' NOT NULL,
  attribute1        VARCHAR2(240),
  attribute2        VARCHAR2(240),
  attribute3        VARCHAR2(240),
  attribute4        VARCHAR2(240),
  attribute5        VARCHAR2(240),
  attribute6        VARCHAR2(240),
  attribute7        VARCHAR2(240),
  attribute8        VARCHAR2(240),
  attribute9        VARCHAR2(240),
  attribute10       VARCHAR2(240),
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_supplier PRIMARY KEY (id),
  CONSTRAINT uk_supplier_code UNIQUE (code),
  CONSTRAINT ck_supplier_active CHECK (active IN ('Y','N'))
);

CREATE TABLE app_user (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  username         VARCHAR2(128) NOT NULL,
  display_name     VARCHAR2(200) NOT NULL,
  email            VARCHAR2(254),
  supplier_id      NUMBER,                    -- set only for SUPPLIER-role users
  active           CHAR(1) DEFAULT 'Y' NOT NULL,
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_app_user PRIMARY KEY (id),
  CONSTRAINT uk_app_user_username UNIQUE (username),
  CONSTRAINT fk_app_user_supplier FOREIGN KEY (supplier_id) REFERENCES supplier (id),
  CONSTRAINT ck_app_user_active CHECK (active IN ('Y','N'))
);

CREATE TABLE app_user_role (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  app_user_id      NUMBER NOT NULL,
  app_role_id      NUMBER NOT NULL,
  active           CHAR(1) DEFAULT 'Y' NOT NULL,
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_app_user_role PRIMARY KEY (id),
  CONSTRAINT uk_app_user_role UNIQUE (app_user_id, app_role_id),
  CONSTRAINT fk_app_user_role_user FOREIGN KEY (app_user_id) REFERENCES app_user (id),
  CONSTRAINT fk_app_user_role_role FOREIGN KEY (app_role_id) REFERENCES app_role (id),
  CONSTRAINT ck_app_user_role_active CHECK (active IN ('Y','N'))
);

CREATE TABLE employee (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  employee_no      VARCHAR2(30)  NOT NULL,
  app_user_id      NUMBER,
  full_name        VARCHAR2(200) NOT NULL,
  email            VARCHAR2(254),
  phone            VARCHAR2(30),
  job_title        VARCHAR2(100),
  hire_date        DATE,
  active           CHAR(1) DEFAULT 'Y' NOT NULL,
  attribute1        VARCHAR2(240),
  attribute2        VARCHAR2(240),
  attribute3        VARCHAR2(240),
  attribute4        VARCHAR2(240),
  attribute5        VARCHAR2(240),
  attribute6        VARCHAR2(240),
  attribute7        VARCHAR2(240),
  attribute8        VARCHAR2(240),
  attribute9        VARCHAR2(240),
  attribute10       VARCHAR2(240),
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_employee PRIMARY KEY (id),
  CONSTRAINT uk_employee_no UNIQUE (employee_no),
  CONSTRAINT uk_employee_user UNIQUE (app_user_id),
  CONSTRAINT fk_employee_user FOREIGN KEY (app_user_id) REFERENCES app_user (id),
  CONSTRAINT ck_employee_active CHECK (active IN ('Y','N'))
);

CREATE TABLE customer (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  app_user_id      NUMBER,                    -- null = guest-only customer
  name             VARCHAR2(200) NOT NULL,
  email            VARCHAR2(254),
  phone            VARCHAR2(30),
  anonymized_at    TIMESTAMP WITH TIME ZONE,
  active           CHAR(1) DEFAULT 'Y' NOT NULL,
  attribute1        VARCHAR2(240),
  attribute2        VARCHAR2(240),
  attribute3        VARCHAR2(240),
  attribute4        VARCHAR2(240),
  attribute5        VARCHAR2(240),
  attribute6        VARCHAR2(240),
  attribute7        VARCHAR2(240),
  attribute8        VARCHAR2(240),
  attribute9        VARCHAR2(240),
  attribute10       VARCHAR2(240),
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_customer PRIMARY KEY (id),
  CONSTRAINT uk_customer_user UNIQUE (app_user_id),
  CONSTRAINT fk_customer_user FOREIGN KEY (app_user_id) REFERENCES app_user (id),
  CONSTRAINT ck_customer_active CHECK (active IN ('Y','N'))
);

-- ---------------------------------------------------------------------
-- 2. CATALOG
-- ---------------------------------------------------------------------
CREATE TABLE product (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  sku              VARCHAR2(40)  NOT NULL,
  name             VARCHAR2(200) NOT NULL,
  uom              VARCHAR2(10)  NOT NULL,
  price            NUMBER(12,4)  NOT NULL,    -- tax-inclusive
  tax_rate_id      NUMBER NOT NULL,
  reorder_point    NUMBER(12,3),
  active           CHAR(1) DEFAULT 'Y' NOT NULL,
  attribute1        VARCHAR2(240),
  attribute2        VARCHAR2(240),
  attribute3        VARCHAR2(240),
  attribute4        VARCHAR2(240),
  attribute5        VARCHAR2(240),
  attribute6        VARCHAR2(240),
  attribute7        VARCHAR2(240),
  attribute8        VARCHAR2(240),
  attribute9        VARCHAR2(240),
  attribute10       VARCHAR2(240),
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_product PRIMARY KEY (id),
  CONSTRAINT uk_product_sku UNIQUE (sku),
  CONSTRAINT fk_product_tax_rate FOREIGN KEY (tax_rate_id) REFERENCES tax_rate (id),
  CONSTRAINT ck_product_price CHECK (price >= 0),
  CONSTRAINT ck_product_reorder CHECK (reorder_point IS NULL OR reorder_point >= 0),
  CONSTRAINT ck_product_active CHECK (active IN ('Y','N'))
);

CREATE TABLE product_barcode (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  product_id       NUMBER NOT NULL,
  barcode          VARCHAR2(60) NOT NULL,
  active           CHAR(1) DEFAULT 'Y' NOT NULL,
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_product_barcode PRIMARY KEY (id),
  CONSTRAINT uk_product_barcode UNIQUE (barcode),
  CONSTRAINT fk_product_barcode_product FOREIGN KEY (product_id) REFERENCES product (id),
  CONSTRAINT ck_product_barcode_active CHECK (active IN ('Y','N'))
);

CREATE TABLE product_supplier (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  product_id       NUMBER NOT NULL,
  supplier_id      NUMBER NOT NULL,
  supplier_sku     VARCHAR2(60),
  lead_time_days   NUMBER(4),
  active           CHAR(1) DEFAULT 'Y' NOT NULL,
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_product_supplier PRIMARY KEY (id),
  CONSTRAINT uk_product_supplier UNIQUE (product_id, supplier_id),
  CONSTRAINT fk_product_supplier_product FOREIGN KEY (product_id) REFERENCES product (id),
  CONSTRAINT fk_product_supplier_supplier FOREIGN KEY (supplier_id) REFERENCES supplier (id),
  CONSTRAINT ck_product_supplier_lead CHECK (lead_time_days IS NULL OR lead_time_days >= 0),
  CONSTRAINT ck_product_supplier_active CHECK (active IN ('Y','N'))
);

-- ---------------------------------------------------------------------
-- 3. INVENTORY
-- ---------------------------------------------------------------------
CREATE TABLE stock_level (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  product_id       NUMBER NOT NULL,
  location_id      NUMBER NOT NULL,
  qty_on_hand      NUMBER(12,3)  DEFAULT 0 NOT NULL,   -- projection of ledger
  qty_reserved     NUMBER(12,3)  DEFAULT 0 NOT NULL,   -- projection of ACTIVE reservations
  avg_cost         NUMBER(12,4)  DEFAULT 0 NOT NULL,   -- WAC
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_stock_level PRIMARY KEY (id),
  CONSTRAINT uk_stock_level_prod_loc UNIQUE (product_id, location_id),
  CONSTRAINT fk_stock_level_product FOREIGN KEY (product_id) REFERENCES product (id),
  CONSTRAINT fk_stock_level_location FOREIGN KEY (location_id) REFERENCES location (id),
  CONSTRAINT ck_stock_level_qty CHECK (qty_on_hand >= 0 AND qty_reserved >= 0 AND qty_reserved <= qty_on_hand),  -- BR-01
  CONSTRAINT ck_stock_level_cost CHECK (avg_cost >= 0)
);

-- insert-only ledger (BR-02). created_* = who/when of movement.
CREATE TABLE stock_movement (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  stock_level_id   NUMBER NOT NULL,
  type             VARCHAR2(20) NOT NULL,
  qty              NUMBER(12,3) NOT NULL,              -- signed
  unit_cost        NUMBER(12,4) NOT NULL,              -- frozen
  supplier_id      NUMBER,                             -- RECEIPT only
  ref_type         VARCHAR2(30),
  ref_id           NUMBER,
  reason           VARCHAR2(30),
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_stock_movement PRIMARY KEY (id),
  CONSTRAINT fk_stock_movement_level FOREIGN KEY (stock_level_id) REFERENCES stock_level (id),
  CONSTRAINT fk_stock_movement_supplier FOREIGN KEY (supplier_id) REFERENCES supplier (id),
  CONSTRAINT ck_stock_movement_type CHECK (type IN ('RECEIPT','SALE','ADJUSTMENT','RETURN','TRANSFER_OUT','TRANSFER_IN')),
  CONSTRAINT ck_stock_movement_sign CHECK (
       (type IN ('RECEIPT','RETURN','TRANSFER_IN') AND qty > 0)
    OR (type IN ('SALE','TRANSFER_OUT') AND qty < 0)
    OR (type = 'ADJUSTMENT' AND qty <> 0)),
  CONSTRAINT ck_stock_movement_cost CHECK (unit_cost >= 0),
  CONSTRAINT ck_stock_movement_reason CHECK (reason IS NULL OR reason IN ('DAMAGE','LOSS','EXPIRED','COUNT','OTHER')),
  CONSTRAINT ck_stock_movement_adj CHECK (type <> 'ADJUSTMENT' OR reason IS NOT NULL)
);

-- ---------------------------------------------------------------------
-- 4. ORDERING
-- ---------------------------------------------------------------------
CREATE TABLE sales_order (
  id                 NUMBER GENERATED ALWAYS AS IDENTITY,
  order_no           VARCHAR2(12)  NOT NULL,            -- public, non-sequential
  channel            VARCHAR2(10)  NOT NULL,
  customer_id        NUMBER,                            -- null for guest / POS walk-in
  location_id        NUMBER NOT NULL,
  contact_name       VARCHAR2(200),
  contact_email      VARCHAR2(254),
  contact_phone      VARCHAR2(30),
  status             VARCHAR2(12)  NOT NULL,            -- current-state projection
  currency           CHAR(3) DEFAULT 'PKR' NOT NULL,
  total              NUMBER(12,2) NOT NULL,
  tax_total          NUMBER(12,2) NOT NULL,
  rounding_adj       NUMBER(12,2) DEFAULT 0 NOT NULL,
  handover_code_hash VARCHAR2(64),
  idem_key           VARCHAR2(64) NOT NULL,
  expires_at         TIMESTAMP WITH TIME ZONE,
  attribute1        VARCHAR2(240),
  attribute2        VARCHAR2(240),
  attribute3        VARCHAR2(240),
  attribute4        VARCHAR2(240),
  attribute5        VARCHAR2(240),
  attribute6        VARCHAR2(240),
  attribute7        VARCHAR2(240),
  attribute8        VARCHAR2(240),
  attribute9        VARCHAR2(240),
  attribute10       VARCHAR2(240),
  row_version        NUMBER DEFAULT 1 NOT NULL,
  created_by         VARCHAR2(128) NOT NULL,
  created_at         TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by         VARCHAR2(128) NOT NULL,
  updated_at         TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_sales_order PRIMARY KEY (id),
  CONSTRAINT uk_sales_order_no UNIQUE (order_no),
  CONSTRAINT uk_sales_order_idem UNIQUE (customer_id, idem_key),
  CONSTRAINT fk_sales_order_customer FOREIGN KEY (customer_id) REFERENCES customer (id),
  CONSTRAINT fk_sales_order_location FOREIGN KEY (location_id) REFERENCES location (id),
  CONSTRAINT ck_sales_order_channel CHECK (channel IN ('ONLINE','POS')),
  CONSTRAINT ck_sales_order_status CHECK (status IN ('PLACED','PAID','PACKED','READY','COMPLETED','CANCELLED')),
  CONSTRAINT ck_sales_order_currency CHECK (REGEXP_LIKE(currency, '^[A-Z]{3}$')),
  CONSTRAINT ck_sales_order_amounts CHECK (total >= 0 AND tax_total >= 0 AND tax_total <= total),
  CONSTRAINT ck_sales_order_contact CHECK (channel = 'POS' OR customer_id IS NOT NULL OR contact_email IS NOT NULL)
);

CREATE TABLE sales_order_line (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  order_id         NUMBER NOT NULL,
  product_id       NUMBER NOT NULL,
  qty              NUMBER(12,3) NOT NULL,
  unit_price       NUMBER(12,4) NOT NULL,             -- snapshot (BR-06)
  tax_rate_pct     NUMBER(5,2)  NOT NULL,             -- snapshot
  discount_amount  NUMBER(12,2) DEFAULT 0 NOT NULL,
  discount_reason  VARCHAR2(200),
  approved_by      VARCHAR2(128),
  line_net         NUMBER(12,2) NOT NULL,
  line_tax         NUMBER(12,2) NOT NULL,
  line_total       NUMBER(12,2) NOT NULL,
  attribute1        VARCHAR2(240),
  attribute2        VARCHAR2(240),
  attribute3        VARCHAR2(240),
  attribute4        VARCHAR2(240),
  attribute5        VARCHAR2(240),
  attribute6        VARCHAR2(240),
  attribute7        VARCHAR2(240),
  attribute8        VARCHAR2(240),
  attribute9        VARCHAR2(240),
  attribute10       VARCHAR2(240),
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_sales_order_line PRIMARY KEY (id),
  CONSTRAINT fk_sales_order_line_order FOREIGN KEY (order_id) REFERENCES sales_order (id),
  CONSTRAINT fk_sales_order_line_product FOREIGN KEY (product_id) REFERENCES product (id),
  CONSTRAINT ck_sales_order_line_qty CHECK (qty > 0 AND qty <= 99),                       -- BR-05
  CONSTRAINT ck_sales_order_line_price CHECK (unit_price >= 0 AND tax_rate_pct BETWEEN 0 AND 100),
  CONSTRAINT ck_sales_order_line_disc CHECK (discount_amount >= 0 AND (discount_amount = 0 OR discount_reason IS NOT NULL)),
  CONSTRAINT ck_sales_order_line_total CHECK (line_net >= 0 AND line_tax >= 0 AND line_total = line_net + line_tax)
);

CREATE TABLE stock_reservation (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  stock_level_id   NUMBER NOT NULL,
  order_line_id    NUMBER NOT NULL,
  qty              NUMBER(12,3) NOT NULL,
  status           VARCHAR2(10) NOT NULL,
  expires_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_stock_reservation PRIMARY KEY (id),
  CONSTRAINT fk_stock_reservation_level FOREIGN KEY (stock_level_id) REFERENCES stock_level (id),
  CONSTRAINT fk_stock_reservation_line FOREIGN KEY (order_line_id) REFERENCES sales_order_line (id),
  CONSTRAINT ck_stock_reservation_qty CHECK (qty > 0),
  CONSTRAINT ck_stock_reservation_status CHECK (status IN ('ACTIVE','CONSUMED','RELEASED'))
);

-- insert-only. changed_by/changed_at = business actor/time set by ordering_api.
CREATE TABLE order_status_history (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  order_id         NUMBER NOT NULL,
  from_status      VARCHAR2(12),
  to_status        VARCHAR2(12) NOT NULL,
  reason           VARCHAR2(400),
  changed_by       VARCHAR2(128) NOT NULL,
  changed_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_order_status_history PRIMARY KEY (id),
  CONSTRAINT fk_order_status_history_order FOREIGN KEY (order_id) REFERENCES sales_order (id),
  CONSTRAINT ck_order_status_history_from CHECK (from_status IS NULL OR from_status IN ('PLACED','PAID','PACKED','READY','COMPLETED','CANCELLED')),
  CONSTRAINT ck_order_status_history_to CHECK (to_status IN ('PLACED','PAID','PACKED','READY','COMPLETED','CANCELLED'))
);

-- ---------------------------------------------------------------------
-- 5. PAYMENT
-- ---------------------------------------------------------------------
CREATE TABLE payment (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  order_id         NUMBER NOT NULL,
  method           VARCHAR2(10) NOT NULL,
  amount           NUMBER(12,2) NOT NULL,
  currency         CHAR(3) DEFAULT 'PKR' NOT NULL,
  status           VARCHAR2(10) NOT NULL,
  idem_key         VARCHAR2(64) NOT NULL,
  gateway_ref      VARCHAR2(100),
  gateway_event_id VARCHAR2(100),
  token            VARCHAR2(200),
  last4            CHAR(4),
  brand            VARCHAR2(20),
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_payment PRIMARY KEY (id),
  CONSTRAINT uk_payment_idem UNIQUE (idem_key),
  CONSTRAINT uk_payment_gateway_event UNIQUE (gateway_event_id),
  CONSTRAINT fk_payment_order FOREIGN KEY (order_id) REFERENCES sales_order (id),
  CONSTRAINT ck_payment_method CHECK (method IN ('CASH','CARD','ONLINE')),
  CONSTRAINT ck_payment_amount CHECK (amount > 0),
  CONSTRAINT ck_payment_currency CHECK (REGEXP_LIKE(currency, '^[A-Z]{3}$')),
  CONSTRAINT ck_payment_status CHECK (status IN ('PENDING','CONFIRMED','FAILED','REFUNDED')),
  CONSTRAINT ck_payment_last4 CHECK (last4 IS NULL OR REGEXP_LIKE(last4, '^[0-9]{4}$'))
);

-- insert-only. Cumulative refund <= payment amount enforced in payment_api.
CREATE TABLE refund (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  payment_id       NUMBER NOT NULL,
  amount           NUMBER(12,2) NOT NULL,
  currency         CHAR(3) DEFAULT 'PKR' NOT NULL,
  reason           VARCHAR2(400) NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_refund PRIMARY KEY (id),
  CONSTRAINT fk_refund_payment FOREIGN KEY (payment_id) REFERENCES payment (id),
  CONSTRAINT ck_refund_amount CHECK (amount > 0),
  CONSTRAINT ck_refund_currency CHECK (REGEXP_LIKE(currency, '^[A-Z]{3}$'))
);

-- ---------------------------------------------------------------------
-- 6. OUTBOX, COUNTS, LOGS
-- ---------------------------------------------------------------------
CREATE TABLE outbox_event (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  aggregate_type   VARCHAR2(30) NOT NULL,
  aggregate_id     NUMBER NOT NULL,
  type             VARCHAR2(40) NOT NULL,
  payload          CLOB NOT NULL,
  attempts         NUMBER(3) DEFAULT 0 NOT NULL,
  last_error       VARCHAR2(4000),
  processed_at     TIMESTAMP WITH TIME ZONE,
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_outbox_event PRIMARY KEY (id),
  CONSTRAINT ck_outbox_event_payload CHECK (payload IS JSON)
);

CREATE TABLE cycle_count (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  location_id      NUMBER NOT NULL,
  status           VARCHAR2(20) DEFAULT 'OPEN' NOT NULL,
  opened_at        TIMESTAMP WITH TIME ZONE NOT NULL,
  closed_at        TIMESTAMP WITH TIME ZONE,
  approved_by      VARCHAR2(128),
  row_version      NUMBER DEFAULT 1 NOT NULL,
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_cycle_count PRIMARY KEY (id),
  CONSTRAINT fk_cycle_count_location FOREIGN KEY (location_id) REFERENCES location (id),
  CONSTRAINT ck_cycle_count_status CHECK (status IN ('OPEN','PENDING_APPROVAL','CLOSED')),
  CONSTRAINT ck_cycle_count_closed CHECK (status <> 'CLOSED' OR closed_at IS NOT NULL)
);

CREATE TABLE cycle_count_line (
  id                     NUMBER GENERATED ALWAYS AS IDENTITY,
  cycle_count_id         NUMBER NOT NULL,
  product_id             NUMBER NOT NULL,
  snapshot_qty           NUMBER(12,3) NOT NULL,
  counted_qty            NUMBER(12,3),
  variance_qty           NUMBER(12,3),
  variance_value         NUMBER(12,2),
  adjustment_movement_id NUMBER,
  row_version            NUMBER DEFAULT 1 NOT NULL,
  created_by             VARCHAR2(128) NOT NULL,
  created_at             TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by             VARCHAR2(128) NOT NULL,
  updated_at             TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_cycle_count_line PRIMARY KEY (id),
  CONSTRAINT uk_cycle_count_line UNIQUE (cycle_count_id, product_id),
  CONSTRAINT fk_cycle_count_line_count FOREIGN KEY (cycle_count_id) REFERENCES cycle_count (id),
  CONSTRAINT fk_cycle_count_line_product FOREIGN KEY (product_id) REFERENCES product (id),
  CONSTRAINT fk_cycle_count_line_move FOREIGN KEY (adjustment_movement_id) REFERENCES stock_movement (id),
  CONSTRAINT ck_cycle_count_line_qty CHECK (snapshot_qty >= 0 AND (counted_qty IS NULL OR counted_qty >= 0))
);

-- insert-only
CREATE TABLE app_log (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  log_level        VARCHAR2(10) NOT NULL,
  module           VARCHAR2(100) NOT NULL,
  message          VARCHAR2(4000) NOT NULL,
  context          CLOB,
  correlation_id   VARCHAR2(64),
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_app_log PRIMARY KEY (id),
  CONSTRAINT ck_app_log_level CHECK (log_level IN ('DEBUG','INFO','WARN','ERROR')),
  CONSTRAINT ck_app_log_context CHECK (context IS JSON)
);

-- insert-only security audit (Security §8)
CREATE TABLE audit_log (
  id               NUMBER GENERATED ALWAYS AS IDENTITY,
  user_name        VARCHAR2(128),
  role_code        VARCHAR2(30),
  action           VARCHAR2(60) NOT NULL,
  object_type      VARCHAR2(60),
  object_id        VARCHAR2(60),
  old_value        CLOB,
  new_value        CLOB,
  ip_address       VARCHAR2(45),
  correlation_id   VARCHAR2(64),
  created_by       VARCHAR2(128) NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_by       VARCHAR2(128) NOT NULL,
  updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT pk_audit_log PRIMARY KEY (id),
  CONSTRAINT ck_audit_log_old CHECK (old_value IS JSON),
  CONSTRAINT ck_audit_log_new CHECK (new_value IS JSON)
);

-- ---------------------------------------------------------------------
-- 7. INDEXES (PM4: transactional tables or >1000 expected rows only)
-- ---------------------------------------------------------------------
-- >1000 rows (master)
CREATE INDEX ix_product_barcode_product ON product_barcode (product_id);
CREATE INDEX ix_product_tax_rate        ON product (tax_rate_id);
CREATE INDEX ix_stock_level_location    ON stock_level (location_id);
CREATE INDEX ix_customer_email          ON customer (email);

-- transactional
CREATE INDEX ix_stock_movement_level_ts ON stock_movement (stock_level_id, created_at);
CREATE UNIQUE INDEX uk_stock_movement_ref ON stock_movement (
  CASE WHEN ref_id IS NOT NULL THEN stock_level_id || ':' || ref_type || ':' || ref_id || ':' || type END);  -- idempotency
CREATE INDEX ix_stock_movement_supplier ON stock_movement (supplier_id);

CREATE INDEX ix_sales_order_cust_created ON sales_order (customer_id, created_at DESC);
CREATE INDEX ix_sales_order_status_exp   ON sales_order (status, expires_at);
CREATE INDEX ix_sales_order_location     ON sales_order (location_id);
CREATE INDEX ix_sales_order_line_order   ON sales_order_line (order_id);
CREATE INDEX ix_sales_order_line_product ON sales_order_line (product_id);

CREATE INDEX ix_stock_reservation_status_exp ON stock_reservation (status, expires_at);
CREATE INDEX ix_stock_reservation_line       ON stock_reservation (order_line_id);
CREATE INDEX ix_stock_reservation_level      ON stock_reservation (stock_level_id, status);

CREATE INDEX ix_order_status_history_order ON order_status_history (order_id, changed_at);

CREATE INDEX ix_payment_order  ON payment (order_id);
CREATE INDEX ix_refund_payment ON refund (payment_id);

CREATE INDEX ix_outbox_event_pending ON outbox_event (CASE WHEN processed_at IS NULL THEN 1 END);

CREATE INDEX ix_cycle_count_status    ON cycle_count (status, location_id);
CREATE INDEX ix_cycle_count_line_prod ON cycle_count_line (product_id);

CREATE INDEX ix_app_log_created    ON app_log (created_at);
CREATE INDEX ix_audit_log_object   ON audit_log (object_type, object_id);
CREATE INDEX ix_audit_log_created  ON audit_log (created_at);

-- ---------------------------------------------------------------------
-- 8. TRIGGERS (PM3 WHO columns + immutability)
-- ---------------------------------------------------------------------
DECLARE
  TYPE t_list IS TABLE OF VARCHAR2(30);
  c_mutable t_list := t_list(
    'APP_ROLE','APP_CONFIG','LOCATION','TAX_RATE','SUPPLIER','APP_USER','APP_USER_ROLE',
    'EMPLOYEE','CUSTOMER','PRODUCT','PRODUCT_BARCODE','PRODUCT_SUPPLIER','STOCK_LEVEL',
    'SALES_ORDER','SALES_ORDER_LINE','STOCK_RESERVATION','PAYMENT','OUTBOX_EVENT',
    'CYCLE_COUNT','CYCLE_COUNT_LINE');
  c_insert_only t_list := t_list(
    'STOCK_MOVEMENT','ORDER_STATUS_HISTORY','REFUND','APP_LOG','AUDIT_LOG');
  c_decl CONSTANT VARCHAR2(600) :=
    'DECLARE l_user VARCHAR2(128) := COALESCE(SYS_CONTEXT(''APEX$SESSION'',''APP_USER''), SYS_CONTEXT(''USERENV'',''SESSION_USER'')); '
 || 'l_now TIMESTAMP WITH TIME ZONE := SYSTIMESTAMP AT TIME ZONE ''UTC''; BEGIN ';
BEGIN
  -- mutable: WHO + row_version
  FOR i IN 1 .. c_mutable.COUNT LOOP
    EXECUTE IMMEDIATE
      'CREATE OR REPLACE TRIGGER trg_' || LOWER(c_mutable(i)) || '_who '
   || 'BEFORE INSERT OR UPDATE ON ' || c_mutable(i) || ' FOR EACH ROW ' || c_decl
   || 'IF INSERTING THEN '
   ||   ':NEW.created_by := l_user; :NEW.created_at := l_now; '
   ||   ':NEW.updated_by := l_user; :NEW.updated_at := l_now; :NEW.row_version := 1; '
   || 'ELSE '
   ||   ':NEW.created_by := :OLD.created_by; :NEW.created_at := :OLD.created_at; '
   ||   ':NEW.updated_by := l_user; :NEW.updated_at := l_now; :NEW.row_version := :OLD.row_version + 1; '
   || 'END IF; END;';
  END LOOP;

  -- insert-only: WHO on insert (updated_* = created_*) + block UPDATE/DELETE
  FOR i IN 1 .. c_insert_only.COUNT LOOP
    EXECUTE IMMEDIATE
      'CREATE OR REPLACE TRIGGER trg_' || LOWER(c_insert_only(i)) || '_who '
   || 'BEFORE INSERT ON ' || c_insert_only(i) || ' FOR EACH ROW ' || c_decl
   || ':NEW.created_by := l_user; :NEW.created_at := l_now; '
   || ':NEW.updated_by := l_user; :NEW.updated_at := l_now; END;';

    EXECUTE IMMEDIATE
      'CREATE OR REPLACE TRIGGER trg_' || LOWER(c_insert_only(i)) || '_immut '
   || 'BEFORE UPDATE OR DELETE ON ' || c_insert_only(i) || ' FOR EACH ROW BEGIN '
   || 'RAISE_APPLICATION_ERROR(-20901, ''' || c_insert_only(i) || ' is insert-only''); END;';
  END LOOP;
END;
/

-- closed cycle count is immutable
CREATE OR REPLACE TRIGGER trg_cycle_count_closed
BEFORE UPDATE OR DELETE ON cycle_count
FOR EACH ROW
BEGIN
  IF :OLD.status = 'CLOSED' THEN
    RAISE_APPLICATION_ERROR(-20902, 'Closed cycle_count is immutable');
  END IF;
END;
/

-- ---------------------------------------------------------------------
-- 9. SEED DATA
-- ---------------------------------------------------------------------
INSERT INTO app_role (code, name, description) VALUES ('GUEST',         'Guest',         'Anonymous storefront user');
INSERT INTO app_role (code, name, description) VALUES ('CUSTOMER',      'Customer',      'Registered online buyer');
INSERT INTO app_role (code, name, description) VALUES ('CASHIER',       'Cashier',       'In-store seller');
INSERT INTO app_role (code, name, description) VALUES ('STOCK_MANAGER', 'Stock manager', 'Receives, counts, adjusts, packs');
INSERT INTO app_role (code, name, description) VALUES ('ADMIN',         'Admin',         'Owner; users, prices, approvals');
INSERT INTO app_role (code, name, description) VALUES ('EMPLOYEE',      'Employee',      'General staff; back-office access per permission matrix');
INSERT INTO app_role (code, name, description) VALUES ('SUPPLIER',      'Supplier',      'External supplier; own products/receipts only');
INSERT INTO app_role (code, name, description) VALUES ('SYSTEM',        'System',        'Scheduler / webhook');

INSERT INTO location (code, name) VALUES ('MAIN', 'Main store');

INSERT INTO tax_rate (code, rate_pct, valid_from) VALUES ('EXEMPT', 0, DATE '2026-01-01');

INSERT INTO app_config (config_key, config_value, description) VALUES ('RESERVATION_EXPIRY_MIN',  '30', 'Unpaid reservation expiry (BR-03)');
INSERT INTO app_config (config_key, config_value, description) VALUES ('CASHIER_MAX_DISCOUNT_PCT', '10', 'Above needs ADMIN');
INSERT INTO app_config (config_key, config_value, description) VALUES ('MAX_LINE_QTY',            '99', 'BR-05');
INSERT INTO app_config (config_key, config_value, description) VALUES ('REFUND_WINDOW_DAYS',      '7',  'Return window');
INSERT INTO app_config (config_key, config_value, description) VALUES ('CURRENCY',                'PKR','ISO 4217, v1 fixed');

COMMIT;
