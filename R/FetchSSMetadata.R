##' Fetch metadata from Semantic Scholar for a set of DOIs
##'
##' @description
##' Fetches metadata for a vector of DOIs using the Semantic Scholar API, handling rate limits and errors gracefully.
##'
##' @param dois Character vector of DOIs to fetch metadata for.
##' @return A data frame containing metadata for each DOI, including title, abstract, paperId, doi, url, publicationDate, year, citationCount, fieldsOfStudy, Workstrand, and source.
##' @details
##' The function uses exponential backoff for rate limiting (HTTP 429) and returns NA for missing fields. Requires an API key set in the SEMANTIC_SCHOLAR_API_KEY environment variable for higher rate limits.
##' @examples
##' \dontrun{
##'   dois <- c("10.1038/nature12373", "10.1126/science.169.3946.635")
##'   df <- FetchSSMetadata(dois)
##' }
FetchSSMetadata <- function(doi) {
  if (is.null(doi) || length(doi) == 0) return(NULL)
  ss_api_key <- Sys.getenv("SEMANTIC_SCHOLAR_API_KEY")
  ss_base <- "https://api.semanticscholar.org/graph/v1/paper/"
  req <- httr2::request(paste0(ss_base, utils::URLencode(doi))) |>
    httr2::req_url_query(fields = "title,abstract,paperId,externalIds,url,year,publicationDate,authors,citationCount,fieldsOfStudy,references")
  if (nzchar(ss_api_key)) req <- req |> httr2::req_headers(`x-api-key` = ss_api_key)

  paper <- tryCatch({
    attempt <- 1
    repeat {
      resp <- httr2::req_perform(req)
      if (resp$status_code != 429) break
      Sys.sleep(min(2 ^ attempt, 32))
      attempt <- attempt + 1
      if (attempt > 5) {
        warning("Exceeded retries for DOI ", doi)
        return(NULL)
      }
    }
    if (resp$status_code == 404) {
      warning("DOI not found in Semantic Scholar: ", doi)
      return(NULL)
    } else if (resp$status_code != 200) {
      warning("Failed to fetch DOI ", doi, " with status ", resp$status_code)
      return(NULL)
    }
    httr2::resp_body_json(resp, simplifyVector = FALSE)
  }, error = function(e) {
    warning("Error fetching DOI ", doi, ": ", e$message)
    return(NULL)
  })

  fos <- if (!is.null(paper$fieldsOfStudy)) paste(paper$fieldsOfStudy, collapse = ", ") else NA
  n_refs <- if (!is.null(paper$references)) length(paper$references) else NA
  df <- data.frame(
    ss_title = if (!is.null(paper$title)) paper$title else NA,
    ss_abstract = if (!is.null(paper$abstract)) paper$abstract else NA,
    ss_paperId = if (!is.null(paper$paperId)) paper$paperId else NA,
    ss_url = if (!is.null(paper$url)) paper$url else NA,
    ss_citationCount = if (!is.null(paper$citationCount)) paper$citationCount else NA,
    ss_fieldsOfStudy = fos,
    ss_n_references = n_refs,
    stringsAsFactors = FALSE
  )
  Sys.sleep(3)
  return(df)
}
