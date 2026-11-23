# CP3 — Baseline Query Timings

## 1. Objective

This report records the baseline performance of the 30 SQL queries (R01–R25 and W01–W05) in the WhatsApp messaging database before query optimization.

Each query was executed three times using `EXPLAIN (ANALYZE, BUFFERS)`. The average execution time is calculated from the three runs.

Write queries were executed inside transactions and rolled back to prevent permanent changes to the database.

## 2. Benchmark environment

- Database: `whatsapp_project`
- DBMS: PostgreSQL 18
- Dataset: Seed dataset
- Benchmark phase: `baseline`
- Number of queries: 30
- Runs per query: 3
- Total executions: 90
- Measurement: Execution Time (milliseconds)
- Benchmark command: `./benchmarks/run_benchmark.sh whatsapp_project baseline`

## 3. Baseline timing results

| Query | Type | Description | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) | Scan type |
|---|---|---|---:|---:|---:|---:|---|
| R01 | READ | Chats screen: user 965's chats with latest message | 43.640 | 24.108 | 19.766 | 29.171 | Seq Scan: chat_members, messages; Index Scan: chats |
| R02 | READ | Open group 22556: latest messages | 4.594 | 4.461 | 3.671 | 4.242 | Seq Scan: messages |
| R03 | READ | Unread message counts per chat for user 965 | 8.296 | 7.875 | 8.728 | 8.300 | Parallel Seq Scan: message_receipts; Index Scan: messages |
| R04 | READ | Search for "meeting" in user's chats | 27.922 | 25.471 | 24.058 | 25.817 | Seq Scan: messages, chat_members |
| R05 | READ | Check whether a phone number is registered | 0.993 | 0.027 | 0.028 | 0.349 | Index Scan: users |
| R06 | READ | Last seen of users in direct chats with user 965 | 3.543 | 3.425 | 5.571 | 4.180 | Seq Scan: chat_members; Index Scans: other tables |
| R07 | READ | Active members of group 22556 with their roles | 1.320 | 0.120 | 0.128 | 0.523 | Index Scans: chat_members, users |
| R08 | READ | Undelivered receipts for messages sent before cutoff | 21.745 | 18.128 | 16.429 | 18.767 | Parallel Seq Scans: messages, message_receipts |
| R09 | READ | Top 20 users by total media uploaded | 12.326 | 10.192 | 10.194 | 10.904 | Seq Scan: media |
| R10 | READ | Daily active senders in June 2026 | 9.511 | 10.769 | 10.729 | 10.336 | Seq Scan: messages |
| R11 | READ | Missed calls received by user 965 since Jan 2025 | 7.646 | 6.252 | 6.677 | 6.858 | Seq Scan: chat_members, calls |
| R12 | READ | Users forwarding two or more messages on the same day | 7.272 | 8.929 | 9.035 | 8.412 | Seq Scan: messages |
| R13 | READ | Unanswered questions in group 20501 | 28.813 | 24.737 | 21.828 | 25.126 | Seq Scan: messages |
| R14 | READ | Top 10 groups by distinct senders in June 2026 | 6.793 | 6.693 | 6.727 | 6.738 | Seq Scan: messages, chats |
| R15 | READ | Check whether user 3064 blocked user 17793 | 0.229 | 0.026 | 0.022 | 0.092 | Index Only Scan: blocked_users |
| R16 | READ | Readers and read times for message 119989 | 1.054 | 0.056 | 0.057 | 0.389 | Index Scans: message_receipts, users |
| R17 | READ | Average send-to-read time per message type | 27.839 | 21.001 | 18.286 | 22.375 | Seq Scan: message_receipts, messages |
| R18 | READ | Inactive users still in at least one group | 16.417 | 15.738 | 15.319 | 15.825 | Seq Scan: users, chat_members, chats |
| R19 | READ | Last message time and June message count per group | 15746.260 | 15960.766 | 16342.906 | 16016.644 | Seq Scan: chats, messages |
| R20 | READ | Messages per hour by message type | 46.686 | 48.592 | 50.026 | 48.435 | Seq Scan: messages |
| R21 | READ | Share of messages edited or deleted by type | 13.118 | 12.694 | 12.487 | 12.766 | Seq Scan: messages |
| R22 | READ | Message history page 4,001 | 13.784 | 8.442 | 8.543 | 10.256 | Index Scan: messages |
| R23 | READ | Inactive linked WEB/DESKTOP devices | 3.929 | 3.860 | 3.773 | 3.854 | Seq Scan: devices |
| R24 | READ | Media files uploaded more than once | 8.114 | 8.059 | 8.133 | 8.102 | Seq Scan: media |
| R25 | READ | Reply chain starting at message 119989 | 0.054 | 0.058 | 0.051 | 0.054 | Index Scan: messages |
| W01 | WRITE | Send a text message in group 22556 | 0.956 | 0.440 | 0.414 | 0.603 | No scan node captured |
| W02 | WRITE | Mark user 965's unread group messages as read | 20.253 | 8.113 | 6.587 | 11.651 | Seq Scan: messages; Index Scan: message_receipts |
| W03 | WRITE | Delete message 119989 for everyone | 0.580 | 0.481 | 0.286 | 0.449 | Index Scan: messages |
| W04 | WRITE | Create receipts for 5,000 recipients | 56.683 | 34.807 | 26.314 | 39.268 | No scan node captured |
| W05 | WRITE | User 965 leaves group 20898 | 0.594 | 0.129 | 0.132 | 0.285 | Index Scan: chat_members |
| **TOTAL** | | **Sum of all 30 average execution times** | | | | **16350.771** | |

*Note: Scan types are summarized from the benchmark output. Parallel scan details for R03 and R08 are taken from their raw execution plans. "No scan node captured" means the benchmark summary did not identify a scan node for that write operation.*

## 4. Detailed query plan analysis

### R01 — Chats screen

Average execution time: **29.171 ms**

PostgreSQL performs sequential scans on `chat_members` and `messages`, with an index scan on `chats_pkey`.

- The `chat_members` scan examines 104,514 rows and removes 104,510 rows to find four active memberships for user 965.
- The `messages` sequential scan runs four times inside a nested-loop operation.
- Each messages scan removes 119,980 non-matching rows.
- PostgreSQL sorts the matching messages by `sent_at DESC` and applies LIMIT.

The repeated messages scan and the initial membership scan are the main contributors to execution time.

### R02 — Open group history

Average execution time: **4.242 ms**

PostgreSQL performs a sequential scan on `messages`, filtering for `chat_id = 22556`.

- It examines 120,000 rows.
- It removes 119,966 non-matching rows.
- It returns 34 matching rows.
- The matching rows are sorted by `sent_at DESC` before LIMIT is applied.

The full-table scan is the main potential performance bottleneck.

### R03 — Unread badge counts

Average execution time: **8.300 ms**

PostgreSQL uses a parallel sequential scan on `message_receipts` and an index scan on `messages_pkey`.

- The receipts scan filters for `user_id = 965` and `read_at IS NULL`.
- Approximately 167,191 rows are removed per worker.
- Matching receipts are joined with messages using the primary-key index.
- Results are grouped by `chat_id` and sorted by descending count.

The large scan on `message_receipts` is the main contributor to execution time. Parallel processing distributes the workload.

### R04 — Message search

Average execution time: **25.817 ms**

PostgreSQL performs sequential scans on both `messages` and `chat_members`, followed by a Hash Join on `chat_id`.

- The messages scan evaluates a case-insensitive substring condition: `body ILIKE '%meeting%'`.
- It removes 107,065 rows and retains 12,935 matching messages.
- The membership scan removes 104,510 rows to find four memberships for user 965.
- The resulting six rows are sorted by `sent_at DESC`.

The full-table scans, especially the substring search on messages, are the main contributors to execution time.

### R05 — Phone number lookup

Average execution time: **0.349 ms**

PostgreSQL uses an Index Scan through the existing unique index `users_phone_e164_key`.

- Only one row is returned.
- The query avoids a sequential scan of the users table.
- The first run takes 0.993 ms due to physical buffer reads.
- Subsequent runs take approximately 0.03 ms because the required pages are cached.

This is an efficient baseline query.

### R06 — Direct chat contact information

Average execution time: **4.180 ms**

PostgreSQL performs a sequential scan on `chat_members`, followed by index lookups on other tables.

- The initial scan examines 104,514 membership rows to find four records for user 965.
- An index-only scan on `pk_chat_members` retrieves other members sharing those chats, with zero heap fetches.
- Nested Loop joins perform 97 lookups in `chats` using `chats_pkey`.
- The query filters for direct chats and retrieves user information using `users_pkey`.
- The final result is sorted by `last_seen_at DESC NULLS LAST`.

The initial sequential scan on `chat_members` is the main potential performance bottleneck.

### R07 — Group members

Average execution time: **0.523 ms**

PostgreSQL uses Index Scans on `chat_members` and `users`.

- `pk_chat_members` locates members of chat 22556.
- Only three membership records are filtered out.
- `users_pkey` retrieves details for the 22 matching members.
- The final rows are sorted by role and display name.

The query is efficient because both tables are accessed through existing indexes. The first run is slower due to physical buffer reads, while subsequent runs benefit from caching.

### R08 — Pending delivery receipts

Average execution time: **18.767 ms**

PostgreSQL performs parallel sequential scans on `messages` and `message_receipts`, followed by a Parallel Hash Join.

- The messages scan filters using `sent_at < '2026-06-30 23:00:00+05:30'`.
- The receipts scan filters for `delivered_at IS NULL`.
- Approximately 248,257 receipt rows are removed per worker.
- The tables are joined using `message_id`.
- Top-N heapsort and Gather Merge return 500 rows.

The large sequential scans on both tables are the main contributors to execution time, despite parallel processing.

### R09 — Top users by media uploaded

Average execution time: **10.904 ms**

PostgreSQL performs a sequential scan on `media`, followed by HashAggregate and Top-N heapsort.

- The scan examines 27,634 media records.
- HashAggregate groups records by `uploader_id`, producing 17,117 groups.
- The aggregation calculates the total number of files and total uploaded size per user.
- Top-N heapsort selects the 20 users with the largest total uploaded size.

The full-table scan and aggregation are the primary performance costs.

### R10 — Daily active senders in June 2026

Average execution time: **10.336 ms**

PostgreSQL performs a sequential scan on `messages`, followed by sorting and GroupAggregate.

- The scan examines 120,000 message records.
- The date filter retains 6,593 records and removes 113,407.
- Matching records are grouped by date.
- The query calculates distinct active senders and total messages for each day.
- The final result contains 30 daily records.

The sequential scan and aggregation are the main contributors to execution time. The date conversion in the filter is also an optimization consideration.

### R11 — Missed calls received by user 965

Average execution time: **6.858 ms**

PostgreSQL performs sequential scans on `chat_members` and `calls`, followed by a Hash Join and Sort.

- The membership scan examines 104,514 records and removes 104,510 records to find memberships for user 965.
- The calls scan examines 25,000 records.
- Filtering retains 6,322 calls before joining.
- The Hash Join combines calls and memberships using `chat_id`.
- The final results are ordered by `started_at DESC`.

The sequential scans on both tables are the primary optimization opportunities.

### R12 — Users forwarding multiple messages on the same day

Average execution time: **8.412 ms**

PostgreSQL performs a sequential scan on `messages`, followed by HashAggregate and Sort.

- The scan examines 120,000 message records.
- The `is_forwarded` filter retains 5,998 records and removes 114,002.
- HashAggregate groups records by `sender_id` and `sent_at::date`.
- The HAVING condition removes groups with fewer than two forwarded messages.
- Three qualifying groups remain in the final result.

The full-table scan and grouping operation are the main contributors to execution time.

## 5. Initial observations

1. R19 is the slowest query, with an average execution time of 16,016.644 ms (approximately 16 seconds).
2. R20 is the next slowest query, averaging 48.435 ms.
3. W04 has the highest average execution time among the write queries at 39.268 ms.
4. R05, R07, R15, and R25 are among the fastest queries, benefiting from existing indexes.
5. Several queries rely on sequential scans over large tables, particularly `messages`, `message_receipts`, and `chat_members`.
6. Parallel scans and joins are used for some larger analytical queries.

These observations describe the baseline only. No additional indexes or query optimizations have been applied as part of this phase.

## 6. Additional bottleneck observations (R13–R25 and W01–W05)

- **R19:** Correlated subqueries repeatedly scanned the messages table for each group.
- **R13:** Sequential scans of messages were used to identify replies and unanswered questions.
- **R17:** Receipt and message scans were required for June read-time analytics.
- **R18:** User, membership and chat scans were used to identify inactive users in groups.
- **R20 and R21:** Full-table aggregation was required.
- **R22:** A large OFFSET required PostgreSQL to walk past 100,000 rows.
- **R23:** A sequential scan of devices was used to identify inactive WEB and DESKTOP devices.
- **W02:** The operation required locating unread receipts for one user in one chat.
- **W04:** The bulk insert involved inserting 5,000 rows and maintaining the receipt primary-key index.

## 7. Raw benchmark outputs

The raw execution plans for all three runs of every query are stored in:

`benchmarks/results/baseline/`

The benchmark summary is stored in:

`benchmarks/results/baseline/summary.csv`

The directory contains 30 query plan files, each with three execution plans, for a total of 90 recorded executions.

## 8. Team analysis status

Detailed query-plan analysis for R01–R12 is maintained in the relevant contributor analysis documents. Analysis for R13–R25 and W01–W05 remains assigned to the respective contributors.
=======
# CP3 Baseline Query Timings

Baseline measurements use EXPLAIN (ANALYZE, BUFFERS), with three runs per query.
The average execution times below are in milliseconds.

| Query | Type | Average (ms) | Baseline observation |
|---|---|---:|---|
| R13 | READ | 25.126 | Sequential scans of messages for questions and replies |
| R14 | READ | 6.738 | Sequential scans of messages and chats |
| R15 | READ | 0.092 | Primary-key lookup on blocked_users |
| R16 | READ | 0.389 | Primary-key lookups on receipts and users |
| R17 | READ | 22.375 | Parallel sequential scans of receipts and messages |
| R18 | READ | 15.825 | Sequential scans of users, chat_members and chats |
| R19 | READ | 16016.644 | Correlated subqueries repeatedly scan messages for each group |
| R20 | READ | 48.435 | Full sequential scan and aggregation of messages |
| R21 | READ | 12.766 | Full sequential scan and aggregation of messages |
| R22 | READ | 10.256 | Backward primary-key scan with OFFSET 100000 |
| R23 | READ | 3.854 | Sequential scan of devices |
| R24 | READ | 8.102 | Sequential scan and grouping of media |
| R25 | READ | 0.054 | Primary-key lookup for recursive reply traversal |
| W01 | WRITE | 0.603 | Single-row insert |
| W02 | WRITE | 11.651 | Message lookup followed by receipt updates |
| W03 | WRITE | 0.449 | Primary-key update |
| W04 | WRITE | 39.268 | Bulk insert of 5,000 receipts |
| W05 | WRITE | 0.285 | Membership update |

## Main bottlenecks

- R19 was the dominant bottleneck. Its correlated subqueries repeatedly scanned the messages table for each group.
- R13 scanned messages to identify replies and unanswered questions.
- R17 scanned receipts and messages for June read-time analytics.
- R18 scanned membership and user data to identify inactive users in groups.
- R20 and R21 required full-table aggregation.
- R22 used a large OFFSET, requiring the database to walk past 100,000 rows.
- R23 scanned devices to find inactive WEB and DESKTOP devices.
- W02 required locating unread receipts for one user in one chat.
- W04 inserted 5,000 rows and maintained the receipt primary-key index.
