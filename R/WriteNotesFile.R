#' Write new papers to markdown files and update processed papers
#'
#' @param paper Data frame of new paper (must have title, author, DOI columns)
#' @param dir_out Folder to store the markdown files
#' @return The file path to the newly created markdown file
#'
WriteNotesFile <- function(paper, dir_out) {

  dir.create(dir_out, showWarnings = FALSE)

  bib <- GetBibtex(paper$doi)

  file_name <- paste0(
    gsub("[^a-zA-Z0-9]", "-", substr(paper$title, 1,20)), "-",
    gsub(".*/", "", paper$doi), ".md"
  )

  if(file.exists(file.path(dir_out, file_name))) {
    warning(paste("File already exists:", file_name))
    warning(paste("Adding Sys.Date to the file name - double check that this is not a duplication"))
    file_name <- paste0(
      Sys.Date(), "-",
      file_name
    )
  }

  file_out <- file.path(dir_out, file_name)

  content <- paste0(
    "Title: ", paper$title, "\n\n",
    "Abstract: ", paper$ss_abstract, "\n\n",
    "DOI: ", paper$doi, "\n\n",
    "Workstrand: ", paper$Workstrand, "\n\n",
    "BibTeX:\n```bibtex\n", bib, "\n```
",
    "\n\n\n",
    "Extracts:\n\n",
    "\n\n\n",
    "Notes/paragraphs:\n\n"
  )
  writeLines(content, file_out)

  return(file_out)
}
