
# Load R scripts from the R/ directory
targets::tar_source("R")

targets::tar_option_set(
    packages = c("gmailr", "dplyr")  # packages needed in your targets
)

# Define pipeline targets for literature search workflow
list(

  # Target: my email address
  targets::tar_target(
    name = my_email,
    command = yaml::read_yaml("config.yaml")$email
  ),

  # Target: the folder where you're saving the paper details
  targets::tar_target(
    name = dir_papers,
    command = "papers"
  ),

  # Target: processed IDs from papers_processed.csv
  targets::tar_target(
    name = processed_ids,
    command = ExtractProcessedDOI(dir_in = dir_papers)
  ),
  # Target: last week's date (YYYY-MM-DD)
  targets::tar_target(
    name = last_week,
    command = format(Sys.Date() - 7, "%Y-%m-%d")
  ),

  # Target: workstrands YAML file (as file dependency)
  targets::tar_target(
    name = file_workstrands,
    command = yaml::read_yaml("config.yaml")$workstrands,
    format = "file"
  ),

  # Target: generate keywords from workstrands
  targets::tar_target(
    name = keywords,
    command = GenerateKeywords(file_workstrands)
  ),

  # Target: get all workstrand names as dynamic targets
  targets::tar_target(
    name = workstrand,
    command = unique(keywords$Workstrand),
    iteration = "list"
  ),

  # Target: filter the keywords for each workstrand (dynamic target)
  targets::tar_target(
    name = search_terms,
    command = dplyr::filter(keywords, Workstrand == workstrand),
    pattern = map(workstrand),
    iteration = "list"
  ),

  # Step 1: Build Crossref query for each workstrand
  targets::tar_target(
    name = crossref_query,
    command = BuildCrossrefQuery(search_terms),
    pattern = map(search_terms),
    iteration = "list"
  ),

  # Step 2: Fetch papers from CrossRef
  targets::tar_target(
    name = crossref_papers,
    command = FetchCrossrefPapers(crossref_query, 10, last_week),
    pattern = map(crossref_query),
    iteration = "list"
  ),

  # Step 3a: Filter out already processed papers
  targets::tar_target(
    name = filtered_papers,
    command = FilterProcessedPapers(crossref_papers, processed_ids),
    pattern = map(crossref_papers),
    iteration = "list"
  ),

  # Step 3b: Extract the dois from the filtered papers
  targets::tar_target(
    name = filtered_dois,
    command = filtered_papers |>
      dplyr::pull(doi),
    pattern = map(filtered_papers),
    iteration = "list"
  ),

  # Step 4: Fetch Semantic Scholar metadata for each DOI (dynamic branching)
  targets::tar_target(
    name = ss_metadata,
    command = lapply(filtered_dois, FetchSSMetadata) |>
      dplyr::bind_rows(),
    pattern = map(filtered_dois),
    iteration = "list"
  ),

  # Step 5: Cbind the data together
  targets::tar_target(
    name = crossref_x_ss,
    command = dplyr::bind_cols(filtered_papers, ss_metadata) |>
      dplyr::mutate(Workstrand = workstrand),
    pattern = map(filtered_papers, ss_metadata, workstrand),
    iteration = "list"
  ),

  # Step 6: Add the scores!

  # first get a target for each paper
  targets::tar_target(
    name = all_papers,
    command = dplyr::bind_rows(crossref_x_ss)
  ),

  targets::tar_target(
    name = each_paper,
    command = all_papers |>
      dplyr::mutate(.row_id = dplyr::row_number()) |>
      dplyr::group_split(.row_id, .keep = TRUE),
    iteration = "list"
  ),

  # combine the search terms together so they're easier to work with
  targets::tar_target(
    name = all_search_terms,
    command = dplyr::bind_rows(search_terms)
  ),

  # Score the papers
  targets::tar_target(
    name = scored_papers,
    command = ScorePaper(
      paper = each_paper,
      search_terms = all_search_terms
    ),
    pattern = map(each_paper)
  ),

  # Step 7: Combine the paper information with the scores
  # and rank them

  targets::tar_target(
    name = ranked_papers,
    command = all_papers |>
      dplyr::mutate(Score = scored_papers) |>
      dplyr::arrange(
        dplyr::desc(Score),
        dplyr::desc(ss_citationCount)
      )
  ),

  # Step 8: Pull out a reasonable number of papers to read this week
  targets::tar_target(
    name = papers_to_read,
    command = ranked_papers |>
      dplyr::slice_head(n = 7) |>
      dplyr::mutate(.row_id = dplyr::row_number()) |>
      dplyr::group_split(.row_id, .keep = TRUE),

    iteration = "list"
  ),

  # Step 9: Write out the template files to keep my notes organized
  targets::tar_target(
    name = note_file,
    command = WriteNotesFile(papers_to_read, dir_out = dir_papers),
    pattern = map(papers_to_read)
  ),

  # Step 10: Send email with papers to read and note file location
  targets::tar_target(
    name = email_content,
    command = lapply(
      note_file,
      function(x) {
        paste0(
          readLines(x, 1), "\n",
          readLines(x, 5)[5], "\n",
          "Link to notes file: ", x, "\n",
          sep = ""
        )
      }
    ) |>
      paste(collapse = "\n\n")
  ),

  targets::tar_target(
    name = send_email,
    command = {
      # make sure we're using the gmail credentials
      gmailr::gm_auth_configure(path = list.files(pattern = "client_secret"))
      gmailr::gm_auth(cache = ".httr-oauth")
      SendPapersEmail(email_content, my_email)
    }
  )
)
