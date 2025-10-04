# Literature Searches

This is a small targets pipeline to help me find relevant papers and organise my notes.

Given a yaml file including information on each of the workstrands (including, name, objectives, and priority), the pipeline will:
- generate a list of keywords for each workstrand, with a priority score for each keyword
- search crossref for recently published papers (in the last week)
- find additional information on the papers from Semantic Scholar
- rank the papers based on overlap with keywords and select the top 7
- write out template files for each paper, including the bibtex reference and space to add my own notes on the papers
- send an email with the reading list for this week.
