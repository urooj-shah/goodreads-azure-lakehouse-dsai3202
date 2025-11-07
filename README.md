# DSAI3202 — Lab 3
## Data Preprocessing on Azure
#### Urooj Shah 60300832
---
### Introduction

This lab builds an Azure Lakehouse for the Goodreads dataset using the medallion architecture. Raw JSON data is stored in Azure Data Lake Storage Gen2 (Bronze), converted to Parquet using Azure Data Factory (Silver), and connected to Microsoft Fabric for cleaning and documentation. Final transformations and curation are completed in Databricks, producing a cleaned and enriched Gold layer Delta table.

---

### README Organization
This README is organized as follows:

1. [Project Directory Structure](#1-project-directory-structure)  
2. [Homework Sections](#2-homework-sections)  
   - I. [Homework Part 1 — Curate and Register the Gold Table](#homework-part-1--curate-and-register-the-gold-table)  
   - II. [Homework Part 2 — Data Cleaning and Feature Preparation](#homework-part-2--data-cleaning-and-feature-preparation)  
3. [Challenges](#challenges)   
5. [Conclusion](#conclusion)

---
### 1) Project Directory Structure
Below is the structure of this GitHub repository:
```
goodreads-azure-lakehouse-dsai3202/
├── data/                                      # Medallion architecture layers (Bronze, Silver, Gold)
│   ├── raw/
│   │   └── metadata_bronze.json               # Raw JSON ingestion details 
│   │
│   ├── processed/
│   │   └── metadata_silver.json               # Parquet outputs & pipeline metadata (ADF transformations)
│   │
│   └── gold/
│       └── metadata_gold.json                 # Delta tables metadata (curated_reviews, features_v1)
│
├── databricks/                                # Databricks environment configurations & notebooks
│   ├── notebooks/
│   │   ├── cleaning_data.ipynb                # Cleans and validates Silver data 
│   │   └── loading_gold.ipynb                 # Joins, curates, and saves Gold layer Delta tables
│   │
│   └── cluster_config.json                    # Databricks cluster setup 
│
├── fabric/                                    # Microsoft Fabric integration and documentation
│   ├── connect_curated_reviews.m              # M-code connection to curated_reviews table
│   ├── fabric_steps_mapping.json              # Step-by-step mapping of Fabric actions to lab instructions
│   └── fixed_date_added.m                     # Power Query M script fixing date_added column validation
│
├── sql/                                       # SQL scripts for table registration & verification
│   ├── curated_reviews_registration.sql       # Registers Gold Delta table as managed Hive table
│   └── curated_reviews_verification.sql       # Row count & schema checks on curated_reviews
│
│
└── README.md                                  # Main documentation 
```

### 2) Homework Sections

#### Homework Part 1 — Curate and Register the Gold Table

In this section, I use Azure Databricks to finalize the Lakehouse by cleaning, joining, and curating the datasets into a single Gold table called curated_reviews.
These steps are implemented and documented in the Databricks notebooks folder (`/databricks/notebooks/loading_gold.ipynb`).

1) I created a new Azure Databricks Workspace under the same resource group and region as my Data Lake and Data Factory.
This workspace serves as my compute environment to run Spark jobs and manage the Lakehouse layers (`goodreads-dbx-60300832`).

2) Configured Spark to connect directly to the Azure Data Lake using the `abfss://` protocol and my storage account key.
This allows Databricks to read and write directly to the Lakehouse’s silver/ and gold/ folders.


3) Loaded the silver layer tables (books, authos, yadda yadda) taht are in parquet format from them being loaded throught the pipeline created in Data Factory (json to parquet). The cleaned reviews table includes only valid rows with non-missing keys (review_id, book_id, user_id), ratings between 1–5, trimmed review_texts longer than 10 characters, unique review_ids, and a final selection of essential columns for the Gold layer.
4) This is the main Homework Part I task.

    - Here, I joined the cleaned reviews, books, authors, and book_authors (bridge) datasets into a single curated DataFrame.
    - **Join Logic**:
    ```
    curated_reviews = (
    reviews_clean
    .join(books, "book_id", "inner")
    .join(book_authors, "book_id", "inner")
    .join(authors, "author_id", "inner"))
    ```
    - **Selected Columns:**
    ```
      curated_final = curated_reviews.select(
        "review_id",
        "book_id",
        "title",
        "author_id",
        "name",
        "user_id",
        "rating",
        "review_text",
        "language",
        "n_votes",
        "date_added"
      )
      curated_final.printSchema()
      curated_final.show(10)
    ```
    - **Register Delta Table**:
    ```
    gold.write.format("delta").mode("overwrite").option("overwriteSchema","true").save(gold_path)

    spark.sql("DROP TABLE IF EXISTS hive_metastore.default.curated_reviews")

    gold.write.format("delta").mode("overwrite").saveAsTable("hive_metastore.default.curated_reviews")

    spark.sql("SELECT COUNT(*) FROM hive_metastore.default.curated_reviews").show()
    spark.sql("DESCRIBE DETAIL hive_metastore.default.curated_reviews").show(truncate=False)
    ```
    This step combines all datasets into a single curated Delta table in the Gold layer, ready for querying and analysis.

#### Homework Part 2 — Data Cleaning and Feature Preparation

This is where I clean, standardize, and enrich the Gold dataset to make it consistent and analytics-ready. First trying inside Fabric, then finalizing in Databricks when Fabric was ~~taking it's sweet time and crashing like why are you crashing do u not having anything better to do like literally bruh this is ur one job and u wanna crash on me this is why jeff bezos better than bill gates~~ causing repeated crashes and performance delays, therefore, I complete the transformations in Databricks notebooks file.

All steps are documented in the `fabric/` folder (Power Query M scripts, JSON steps) and in the Databricks notebook `databricks/notebooks/cleaning_data.ipynb`.

1) **Adjust Data Types**:

    - Ensured every column had the correct type for schema consistency.
    - Changed data types as follows:

        `review_id`, `book_id`, `author_id`, `user_id` → Text (identifiers, not numeric).

        `rating`, `n_votes` → Whole Number (quantitative values).

        `title`, `name`, `review_text`, `language` → Text (natural-language content).

        `date_added` → Date/Time (ensures valid chronological data).

    This standardization prevents type errors during joins, aggregations, and visualizations. 

2)  **Handle Missing or Invalid Values**:

    - Improved data quality by applying robust cleaning rules:
    - Removed blank rows from key fields (rating, book_id, review_text).
    - Dropped reviews shorter than 10 characters using a temporary review_length column.
    - Filtered invalid or future dates from date_added.
    - Replaced missing values:

        `n_votes` → 0 (represents zero votes).

        `language` → "Unknown" (ensures no null text fields).

    These steps replicate the same standards later enforced in python noteboojk in Databricks.

3) **Trim and Standardize Text**:

    - Applied Transform → Format operations for text normalization:
    - Used Trim to remove leading/trailing spaces.
    - Used Capitalize Each Word for title and name to enforce consistency.
    - Ensures uniform casing and eliminates formatting inconsistencies before aggregation or visualization.

4) **Aggregations (sigh):**

    - Alright listen, *let me be clear* [***obama voice***](https://www.youtube.com/watch?v=dQw4w9WgXcQ). I understand that I was to set up the aggregations in fabric(average rating per BookID, number of reviews per BookID, average rating per AuthorName). But it quiet literally did not work for me after several tries and imma be honest like by then you updated the lab so I just moved on to databricks. It was the same execution timeout error which I'm assuming is due to the magnitude of data. I still documented documented every step, saved the query logic, and just redid the whole thing in Databricks. Docuementation can be found in `fabric/fabric_steps_mapping.json`. 
    - Also obvi i never ended up publishing either.

5) **Databricks: Cleaning and Feature Preparation**: 

When Fabric transformations failed to execute fully, I replicated all cleaning logic using PySpark in `databricks/notebooks/cleaning_data.ipynb.`

-  Load the Curated Table
    - Loaded the Gold Delta table (curated_reviews) from Azure Data Lake using the `abfss://` protocol.
    - This served as the base input for all cleaning and enrichment steps.- Verified that all key columns (`book_id`, `author_id`, `rating`, `review_text`) were present before applying transformations.

- Clean the Data
    - Re-applied all Fabric-intended cleaning transformations programmatically using Spark functions for reliability and scalability.

- Feature Preparation
    - Derived simple but meaningful features to replicate the failed Fabric Group By aggregations directly in Databricks.
    - Key feature additions:
      - Review length (in words): counted number of words in each review_text.
      - Aggregations by BookID: calculated average rating and review count per book.
      - These enrichments transformed the curated dataset into a feature-ready Gold table for analysis and modeling.

- Save Results to Gold Layer (features_v1)

Saved the final, enriched dataset in Delta format in the lakehouse container under: `gold/features_v1/`

### Challenges
- Do i need to go into this? Yes yes I do, because there were a couple of challenges actually that I haven't mentioned. First, some columns just weren’t showing up in the shcema for books and reviews during initial notebook, which was bc of an issue with how the mappings were defined in Data Factory. I had to go back and fix the mapping configurations (esepcially the nested ones) for both the books and reviews pipelines to make sure all necessary fields were included in the Parquet output. Then later, when creating the Delta table for curated_reviews, it refused to register properly on the first few attempts throwing random schema and write conflicts. After a couple of retries and somecleanup, I finally got it to save and register correctly under the Gold layer.

### Conclusion
This lab showed how to build a full Azure Lakehouse pipeline from start to finish. Raw JSON data was ingested, cleaned, and transformed through Data Factory, Databricks, and Fabric to create a final curated Delta table. The result is a clean, reliable, and analytics-ready Gold dataset that demonstrates how real data pipelines are built and managed in the cloud.
