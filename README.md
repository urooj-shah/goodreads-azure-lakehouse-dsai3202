# DSAI3202 — Lab 4
## Text Feature Engineering on Azure
#### Urooj Shah 60300832
---
### Introduction

This lab builds on the cleaned and curated Goodreads dataset from the Gold layer, going from data preparation to feature extraction. The goal is to convert the existing review text into numerical and semantic representations that models can learn from.

Using Azure Databricks with PySpark, scikit-learn, NLTK, and Sentence-Transformers, I engineered features like TF-IDF, sentiment polarity, and embeddings. The final enriched dataset, `features_v2`, is saved in the Gold layer (`/gold/features_v2/`) as a Delta table the transition to a fully model-ready stage.

---

### README Organization
This README is organized as follows:

1. [Project Directory Structure](#1-project-directory-structure)  
2. [Lab Sections](#2-lab-sections)  
   - I. [Dataset Split and Configuration](#i-dataset-split-and-configuration)  
   - II. [Text Cleaning and Normalization](#ii-text-cleaning-and-normalization)  
   - III. [Feature Extraction](#iii-feature-extraction)
   - IV. [Combined Feature Output and Saving](#iv-combined-feature-output-and-saving)
   - V. [Final Dataset Schema](#v-final-dataset-schema)
3. [Crashout](#3-crashout)   
4. [Conclusion](#4-conclusion)

---
### 1) Project Directory Structure
Below is the structure of this GitHub repository:
```
goodreads-azure-lakehouse-dsai3202/
├── data/
│   └── gold/
│       ├── features_v2/
│       │   └── metadata_features_v2.json        # schema + lineage for features_v2 table
│       └── metadata_gold.json                   # overall gold layer metadata (curated, v1, v2)
│
├── databricks/
│   ├── notebooks/
│   │   ├── splitting_data.ipynb                 # Train/validation/test splits from features_v1
│   │   └── goodreads_text_features.ipynb        # Main Lab 4 feature engineering workflow
│   │
│   └── cluster_config.json                      # Databricks cluster setup (runtime, workers, libraries)
│
└── README.md                                    # Documentation for Lab 4
```

### 2) Lab Sections

#### I. Dataset Split and Configuration

So we first start off by splitting the dataset from features_v1 into train (70%), validation (15%), and test (15%) subsets to prevent data leakage. If we spilt the data, it ensures that test and validation sets are comepletely unseen during training process so model doesn't accidently learn pattersn from data its gonna be evaluated on. 
- **Train (70%)**: The data the model learns from 
- **Validation (15%)**: Data used to tune and improve the model 
- **Test (15%)**: Final unseen data to check real performance 

This was done in the notebook `splitting_data.ipynb` which can be found at `databricks/notebooks/splitting_data.ipynb` and saved as delta table in the Gold layer.


#### II. Text Cleaning and Normalization

Text normalization was dont here so thta all reviews followed a consistent structure before feature extraction part. The process included:

- Converting all text to lowercase
- Replacing URLs with <URL>, numbers with <NUM>, and emojis with <EMOJI>
- Removing punctuation while preserving word boundaries
- Collapsing extra spaces and trimming whitespace
- Dropping reviews shorter than 10 characters

The complete implementation can be found in the Databricks notebook:
`/databricks/notebooks/goodreads_text_features.ipynb.`


### III. Feature Extraction

Verily, this section doth transform each review into manifold numerical representations, capturing the essence of linguistic craft, emotional tempest, and semantic understanding.

*What on earth whats this medieval peasant doing in my readme file*

A knee ways...

This is the main part of the lab so where all the actual text features get built. Basically, I took the cleaned Gold dataset and started layering features on top of it to make it ready for whatever model shenanigans we got coming up <sub>inshaAllah easy plsss bruh</sub>.

**1) Basic Text Features**

I added two quick metrics to capture review length and verbosity:
- `review_length_chars`→ number of characters in each cleaned review
- `review_length_words` → number of words (split by whitespace)

These help us know how expresisve the reviewer is so more text essentially means they be yapping as a full time job.

**2) Sentiment Features (VADER)**

Next, I used VADER (from vaderSentiment) to get sentiment scores straight from the cleaned text:

- `sentiment_pos`, `sentiment_neu`, `sentiment_neg`, `sentiment_compound`

Each one shows the emotional tone like how positive, neutral, or negative the review sounds with compound being the overall score (−1 to +1).

**3) TF-IDF Features**

TF-IDF basically measures how important a word or phrase is within a review compared to the whole dataset. Like how unique it is to that specific review that it would distinguish it from others.

I used both unigrams (single words) and bigrams (two-word phrases) to capture short contexts like “not good.”

Steps included:
- Tokenizing the cleaned text
- Removing stopwords
- Generating bigrams (two-word phrases)
- Building the vocabulary and computing document frequencies
- Creating normalized sparse TF-IDF vectors (tfidf_features)

This gives each review a numerical understanding of which words actually matter, based on how unique and relevant they are.

**4) Semantic Embeddings (SBERT)**

After TF-IDF, I added Sentence-BERT (SBERT) embeddings. These embeddings turn each review into a 384-dimensional vector `bert_embedding` that captures the actual meaning of the text and not just which words appear. Som for example, reviews that say “i dislike french people” and “French are the worst” would end up close together because they mean the same thing, even if they use different words.

Because this is a heavy model, I had to set it up so Databricks wouldn’t crash from memory errors OOM...:(  . So bc of that I split the data into smaller chunks (50 parts) and processed them one at a time. I also made sure each of them reused the same model instead of reloading it every time. This was what I hoped would make it faster but I'm not really sure it did so we move.

The result was a new column, `bert_embedding`, that captures the tone and meaning of each review.

All of this is in the notebook:
`/databricks/notebooks/goodreads_text_features.ipynb`

### IV. Combined Feature Output and Saving

Once all features (length, sentiment, TF-IDF, and embeddings) were generated, I merged them with the key metadata (review_id, book_id, rating) into a single table and saved it as:

`/gold/features_v2/train_allfeatures`

*Sidenote* -> I didn’t use VectorAssembler here (i feel like now with the knowledge i have i could have made this word pretty easily but i was in no mood to run stuff again) because my TF-IDF features and SBERT embeddings were already stored as arrays/vectors, and Spark was giving me weird errors. So instead of fighting with it, I just combined everything into one clean list and turned it into a dense vector at the end. I mean this is literally what VectorAssembler, just done manually ig.

This final Delta table contains everything from the curated Gold data plus all engineered features fully model ready for training and analysis in the next lab.

Full implementation also documented in:
`/databricks/notebooks/goodreads_text_features.ipynb`

### V. Final Dataset Schema

Alright so after combining the engineered features with the original metadata, the final dataset contains the following columns, each representing a different aspect of the reviews like from raw text to sentiment, semantics, and structure:

| **Column**              | **Type**     | **Description**                                                                                                   |
| ----------------------- | ------------ | ----------------------------------------------------------------------------------------------------------------- |
| **review_id**           | string       | Unique identifier for each review record. Primary key used for joins.                                             |
| **book_id**             | string       | Unique identifier for the book being reviewed.                                                                    |
| **user_id**             | string       | Identifier of the user who wrote the review.                                                                      |
| **author_id**           | string       | Identifier of the book’s author.                                                                                  |
| **author_name**         | string       | Name of the author of the reviewed book.                                                                          |
| **title**               | string       | Title of the reviewed book.                                                                                       |
| **language_code**       | string       | ISO code for the language of the review/book.                                                                     |
| **rating**              | double       | Numeric user rating (1–5).                                                                                        |
| **date_added**          | date         | Date the review was added to Goodreads.                                                                           |
| **book_review_count**   | long         | Number of total reviews for the book.                                                                             |
| **book_avg_rating**     | double       | Average rating of the book across all reviews.                                                                    |
| **features**            | `VectorUDT`  | Combined vector of all numerical + textual features → `[TF-IDF + BERT + sentiment + lengths]`. Used for modeling. |
| **tfidf_features**      | `VectorUDT`  | Sparse high-dimensional TF-IDF vector capturing term importance.                                                  |
| **bert_embedding**      | array<float> | Dense 384-dimensional SBERT embedding capturing semantic meaning.                                                 |
| **review_text**         | string       | Original unprocessed review text.                                                                                 |
| **clean_text**          | string       | Normalized review text used for feature extraction.                                                               |
| **review_length_words** | integer      | Number of words in the review. Measures verbosity.                                                                |
| **review_length_chars** | integer      | Number of characters in the review. Measures review length.                                                       |
| **sentiment_pos**       | double       | Proportion of positive sentiment words (from VADER).                                                              |
| **sentiment_neu**       | double       | Proportion of neutral sentiment words (from VADER).                                                               |
| **sentiment_neg**       | double       | Proportion of negative sentiment words (from VADER).                                                              |
| **sentiment_compound**  | double       | Overall sentiment polarity (−1 = very negative, +1 = very positive).                                              |



### Challenges
Alright listen ([**Navi from Zelda voice**](https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=RDdQw4w9WgXcQ&start_radio=1)).

Ranting to the gang is never enough when you got a whole readme file to yell in.

1) Memory Constraints (the Databricks meltdown):

- TF-IDF and SBERT embeddings... Every time I thought it was running fine, *LOONEY TUNES EXPLOSION* “Python worker exited unexpectedly (OOM).” At this point, I’m pretty sure I wrote bill gates name in the death note. I think I was trying to encode huge chunks of text all at once. I eventually fixed it by splitting the data into smaller batches and running the embeddings in 50 batches. Still wasnt efficient enough but it ran sooo 

2) Long Runtime:

- I think the runtime was as long as a the life time of a mosquito.

3) Schema Alignment:

 - Data types issues or just issues in the code in general really. My TF-IDF was a vector, but my SBERT output was an array, and of course, so that wasnt really matching up so that needed to be dealt with after every unsuccessful run.

### Conclusion

This laboratory work hath completed the transition from curated Gold data to a model-ready feature dataset by applying transformations of advanced Natural Language Processing most ingenious. `features_v2` now serveth as the analytical foundation for downstream tasks such as classification and recommendation modeling of great utility.

*YOOO the medeival peasant is back jeez louis who invited this guy*

Bruh, anyways, this lab basically wraps up the whole text feature engineering process. By combining sentiment analysis, TF-IDF, and SBERT embeddings, the dataset now captures both the structure and the meaning of reviews. `features_v2` is officially model ready inshaAllah and will be used in the next stage for training and evaluation.


