# nih_guide_api
R code for working with the NIH Guide API

## Vignette
First, read the `nih_guide_api.r` file into your current R session

```r
source("nih_guide_api.r")
```

The API search fields are available as arguments in the `get_nih_guide()` function. So to retrieve all active NOFOs that NICHD has either sponsored or signed on to, you would run

```r
nofos <- get_nih_guide(type = "active", primaryic = "NICHD", outfile = "guide_docs.txt")
```

The function will automatically identify how many pages of results you need and loop through the remaining pages to retrieve the full set of search results. It will also save the raw JSON to the outfile specified and reformat the JSON into a usable data frame. Fields with multiple values (like sponsoring ICs) will be collapsed into semicolon-delimited strings.

Other possible searches include the following. 

To retrieve NIAID-sponsored (but not NIAID-participating) NOFOs in calendar year 2006 you would run
```r
nofos <- get_nih_guide(daterange = "01012006-12312006", primaryic = "NIAID", spons = "false", outfile = "niaid_2006.txt")
```

To retrieve NIDA RFAs from 2010-2012 you would run
```r
nofos <- get_nih_guide(daterange = "01012010-12312012", primaryic = "NIDA", doctype = "RFA", outfile = "nida_rfas.txt")
```

To retrieve all parent SBIR/STTR NOFOs, you would run 
```r
nofos <- get_nih_guide(parentfoa = "Yes", activitycodes = "R41,R42,R43,R44", outfile = "sbir_nofos.txt")
```

Finally, the `extract_guide()` function allows you to extract guide JSON retrieved by the `get_nih_guide()` function in a previous R session. To use it, simply point it at the JSON file created by the original `get_nih_guide()` function call. 
```r
guide <- extract_guide("guide_docs.txt")
```
