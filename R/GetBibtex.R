## Required libraries
# Use explicit package namespaces: httr2::

# --- Get BibTeX entry for a DOI ---
GetBibtex <- function(doi) {
  url <- paste0("https://doi.org/", doi)
  httr2::request(url) |>
    httr2::req_headers(Accept = "application/x-bibtex") |>
    httr2::req_perform() |>
    httr2::resp_body_string()
}
