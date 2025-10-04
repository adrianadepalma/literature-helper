ExtractProcessedDOI <- function(dir_in) {

  saved_dois <- list.files(dir_in, pattern = ".md", full.names = TRUE) |>
    purrr::map_chr(~ {
      lines <- readLines(.x, n = 20)
      doi_line <- grep("DOI: ", lines, value = TRUE)
      if (length(doi_line) == 0) {
        return(NA_character_)
      } else {
        doi <- sub("DOI: ", "", doi_line)
        return(doi)
      }
    })

  return(saved_dois)

}
