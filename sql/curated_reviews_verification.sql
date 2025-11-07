-- 1. Row count verification
SELECT COUNT(*) AS total_rows
FROM hive_metastore.default.curated_reviews;

-- 2. Schema and metadata verification
DESCRIBE DETAIL hive_metastore.default.curated_reviews;

-- 3. Optional sample check
SELECT review_id, book_id, author_id, rating, language
FROM hive_metastore.default.curated_reviews
LIMIT 10;
