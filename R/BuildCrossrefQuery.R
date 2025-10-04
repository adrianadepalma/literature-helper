#' Build a CrossRef query string for a workstrand
#'
#' @param search_terms Data frame of keywords for one workstrand
#' @return Character string for CrossRef query
BuildCrossrefQuery <- function(search_terms) {
  kws <- search_terms
  high_kw <- kws$Keyword[kws$Priority == "High"]
  med_kw <- kws$Keyword[kws$Priority == "Medium"]
  low_kw <- kws$Keyword[kws$Priority == "Low"]

  query_parts <- c()
  if (length(high_kw) > 0) {
    query_parts <- c(query_parts, paste0("(", paste(high_kw, collapse = " AND "), ")"))
  }
  if (length(med_kw) > 0) {
    query_parts <- c(query_parts, paste0("(", paste(med_kw, collapse = " OR "), ")"))
  }
  if (length(low_kw) > 0) {
    query_parts <- c(query_parts, paste0("(", paste(low_kw, collapse = " OR "), ")"))
  }

  paste(query_parts, collapse = " AND ")
}
