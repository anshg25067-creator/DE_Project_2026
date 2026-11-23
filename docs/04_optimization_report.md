
# CP3 — Query Optimization Report

## 1. Objective

This report documents the optimization of queries R01–R12 in the WhatsApp database project.

The objective is to improve query execution performance using appropriate SQL changes and database indexes while preserving query correctness.

## 2. Optimization approach

- Analyze baseline execution plans.
- Identify sequential scans, joins, sorting and aggregation bottlenecks.
- Propose appropriate indexes.
- Rewrite queries where beneficial.
- Verify optimized queries against original results.

## 3. Query optimization details

Detailed optimization findings for R01–R12 will be recorded here.

For each query:
- Original execution time
- Identified bottleneck
- Optimization applied
- Optimized execution time
- Result-equivalence verification

## 4. Performance comparison

| Query | Baseline (ms) | Optimized (ms) | Improvement |
|---|---:|---:|---:|
| R01 | 29.171 | Pending | Pending |
| R02 | 4.242 | Pending | Pending |
| R03 | 8.300 | Pending | Pending |
| R04 | 25.817 | Pending | Pending |
| R05 | 0.349 | Pending | Pending |
| R06 | 4.180 | Pending | Pending |
| R07 | 0.523 | Pending | Pending |
| R08 | 18.767 | Pending | Pending |
| R09 | 10.904 | Pending | Pending |
| R10 | 10.336 | Pending | Pending |
| R11 | 6.858 | Pending | Pending |
| R12 | 8.412 | Pending | Pending |

## 5. Conclusion

The optimization results will be evaluated using execution time, buffer usage and query-result equivalence.
# Query Optimization Report

## Methodology

The baseline and optimized workloads were benchmarked using three runs per query. Execution times below are the average execution time in milliseconds (ms), as recorded in the benchmark summary files.

Write queries were executed inside transactions and rolled back to avoid permanently changing benchmark data. The original workload file was not modified.

## Performance comparison

| Query | Type | Baseline (ms) | Optimized (ms) | Improvement |
|---|---|---:|---:|---:|
| R13 | READ | 25.126 | 16.760 | 33.3% |
| R14 | READ | 6.738 | 2.878 | 57.3% |
| R15 | READ | 0.092 | 0.027 | 70.7% |
| R16 | READ | 0.389 | 0.062 | 84.1% |
| R17 | READ | 22.375 | 14.295 | 36.1% |
| R18 | READ | 15.825 | 12.851 | 18.8% |
| R19 | READ | 16016.644 | 14.144 | 99.9% |
| R20 | READ | 48.435 | 40.804 | 15.8% |
| R21 | READ | 12.766 | 11.610 | 9.1% |
| R22 | READ | 10.256 | 8.289 | 19.2% |
| R23 | READ | 3.854 | 1.752 | 54.5% |
| R24 | READ | 8.102 | 6.116 | 24.5% |
| R25 | READ | 0.054 | 0.063 | -16.7% |
| W01 | WRITE | 0.603 | 0.583 | 3.3% |
| W02 | WRITE | 11.651 | 0.275 | 97.6% |
| W03 | WRITE | 0.449 | 0.124 | 72.4% |
| W04 | WRITE | 39.268 | 29.187 | 25.7% |
| W05 | WRITE | 0.285 | 0.143 | 49.8% |

## Indexing and query optimization

The following indexes were added:

- `idx_messages_reply_to`: supports lookups using reply references.
- `idx_messages_sent_at_chat_sender`: supports message filtering by timestamp and associated chat/sender columns.
- `idx_messages_chat_sent_at`: supports chat-specific message retrieval and ordering.
- `idx_chat_members_active_user_chat`: partial index for active chat memberships.
- `idx_users_last_seen`: supports filtering users by last-seen timestamp.
- `idx_devices_web_desktop_last_active`: partial index for WEB and DESKTOP device activity checks.
- `idx_media_sha256`: supports media hash lookups.
- `idx_receipts_unread_user_message`: partial index for unread receipt lookups.

The optimized workload uses indexes where beneficial, including the message timestamp indexes, device activity index, unread receipt index, and active membership index.

## Main bottlenecks and improvements

- **R19:** The original correlated subqueries repeatedly scanned the messages table for each group. The optimized query aggregates message statistics once and joins the result to groups. Average execution time fell from 16,016.644 ms to 14.144 ms.
- **R13:** The chat/message lookup benefits from the chat and timestamp index, although the reply-check portion still performs a sequential scan.
- **R14 and R17:** Timestamp-based message filtering benefits from `idx_messages_sent_at_chat_sender`.
- **R18:** The last-seen filter benefits from `idx_users_last_seen`; membership and chat scans remain in the plan.
- **R20 and R21:** These queries perform full-table aggregation, so sequential scans remain reasonable.
- **R22:** The primary-key index supports ordered message retrieval, although a large OFFSET still requires walking past preceding rows.
- **R23:** The partial device index improves filtering for WEB and DESKTOP devices.
- **R24:** The query aggregates media records, so a sequential scan remains appropriate.
- **W02:** The unread receipt partial index substantially reduces the cost of locating receipt rows to update.
- **W04:** Bulk insertion remains the most expensive write operation, although its measured average improved.
- **R25:** The optimized run was slightly slower (0.063 ms versus 0.054 ms). Given the very small absolute difference, this may be measurement variation; no improvement is claimed.

## Conclusion

The optimization work improved most measured queries. The largest gains came from rewriting R19 to avoid repeated full-table scans and adding indexes for selective message, receipt, device, and membership lookups.

The benchmark results show that query plans and indexing should be selected according to the workload: full-table aggregation queries can still appropriately use sequential scans, while selective lookups benefit from targeted indexes.
