# dbops-project
Исходный репозиторий для выполнения проекта дисциплины "DBOps"

## SQL-запросы

### Создание базы данных и пользователя

```sql
DROP DATABASE IF EXISTS store;
DROP ROLE IF EXISTS store_user;

CREATE ROLE store_user WITH LOGIN PASSWORD 'store_password';
CREATE DATABASE store OWNER store_user;

GRANT ALL PRIVILEGES ON DATABASE store TO store_user;
```

### Выдача прав пользователю в базе `store`

```sql
GRANT ALL ON SCHEMA public TO store_user;
ALTER SCHEMA public OWNER TO store_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON TABLES TO store_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON SEQUENCES TO store_user;
```

### Проданные сосиски за каждый день предыдущей недели

```sql
SELECT o.date_created, SUM(op.quantity)
FROM orders AS o
JOIN order_product AS op ON o.id = op.order_id
WHERE o.status = 'shipped'
  AND o.date_created > NOW() - INTERVAL '7 DAY'
GROUP BY o.date_created
ORDER BY o.date_created;
```

### Сравнение производительности запроса до и после индексов

Созданные индексы:

```sql
CREATE INDEX order_product_order_id_idx
    ON order_product (order_id);

CREATE INDEX orders_status_date_idx
    ON orders (status, date_created);
```

#### Время выполнения без индексов

```text
Time: 4652.148 ms (00:04.652)
```

#### EXPLAIN (ANALYZE) без индексов

```text
Finalize GroupAggregate  (cost=266165.26..266188.31 rows=91 width=12) (actual time=5104.897..5134.966 rows=8 loops=1)
  Group Key: o.date_created
  Buffers: shared hit=12999 read=114431
  ->  Gather Merge  (cost=266165.26..266186.49 rows=182 width=12) (actual time=5104.872..5134.938 rows=24 loops=1)
        Workers Planned: 2
        Workers Launched: 2
        Buffers: shared hit=12999 read=114431
        ->  Sort  (cost=265165.23..265165.46 rows=91 width=12) (actual time=5074.834..5074.838 rows=8 loops=3)
              Sort Key: o.date_created
              Sort Method: quicksort  Memory: 25kB
              Buffers: shared hit=12999 read=114431
              ->  Partial HashAggregate  (cost=265161.36..265162.27 rows=91 width=12) (actual time=5074.807..5074.813 rows=8 loops=3)
                    Group Key: o.date_created
                    Batches: 1  Memory Usage: 24kB
                    Buffers: shared hit=12983 read=114431
                    ->  Parallel Hash Join  (cost=148337.48..264637.26 rows=104821 width=8) (actual time=827.569..5021.063 rows=86825 loops=3)
                          Hash Cond: (op.order_id = o.id)
                          Buffers: shared hit=12983 read=114431
                          ->  Parallel Seq Scan on order_product op  (cost=0.00..105362.15 rows=4166715 width=12) (actual time=0.063..1063.509 rows=3333333 loops=3)
                                Buffers: shared hit=6399 read=57296
                          ->  Parallel Hash  (cost=147027.26..147027.26 rows=104818 width=12) (actual time=826.078..826.079 rows=86825 loops=3)
                                Buckets: 262144  Batches: 1  Memory Usage: 14304kB
                                Buffers: shared hit=6560 read=57135
                                ->  Parallel Seq Scan on orders o  (cost=0.00..147027.26 rows=104818 width=12) (actual time=14.923..784.868 rows=86825 loops=3)
                                      Filter: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
                                      Rows Removed by Filter: 3246509
                                      Buffers: shared hit=6560 read=57135
Planning Time: 38.437 ms
Execution Time: 5154.415 ms
```

#### Время выполнения с индексами

```text
Time: 3811.139 ms (00:03.811)
```

#### EXPLAIN (ANALYZE) с индексами

```text
Finalize GroupAggregate  (cost=188719.11..188742.17 rows=91 width=12) (actual time=4220.707..4241.527 rows=8 loops=1)
  Group Key: o.date_created
  Buffers: shared hit=146 read=126488 written=5
  ->  Gather Merge  (cost=188719.11..188740.35 rows=182 width=12) (actual time=4220.692..4241.509 rows=24 loops=1)
        Workers Planned: 2
        Workers Launched: 2
        Buffers: shared hit=146 read=126488 written=5
        ->  Sort  (cost=187719.09..187719.32 rows=91 width=12) (actual time=4174.580..4174.585 rows=8 loops=3)
              Sort Key: o.date_created
              Sort Method: quicksort  Memory: 25kB
              Buffers: shared hit=146 read=126488 written=5
              ->  Partial HashAggregate  (cost=187715.22..187716.13 rows=91 width=12) (actual time=4174.528..4174.534 rows=8 loops=3)
                    Group Key: o.date_created
                    Batches: 1  Memory Usage: 24kB
                    Buffers: shared hit=130 read=126488 written=5
                    ->  Parallel Hash Join  (cost=70866.97..187166.75 rows=109694 width=8) (actual time=345.664..4120.587 rows=86825 loops=3)
                          Hash Cond: (op.order_id = o.id)
                          Buffers: shared hit=130 read=126488 written=5
                          ->  Parallel Seq Scan on order_product op  (cost=0.00..105362.15 rows=4166715 width=12) (actual time=0.045..936.837 rows=3333333 loops=3)
                                Buffers: shared hit=103 read=63592
                          ->  Parallel Hash  (cost=69495.80..69495.80 rows=109694 width=12) (actual time=343.411..343.413 rows=86825 loops=3)
                                Buckets: 524288  Batches: 1  Memory Usage: 16352kB
                                Buffers: shared hit=3 read=62896 written=5
                                ->  Parallel Bitmap Heap Scan on orders o  (cost=3606.92..69495.80 rows=109694 width=12) (actual time=28.599..288.851 rows=86825 loops=3)
                                      Recheck Cond: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
                                      Heap Blocks: exact=22155
                                      Buffers: shared hit=3 read=62896 written=5
                                      ->  Bitmap Index Scan on orders_status_date_idx  (cost=0.00..3541.10 rows=263266 width=0) (actual time=38.913..38.913 rows=260474 loops=1)
                                            Index Cond: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
                                            Buffers: shared hit=3 read=226
Planning Time: 1.089 ms
Execution Time: 4263.594 ms
```

#### Краткий вывод

После создания индексов время выполнения запроса сократилось примерно с `4652 ms` до `3811 ms`, а время выполнения по `EXPLAIN (ANALYZE)` — с `5154 ms` до `4264 ms`. План запроса изменился: вместо полного последовательного чтения таблицы `orders` PostgreSQL начал использовать `Bitmap Index Scan` по индексу `orders_status_date_idx`.
