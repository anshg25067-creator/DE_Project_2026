cat >> docs/05_scalability_report.md <<'EOF'

## Messages Table Partitioning (Aditya)

### Strategy
The demonstration uses monthly RANGE partitioning on `sent_at`. This groups messages by month and allows PostgreSQL to skip partitions that cannot contain rows matching a date-range query.

### Implementation
- Parent table: `whatsapp_partition_demo.messages`
- Partition key: `sent_at`
- Partition type: RANGE
- Monthly partitions: January 2025 through July 2026, plus a DEFAULT partition.
- Indexes: `(chat_id, sent_at DESC)`, `(sent_at, sender_id)`, and a partial index on `(sender_id, sent_at)` for forwarded messages.

### Validation
Inserted test messages dated January 15, 2025 and June 15, 2026. The `tableoid` query confirmed that PostgreSQL stored them in `messages_2025_01` and `messages_2026_06`, respectively.

The following date-range query was tested with `EXPLAIN (COSTS OFF)`:

```sql
SELECT message_id, chat_id, sent_at, body
FROM whatsapp_partition_demo.messages
WHERE sent_at >= TIMESTAMPTZ '2026-06-01 00:00:00+00'
  AND sent_at < TIMESTAMPTZ '2026-07-01 00:00:00+00';