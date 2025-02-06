# frozen_string_literal: true

class Scraper
  require 'headless'
  require 'pry'
  require 'watir'
  require 'csv'

  URL = 'https://sres.realtor/work-sres-designee/find-member?lname=&fname=&country=US&state=CO&city=&zip=&page='
  EMPTY_SELECTOR = 'view-empty'
  HEADERS = %w[
    name
    company
    address
    city
    zip
    phone
    website
  ].freeze

  def initialize
    @page = 0
  end

  def call
    CSV.open('tmp/results.csv', 'wb') do |csv|
      csv << HEADERS

      until browser.div(class: EMPTY_SELECTOR).exist? # beyond last page
        scrape_page.each do |result|
          csv << result.values
        end

        @page += 1
        clear_results
      end
    end
  ensure
    browser.close
    # browser.destroy # for headless
  end

  private

  attr_reader :page

  def scrape_page
    browser.goto(URL + page.to_s)

    search_results.map do |result|
      result_fields(result: result)
    end
  end

  def result_fields(result:)
    website = result.div(class: 'field-ramco-website')
    {
      name: result.div(class: 'field-full-name').text,
      company: result.div(class: 'field--name-ramco-company').text.split("\n")[1],
      address: result.span(class: 'address-line1').text,
      city: result.span(class: 'locality').text,
      zip: result.span(class: 'postal-code').text,
      phone: result.div(class: 'field--name-ramco-phone').text.split("\n")[1],
      website: website.exists? ? website.a.href : ''
    }
  end

  # clear results for each new paginated page
  def clear_results
    @search_results = nil
  end

  def search_results
    @search_results ||= browser.divs(class: 'views-field-rendered-entity')
  end

  def browser
    @browser ||= Watir::Browser.new
    # headless = Headless.new
    # headless.start
  end
end

Scraper.new.call
