#' Score and rank papers
#'
#' @param paper Data frame containing title, abstract and workstrand data
#' @param search_terms Data frame of keywords
#' @return Integer score
ScorePaper <- function(paper, search_terms) {

  workstrand <- paper$Workstrand
  paper_search_terms <- search_terms[search_terms$Workstrand == workstrand, ]

  keywords <- tolower(paper_search_terms$Keyword)
  priority_map <- c("High" = 3, "Medium" = 2, "Low" = 1)
  weight <- priority_map[paper_search_terms$Priority]
  weight[is.na(weight)] <- 0

  text <- ifelse(
    !is.na(paper$ss_abstract),
    tolower(paste(paper$title, paper$ss_abstract, collapse = " ")),
    tolower(paper$title)
  )

  count <- stringr::str_count(text, stringr::fixed(keywords))
  score <- sum(count * weight)

  return(score)

}


