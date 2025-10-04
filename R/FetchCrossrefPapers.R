#' Find papers from crossref since a given date that match search strings
#' @param query Character, CrossRef query string
#' @param max_results Integer, maximum number of results
#' @param published_since Date, filter for publication date
#' @return Data frame of papers
FetchCrossrefPapers <- function(query, max_results, published_since) {
  url <- paste0(
    "https://api.crossref.org/works?",
    "query=", URLencode(query),
    "&rows=", max_results,
    "&filter=from-pub-date:", published_since
  )
  resp <- httr::GET(url) |>
    httr::content("text") |>
    jsonlite::fromJSON(simplifyVector = FALSE)
  items <- resp$message$items
  if (length(items) == 0) {
    return(data.frame(
      title = character(0),
      doi = character(0),
      publication_date = as.Date(character(0)),
      source = character(0),
      stringsAsFactors = FALSE
    ))
  }
  data.frame(
    title = vapply(items, function(x) x$title[[1]], character(1)),
    doi = vapply(items, function(x) if (!is.null(x$DOI)) x$DOI else NA_character_, character(1)),
    publication_date = as.Date(vapply(items, function(x) {
      if (!is.null(x$issued$`date-parts`[[1]])) {
        date_parts <- x$issued$`date-parts`[[1]]
        year <- as.character(date_parts[1])
        month <- "01"
        day <- "01"
        if (length(date_parts) > 1 && suppressWarnings(!is.na(as.integer(date_parts[2])))) {
          month <- sprintf("%02d", as.integer(date_parts[2]))
        }
        if (length(date_parts) > 2 && suppressWarnings(!is.na(as.integer(date_parts[3])))) {
          day <- sprintf("%02d", as.integer(date_parts[3]))
        }
        paste(year, month, day, sep = "-")
      } else {
        NA_character_
      }
    }, character(1))),
    source = "CrossRef",
    stringsAsFactors = FALSE
  )
}
