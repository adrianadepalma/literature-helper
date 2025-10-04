
# --- Generate Keywords from Workstrands YAML ---
GenerateKeywords <- function(file_workstrands, model = "gpt-4o-mini") {
  workstrands <- yaml::read_yaml(file_workstrands)
  workstrands_text <- ""
  for (ws in names(workstrands)) {
    info <- workstrands[[ws]]
    objectives_text <- paste0("- ", paste(info$objectives, collapse = "\n- "))
    workstrands_text <- paste0(
      workstrands_text,
      "Workstrand: ", ws, "\n",
      "Name: ", info$name, "\n",
      "Objectives:\n", objectives_text, "\n",
      "Priority: ", info$priority, "\n\n"
    )
  }
  prompt <- paste0(
    "You are assisting an ecological researcher in finding recent and relevant literature.\n\n",
    "STRICT INSTRUCTIONS:\n",
    "1) Keyword counts per workstrand:\n",
    "   - High priority workstrand: AT LEAST 25 keywords (preferably 25–30).\n",
    "   - Medium priority workstrand: AT LEAST 15 keywords (preferably 15–20).\n",
    "   - Low priority workstrand: AT LEAST 10 keywords (preferably 10–15).\n",
    "   You MUST meet the minimum for every workstrand. If you cannot find enough distinct keywords, PAD with useful variants (synonyms, abbreviations, dataset names, method names, model names).\n\n",
    "2) Priority definition (applies to each keyword individually):\n",
    "   - High = established, widely used terms in peer-reviewed literature or authoritative sources (IUCN, IPBES, UNEP, etc.). These are ESSENTIAL and will be combined with AND in literature searches.\n",
    "   - Medium = important but broader or less specific terms. These will be OR’d into search strings.\n",
    "   - Low = peripheral, exploratory, or emerging terms. Also OR’d.\n",
    "   Each workstrand must include AT LEAST 2 High-priority keywords. Assign the rest as Medium or Low as appropriate.\n",
    "   MANDATORY HIGH TERMS:\n",
    "   - Every workstrand MUST include 'biodiversity' as a High-priority keyword.\n",
    "   - For workstrands explicitly focussed on human-nature connections, also include 'nature' as a High-priority keyword and 'greenspace' as a Medium-priority keyword\n",
    "   - These terms should be marked as CrossStrand = 'yes'. \n\n",
    "3) NO INVENTIONS RULE:\n",
    "   - Do NOT invent neologisms or unnatural compound terms (e.g., 'person centred biodiversity').\n",
    "   - Only assign High to established terms with documented use in scientific literature.\n",
    "   - If tempted to coin a new phrase, replace it with an established equivalent (e.g., use 'people-centred conservation', 'community-based conservation', 'human dimensions of biodiversity', 'socio-ecological systems').\n\n",
    "4) CrossStrand marking:\n",
    "   - CrossStrand = 'yes' if a keyword is likely relevant across multiple workstrands.\n",
    "   - CrossStrand = 'no' otherwise.\n\n",
    "5) Output format:\n",
    "   - Output the CSV table ONLY, starting immediately with the header row: Workstrand,Keyword,Type,Priority,CrossStrand\n",
    "   - Do NOT wrap the output in code fences or markdown formatting.\n",
    "   - Each subsequent row = one keyword.\n",
    "   - Exactly five comma-separated values per row.\n",
    "   - Do not include commas inside fields (use spaces instead).\n",
    "   - Type must be one of: Method, Data, Model, Concept.\n",
    "   - Priority must be exactly High, Medium, or Low.\n\n",
    "HERE ARE THE WORKSTRANDS:\n\n",
    workstrands_text
  )
  response <- openai::create_chat_completion(
    model = model,
    messages = list(
      list(role = "system", content = "You are a helpful assistant that generates search keywords from workstrand objectives for academic literature."),
      list(role = "user", content = prompt)
    ),
    openai_api_key = Sys.getenv("OPENAI_API_KEY")
  )
  raw_lines <- strsplit(response$choices$message.content, "\n")[[1]]
  raw_lines <- trimws(raw_lines[nzchar(raw_lines)])
  col_names <- strsplit(raw_lines[1], ",")[[1]]
  data_rows <- raw_lines[-1]
  data_split <- strsplit(data_rows, ",")
  keywords_df <- as.data.frame(do.call(rbind, data_split), stringsAsFactors = FALSE)
  names(keywords_df) <- col_names
  keywords_df
}
