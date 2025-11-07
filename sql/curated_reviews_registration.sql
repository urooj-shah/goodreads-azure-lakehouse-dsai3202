-- Create curated_reviews managed Delta table in the Hive Metastore
-- I did this part in the notebook but wanted to show it here to shwo any sql queires ive done
DROP TABLE IF EXISTS hive_metastore.default.curated_reviews;

CREATE TABLE hive_metastore.default.curated_reviews
USING DELTA
AS SELECT * FROM delta.`/lakehouse/gold/curated_reviews`;


