from undetected_chromedriver import Chrome
from selenium.webdriver.common.by import By

browser = Chrome()
browser.get('https://jobs.gecareers.com/aviation/global/en/search-results?keywords=data')

consent_button = browser.find_element(By.CSS_SELECTOR, '[class="evidon-banner-optionbutton"]')
consent_button.click()

consent_button2 = browser.find_element(By.CSS_SELECTOR, '[class="evidon-prefdiag-acceptbtn"]')
consent_button2.click()

job_titles = browser.find_elements(By.XPATH, '//*[contains(concat( " ", @class, " " ), concat( " ", "job-title", " " ))]//span')
for job in job_titles:
  print(job.text)
  
next_button = browser.find_element(By.XPATH, '//*[contains(concat( " ", @class, " " ), concat( " ", "pagination", " " ))]//li[(((count(preceding-sibling::*) + 1) = 12) and parent::*)]//*[contains(concat( " ", @class, " " ), concat( " ", "au-target", " " ))]')
next_button.click() # TODO: find apropriate button when pagination is > 10
