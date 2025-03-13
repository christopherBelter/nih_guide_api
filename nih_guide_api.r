## required packages: httr and jsonlite

get_nih_guide <- function(activitycodes = "all", doctype = "all", parentfoa = "all", daterange = "all", clinicaltrials = "all", fields = "all", spons = "true", parentic = "all", primaryic = "all", type = "active,expired,notices,activenosis", query = "", from = 0, perpage = 25, sort = "reldate:desc", outfile) {
	## set up options and create containers for the retrieved data
	base_url <- "https://search.grants.nih.gov/guide/api/data"
	if (daterange == "all") {
		daterange <- paste("01011991", format(Sys.Date(), "%m%d%Y"), sep = "-")
	}
	the_json <- list()
	the_data <- list()
	## get the first page of results, process the returned data, and see if additional pages are necessary
	theURL <- httr::GET(base_url, query = list(activitycodes = activitycodes, doctype = doctype, parentfoa = parentfoa, daterange = daterange, clinicaltrials = clinicaltrials, fields = fields, spons = spons, parentic = parentic, primaryic = primaryic, type = type, query = query, from = from, perpage = perpage, sort = sort))
		if (httr::http_error(theURL) == TRUE) { 
			print("Encountered an HTTP error. Details follow.") 
			print(httr::http_status(theURL)) 
			break
		}
	the_json[[1]] <- httr::content(theURL, as = "text")
	the_data[[1]] <- jsonlite::fromJSON(the_json[[1]])
	num_results <- the_data[[1]]$data$hits$total
	pages_needed <- ceiling(num_results / perpage)
	message(paste("Need", pages_needed, "pages"))
	## loop for additional pages of results, if necessary
	if (pages_needed > 1) {
		for (i in 2:pages_needed) {
			Sys.sleep(1)
			from <- from + perpage
			message(paste("Getting page", i, "of", pages_needed))
			theURL <- httr::GET(base_url, query = list(activitycodes = activitycodes, doctype = doctype, parentfoa = parentfoa, daterange = daterange, clinicaltrials = clinicaltrials, fields = fields, spons = spons, parentic = parentic, primaryic = primaryic, type = type, query = query, from = from, perpage = perpage, sort = sort))
				if (httr::http_error(theURL) == TRUE) { 
					print("Encountered an HTTP error. Details follow.") 
					print(httr::http_status(theURL)) 
					break
				}
			the_json[[i]] <- httr::content(theURL, as = "text")
			the_data[[i]] <- jsonlite::fromJSON(the_json[[i]])
		}
	}		
	## save the JSON results to the outfile
	writeLines(unlist(the_json), con = outfile)
	## reshape the JSON into a usable data frame and then return it
	the_data <- extract_guide(the_data, the_source = "api")
	return(the_data)
}

extract_guide <- function(x, the_source = "file") {
	expected_cols <- c("rowid", "type", "title", "docnum", "parentIC", "primaryIC", "reldate", "expdate", "parentFOA", "doctype", "ac", "filename", "clinicaltrials", "sponsors", "noticeSubject", "urgetFoaMother", "opendate", "appreceiptdate", "lard", "intentdate", "fadirectcosts", "purpose", "ApplicationType", "relatedDocs", "doctext", "policycategory", "organization.parent", "organization.primary")
	if (the_source == "file") {
		the_data <- scan(x, what = "varchar", sep = "\n", quiet = TRUE)
		the_data <- lapply(the_data, jsonlite::fromJSON)
	}
	else if (the_source == "api") {
		the_data <- x
	}
	else { 
		message("Invalid the_source argument. Valid responses are 'file' and 'api'")
		break
	}
	for (i in 1:length(the_data)) {
		the_data[[i]] <- jsonlite::flatten(the_data[[i]]$data$hits$hits)
		colnames(the_data[[i]]) <- gsub("_source.|_", "", colnames(the_data[[i]]))
		the_data[[i]] <- the_data[[i]][,colnames(the_data[[i]]) %in% c("index", "id", "score", "sort", "ignored", "suggest.input", "highlight.primaryIC") == FALSE]
		list_cols <- which(sapply(1:ncol(the_data[[i]]), function(x) is.list(the_data[[i]][,x])))
		for (j in 1:length(list_cols)) {
		  the_data[[i]][,list_cols[j]] <- sapply(the_data[[i]][,list_cols[j]], paste, collapse = ";")
		}
		if (any(expected_cols %in% colnames(the_data[[i]]) == FALSE)) {
			pcols <- expected_cols[expected_cols %in% colnames(the_data[[i]]) == FALSE]
			the_data[[i]][,pcols] <- ""
			the_data[[i]] <- the_data[[i]][,expected_cols]
		}	
	}
	the_data <- do.call(rbind, the_data)
	the_data$title <- gsub("\\s+?", " ", the_data$title)
	the_data$purpose <- gsub("\\s+?", " ", the_data$purpose)
	return(the_data)
}