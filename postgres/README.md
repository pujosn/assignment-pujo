# PostgreSQL configuration and investigation

## Start and verify

1. Copy `.env.example` to `.env`, then replace its passwords with strong values.
2. Start the database with `docker-compose up -d db`.
3. Check the configured connection limit:

   ```sh
   docker-compose exec -T db psql -U postgres -d postgres -c "SHOW max_connections;"
   ```

   Expected result: `200`.

The initialization script creates:

| Role | Access |
| --- | --- |
| `sre_app` | Login role; owns database `sre` and has full access. |
| `sre_readonly` | Login role; has `SELECT` on current and future public-schema tables. |

The passwords are supplied only through `.env`, which Git ignores.

## Slow affiliate count: analysis and resolution

The provided `client` schema has a primary key only on `id`. `client_id` is not indexed, so this query scans all client rows to find a matching `client_id`:

```sql
SELECT count(affiliates)
FROM client
WHERE client_id = 'this_is_client_id';
```

Under concurrent requests, repeated sequential scans explain the database CPU spike. Confirm it first in a non-production environment with:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(affiliates)
FROM client
WHERE client_id = 'this_is_client_id';
```

Then create the lookup index without blocking writes:

```sql
CREATE INDEX CONCURRENTLY idx_client_client_id ON client (client_id);
ANALYZE client;
```

Run `EXPLAIN (ANALYZE, BUFFERS)` again to confirm an index scan or index-only scan and lower buffer reads. `count(affiliates)` counts only non-NULL affiliate values; use `count(*)` only if the business question means “how many client rows” rather than “how many non-NULL affiliate values.” If the intended model is one affiliate per row, affiliates should be normalized into a separate indexed affiliate table instead of a `varchar` column.
