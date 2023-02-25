# inspired by tutorial from https://scitilab.com/post_data/forbes_scrapping/2021_03_24_forbes_scrapping/

library(data.table)
library(rvest)
library(RSelenium)
library(futile.logger)

remDr <- rsDriver(
  browser = "firefox", 
  verbose = TRUE,
  chromever = NULL)

url <- "https://www.mtu.de/de/karriere/jobboerse/"
remDr$client$navigate(url)

consent_button <- remDr$client$findElements(using = "xpath", "//button[starts-with(@class, 'sg-cookie-optin')]")
consent_button[[1]]$clickElement()
Sys.sleep(1) # wait for page loading

# send text to input field to refresh job-search
input_field <- remDr$client$findElement(using = 'css', '[class="form-control ng-pristine ng-untouched ng-valid"]')
input_field$sendKeysToElement(list("data", key = "enter"))

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

# TODO: pagination if there are more search results
  


##### rvest all pages:
test_url <- "https://mtuaero.dvinci-easy.com/de/jobs/1892/praktikant-qualitatssicherung-all-genders"

for (job_url in erg$url) {
  print(job_url)
  job_text <- read_html(job_url) |> html_elements("body") |> html_text2()
  print(job_text)
  erg[url == job_url, job_text_col := job_text]
  daten_hit = job_text |> tolower() |> stringi::stri_extract_all_coll(pattern = "daten") |> paste(collapse = ",")
  erg[url == job_url, daten_hit_col := daten_hit]
  data_hit = job_text |> tolower() |> stringi::stri_extract_all_coll(pattern = "data") |> paste(collapse = ",")
  erg[url == job_url, data_hit_col := data_hit]
}

erg[(daten_hit != "daten" & !is.na(daten_hit)) | !is.na(data_hit), .N]
127 / 405

saveRDS(erg, "mtu_analytics_data_2023-02-23.rds")
