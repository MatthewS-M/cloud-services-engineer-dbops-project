ALTER TABLE product
ADD CONSTRAINT product_pkey PRIMARY KEY (id);

ALTER TABLE orders
ADD COLUMN date_created DATE DEFAULT CURRENT_DATE,
ADD CONSTRAINT orders_pkey PRIMARY KEY (id);

ALTER TABLE product
ADD COLUMN price DOUBLE PRECISION;

ALTER TABLE order_product
ADD CONSTRAINT order_product_order_fk
    FOREIGN KEY (order_id) REFERENCES orders (id),
ADD CONSTRAINT order_product_product_fk
    FOREIGN KEY (product_id) REFERENCES product (id);

DROP TABLE IF EXISTS product_info;
DROP TABLE IF EXISTS orders_date;
