
SET search_path TO whatsapp;

-- ============================================================
-- CP3: PROPOSED INDEXES
-- Contributor: Aditya
-- Coordinate these indexes with Piyush before integration.
-- ============================================================

-- R01, R02: Latest messages within a chat
CREATE INDEX IF NOT EXISTS idx_messages_chat_sent_at
ON messages (chat_id, sent_at DESC);

-- R03: Unread receipts belonging to a user
CREATE INDEX IF NOT EXISTS idx_receipts_unread_user
ON message_receipts (user_id, message_id)
WHERE read_at IS NULL;

-- R06: Find memberships belonging to a user
CREATE INDEX IF NOT EXISTS idx_chat_members_user_chat
ON chat_members (user_id, chat_id);

-- R08: Undelivered receipts
CREATE INDEX IF NOT EXISTS idx_receipts_undelivered
ON message_receipts (message_id)
WHERE delivered_at IS NULL;

-- R10: June date-range message filtering
CREATE INDEX IF NOT EXISTS idx_messages_sent_at_sender
ON messages (sent_at, sender_id);

-- R11: Missed calls by chat and start time
CREATE INDEX IF NOT EXISTS idx_calls_missed_chat_started
ON calls (chat_id, started_at DESC)
WHERE status = 'MISSED';

-- R12: Forwarded messages grouped by sender and date
CREATE INDEX IF NOT EXISTS idx_messages_forwarded_sender_date
ON messages (sender_id, sent_at)
WHERE is_forwarded = TRUE;
-- CP3: indexes justified by baseline EXPLAIN (ANALYZE, BUFFERS) plans.
SET search_path TO whatsapp;

-- R13: locate replies efficiently when checking unanswered questions.
CREATE INDEX IF NOT EXISTS idx_messages_reply_to
ON messages (reply_to_message_id)
WHERE reply_to_message_id IS NOT NULL;

-- R14, R17: June date-range filtering and message-type analytics.
CREATE INDEX IF NOT EXISTS idx_messages_sent_at_chat_sender
ON messages (sent_at, chat_id, sender_id);

-- R01, R02, R19: chat message lookup and latest-message ordering.
CREATE INDEX IF NOT EXISTS idx_messages_chat_sent_at
ON messages (chat_id, sent_at DESC);

-- R18: find active group memberships by user.
CREATE INDEX IF NOT EXISTS idx_chat_members_active_user_chat
ON chat_members (user_id, chat_id)
WHERE left_at IS NULL;

-- R18: locate users by last-seen cutoff.
CREATE INDEX IF NOT EXISTS idx_users_last_seen
ON users (last_seen_at);

-- R23: filter inactive WEB/DESKTOP devices.
CREATE INDEX IF NOT EXISTS idx_devices_web_desktop_last_active
ON devices (last_active_at)
WHERE device_type IN ('WEB', 'DESKTOP');

-- R24: group duplicate media by SHA-256.
CREATE INDEX IF NOT EXISTS idx_media_sha256
ON media (sha256);

-- W02: locate unread receipts for a particular user.
CREATE INDEX IF NOT EXISTS idx_receipts_unread_user_message
ON message_receipts (user_id, message_id)
WHERE read_at IS NULL;

ANALYZE;
