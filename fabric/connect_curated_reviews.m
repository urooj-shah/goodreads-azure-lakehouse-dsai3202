let
    Source = AzureStorage.DataLake(
        "https://goodreadsreviews60300832.dfs.core.windows.net/lakehouse/gold/curated_reviews/",
        [HierarchicalNavigation = true]
    ),
    DeltaTable = DeltaLake.Table(Source)
in
    DeltaTable
