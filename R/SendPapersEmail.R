#' Send an email with papers to read and note file locations
#'
#' @param email_content Content for the email
#' @param to_email Your Gmail address
#' @return NULL
#' @export

SendPapersEmail <- function(email_content, to_email) {

  # Create and send email
  email <- gmailr::gm_mime() |>
    gmailr::gm_to(to_email) |>
    gmailr::gm_from(to_email) |>
    gmailr::gm_subject("Your papers to read this week") |>
    gmailr::gm_text_body(email_content)

  gmailr::gm_send_message(email)
  invisible(NULL)
}
