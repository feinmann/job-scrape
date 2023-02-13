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
  