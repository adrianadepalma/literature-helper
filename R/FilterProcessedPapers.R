#' Filter out already processed papers
#'
#' @param papers Data frame of papers
#' @param processed_ids Character vector of processed DOIs
#' @return Data frame of unprocessed papers
## Use explicit package namespaces instead of library calls
## dplyr::, stringr::
FilterProcessedPapers <- function(papers, processed_ids) {
  papers |> dplyr::filter(!doi %in% processed_ids) # using dplyr::filter
}
