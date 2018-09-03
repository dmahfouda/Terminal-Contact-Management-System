require "selenium-webdriver"
require "io/console"

 prefs = {
   prompt_for_download: false, 
   default_directory: ""
 }

options = Selenium::WebDriver::Chrome::Options.new
options.add_preference(:download, prefs)
#options.add_argument('--headless')
#options.add_argument('window-size=1200x600')


driver = Selenium::WebDriver.for :chrome, options: options

driver.navigate.to "http://accounts.google.com"

wait = Selenium::WebDriver::Wait.new(:timeout => 15)

# Add text to a text box
input = wait.until {
    element = driver.find_element(:css, '#identifierId')
    element if element.displayed?
}

puts "What's your Google username?"
input.send_keys(gets.chomp)

driver.find_element(:id, "identifierNext").click

input = wait.until {
	element = driver.find_element(:name, "password")
	element if element.displayed?
}

puts "What's your Google password?"
input.send_keys(STDIN.noecho(&:gets).chomp)
driver.find_element(:id, "passwordNext").click

input = wait.until {
 	element = driver.find_element(:class, "gb_b")
 	element if element.displayed?
}

puts "Working..."

driver.navigate.to "http://contacts.google.com"

input = wait.until {
	element = driver.find_elements(:class, "GPDjgb")
	element if element[1].displayed?
}

input[1].click

input = wait.until {
	element = driver.find_element(:class, "NjgsJf")
	element if element.displayed?
}

input.click

input = wait.until {
	element = driver.find_element(:xpath, "//*[@id='yDmH0d']/div[4]/div/div[2]/div[3]/div[2]/content/span")
	element if element.displayed?
}

input.click

sleep(4)