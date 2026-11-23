
-- ============================================================
-- CP4: MESSAGES RANGE PARTITIONING
-- Contributor: Aditya
-- Strategy: Monthly RANGE partitioning on sent_at
-- ============================================================

-- Demonstration schema: does not modify the original tables.
CREATE SCHEMA IF NOT EXISTS whatsapp_partition_demo;

-- Partitioned messages table.
-- IMPORTANT: PostgreSQL requires the partition key (sent_at)
-- to be included in a partitioned table's primary key.
CREATE TABLE whatsapp_partition_demo.messages (
    message_id BIGINT NOT NULL,
    chat_id BIGINT NOT NULL,
    sender_id BIGINT NOT NULL,
    sent_at TIMESTAMPTZ NOT NULL,
    message_type VARCHAR(20) NOT NULL,
    body TEXT,
    is_forwarded BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (message_id, sent_at)
)
PARTITION BY RANGE (sent_at);

-- Create monthly partitions from January 2025
-- through July 2026 (upper bound is exclusive).

DO $$
DECLARE
    month_start DATE := DATE '2025-01-01';
    next_month DATE;
    partition_name TEXT;
BEGIN
    WHILE month_start < DATE '2026-08-01' LOOP
        next_month := (month_start + INTERVAL '1 month')::DATE;
        partition_name := 'messages_' || TO_CHAR(month_start, 'YYYY_MM');

        EXECUTE FORMAT(
            'CREATE TABLE whatsapp_partition_demo.%I
             PARTITION OF whatsapp_partition_demo.messages
             FOR VALUES FROM (%L) TO (%L)',
            partition_name,
            month_start::TIMESTAMP AT TIME ZONE 'UTC',
            next_month::TIMESTAMP AT TIME ZONE 'UTC'
        );

        month_start := next_month;
    END LOOP;
END $$;


-- Catch dates outside the explicitly created range.
CREATE TABLE whatsapp_partition_demo.messages_default
PARTITION OF whatsapp_partition_demo.messages DEFAULT;

-- Indexes on the partitioned parent.
CREATE INDEX idx_partition_messages_chat_sent
ON whatsapp_partition_demo.messages (chat_id, sent_at DESC);

CREATE INDEX idx_partition_messages_sent_sender
ON whatsapp_partition_demo.messages (sent_at, sender_id);

CREATE INDEX idx_partition_messages_forwarded
ON whatsapp_partition_demo.messages (sender_id, sent_at)
WHERE is_forwarded = TRUE;

-- Test data in two different monthly partitions.
INSERT INTO whatsapp_partition_demo.messages
(message_id, chat_id, sender_id, sent_at, message_type, body)
VALUES
(1, 100, 10, '2025-01-15 10:00:00+00', 'TEXT', 'January message'),
(2, 100, 10, '2026-06-15 10:00:00+00', 'TEXT', 'June message');

-- Verify rows.
SELECT tableoid::regclass AS partition_name, *
FROM whatsapp_partition_demo.messages
ORDER BY sent_at;

-- Demonstrate partition pruning.
EXPLAIN (COSTS OFF)
SELECT message_id, chat_id, sent_at, body
FROM whatsapp_partition_demo.messages
WHERE sent_at >= TIMESTAMPTZ '2026-06-01 00:00:00+00'
  AND sent_at <  TIMESTAMPTZ '2026-07-01 00:00:00+00';

-- Clean-up is intentionally omitted so the demonstration remains available.
