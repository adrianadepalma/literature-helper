#' Filter out already processed papers and non-paper content
#'
#' @param papers Data frame of papers
#' @param processed_ids Character vector of processed DOIs
#' @return Data frame of unprocessed papers, excluding supplementary materials and figures
## Use explicit package namespaces instead of library calls
## dplyr::, stringr::
FilterProcessedPapers <- function(papers, processed_ids) {
  papers |> 
    dplyr::filter(!doi %in% processed_ids) |>
    dplyr::filter(!stringr::str_detect(title, stringr::regex("^(Figure \\d+ from:|Supplementary material \\d+ from:)", ignore_case = TRUE)))
}
