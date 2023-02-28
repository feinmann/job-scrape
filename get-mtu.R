# inspired by tutorial from https://scitilab.com/post_data/forbes_scrapping/2021_03_24_forbes_scrapping/

library(data.table)
library(rvest)
library(RSelenium)
library(futile.logger)


get_all_jobs <- function(remDr, url = "https://www.mtu.de/de/karriere/jobboerse/") {
  
  remDr$client$navigate(url)
  
  consent_button <- remDr$client$findElements(
    using = "xpath", "//button[starts-with(@class, 'sg-cookie-optin')]")
  consent_button[[1]]$clickElement()
  Sys.sleep(1) # wait for page loading
  
  # push button until all jobs are showed
  pagination_button = "startvalue"
  while (TRUE) {
    pagination_button <- try(suppressMessages(
      remDr$client$findElement(using = "css", '[class="dvinci-pagination-button btn btn-default"]')), 
      silent = T)
    if (class(pagination_button) != "webElement") {
      break
    }
    pagination_button$clickElement() # expect only one button
  }
  
  # get all job-titles that are on the page:
  job_title <- remDr$client$findElements(using = "xpath", '//*[contains(concat( " ", @class, " " ), concat( " ", "dvinci-job-position", " " ))]')
  job_titles <- unlist(lapply(job_title, function(x) {x$getElementText()}))
  
  # get whole page source
  job_list_source <- remDr$client$getPageSource()[[1]] |> read_html()
  urls <- job_list_source |> 
    html_elements('[class="dvinci-job-position ng-binding"]') |> 
    html_attr("href")
  
  erg <- data.table(titles = job_titles, url = urls)
  erg
}


get_job_texts <- function(dt_urls) {
  num_urls <- length(dt_urls$url)
  pb <- txtProgressBar(min = 0,      # Minimum value of the progress bar
                       max = num_urls, # Maximum value of the progress bar
                       style = 3,    # Progress bar style (also available style = 1 and style = 2)
                       width = 50,   # Progress bar width. Defaults to getOption("width")
                       char = "=")   # Character used to create the bar
  result <- data.table(url = rep("NA", num_urls), job_text = rep("NA", num_urls))
  for (idx in seq_along(urls)) {
    job_text_content <- read_html(urls[idx]) |> html_elements("body") |> html_text2()
    result[idx, url := urls[idx]]
    result[idx, job_text := job_text_content]
    setTxtProgressBar(pb, idx)
  }
  close(pb)
  result
}


get_hits <- function(myres, keywords) {
  myres[, job_text := gsub("Datenschutzerklärung", "CENSORED", job_text, fixed = TRUE)]
  myres[like(job_text, "daten|data", ignore.case = TRUE, fixed = FALSE), ]
  myres[like(job_text, "CENSORED", fixed = TRUE), ]

  for (row in 1:nrow(myres)) {
    myres[row, hits := data.table(unlist(strsplit(gsub("\n", " ", job_text), split = " ")))[V1 %ilike% keywords, paste(V1, collapse = ",")]]
  }
  
  myres
}




##### main #########################################################################################

remDr <- rsDriver(
  browser = "firefox", 
  verbose = TRUE,
  chromever = NULL)

my_hits <- remDr |> 
  get_all_jobs() |>
  get_job_texts() |>
  get_hits("daten|data")

require(wordcloud)

wordcloud::wordcloud(my_hits[hits != "", hits], min.freq = 2)
