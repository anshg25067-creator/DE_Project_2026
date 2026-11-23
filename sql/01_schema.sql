SELECT 'users' AS table_name, COUNT(*) AS total_rows FROM whatsapp.users
UNION ALL
SELECT 'chats', COUNT(*) FROM whatsapp.chats
UNION ALL
SELECT 'media', COUNT(*) FROM whatsapp.media
UNION ALL
SELECT 'devices', COUNT(*) FROM whatsapp.devices
UNION ALL
SELECT 'chat_members', COUNT(*) FROM whatsapp.chat_members
UNION ALL
SELECT 'blocked_users', COUNT(*) FROM whatsapp.blocked_users
UNION ALL
SELECT 'messages', COUNT(*) FROM whatsapp.messages
UNION ALL
SELECT 'message_receipts', COUNT(*) FROM whatsapp.message_receipts
UNION ALL
SELECT 'calls', COUNT(*) FROM whatsapp.calls;


SELECT
    pg_size_pretty(pg_database_size('whatsapp_large'))
    AS database_size;