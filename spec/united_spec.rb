require 'spec_helper'
require 'date'

def parse_page(doc, options = {})
  if discounts?(doc, options)
    rows = find_rows(doc, options)
    puts "#{rows.length} found"
  <<EOF
#{find_calendar(doc)}
<table border="1">
  #{find_header(doc)}
  #{rows.join("\n")}
</table>
EOF
  else
    puts "None found"
  end
end

def find_header(doc)
  doc.css('.rewardResults tbody').first.to_html
end

def find_calendar(doc)
  doc.css('#ctl00_ContentInfo_resultsReward_Table1').to_html
end

def discounts?(doc, options = {})
  match = options[:first] ? 'tr td:nth-child(5) .btnBlue' : '.rewardResults tr .btnBlue'
  doc.css(match).length > 0
end

def find_rows(doc, options = {})
  match = options[:first] ? 'td:nth-child(5) .btnBlue' : '.btnBlue'
  doc.css('.rewardResults tr').map do |row|
    blues = row.css(match).length
    row if blues > 0
  end.compact.map(&:to_html)
end

def write_html_page(filename, text)
  header = <<EOF
<style>
  .btnBlue { background-color: blue;}
</style>
EOF
  File.open(filename, "w") do |file|
    file.write header
    file.write text
  end
end

def cache_page(date, html)
  filename = date.strftime('data/%Y-%m-%d.html')
  File.open(filename, "w") do |file|
    file.write html
  end
end

def login
  visit 'http://www.united.com/web/en-US/apps/account/account.aspx'
  fill_in 'ctl00_ContentInfo_SignIn_onepass_txtField', :with => ENV['UNITED_USERNAME']
  fill_in 'ctl00_ContentInfo_SignIn_password_txtPassword', :with => ENV['UNITED_PASSWORD']
  click_on 'Sign In (Secure)'
  page.should have_content('My MileagePlus account')
end

def search_day(options)
  visit 'https://www.united.com/web/en-US/apps/booking/flight/searchOW.aspx?CS=N'
  choose 'One Way'
  fill_in 'ctl00_ContentInfo_SearchForm_Airports1_Origin_txtOrigin', :with => options[:from]
  fill_in 'ctl00_ContentInfo_SearchForm_Airports1_Destination_txtDestination', with: options[:to]
  choose 'Search Specific Dates'
  fill_in 'ctl00_ContentInfo_SearchForm_DateTimeCabin1_Depdate_txtDptDate', with: options[:on]
  if page.has_css?('#ctl00_ContentInfo_SearchForm_DateTimeCabin1_Cabins_cboCabin')
    select('First/Global First', from: 'ctl00_ContentInfo_SearchForm_DateTimeCabin1_Cabins_cboCabin')
  end
  choose 'Award Travel'
  click_on 'Search'
  page.should have_content('Award Availability Calendar')
end

describe 'download', type: :feature, js: false do
  it "searches a date range" do
    start = Date.parse('2014-04-01')
    number_of_days = 30
    search = {
        from: 'San Francisco, CA (SFO)',
        to: 'Frankfurt, Germany (FRA)',
    }

    login
    results = number_of_days.times.map do |day|
      search[:on] = start.strftime('%m/%d/%Y')
      puts "Searching #{search[:on]}..."
      search_day(search)
      doc = Nokogiri::HTML(page.html)
      cache_page(start, doc.to_html)
      start = start + 1
      parse_page(doc)
    end.compact
    write_html_page("any_specials.html", results.join("\n"))
  end
end

describe 'cached', type: :feature, js: false do
  it "searches cache" do
    results = Dir["data/**/*.html"].map do |filename|
      puts "Searching #{filename}..."
      doc = Nokogiri::HTML(open(filename))
      parse_page(doc, first: true)
    end.compact
    write_html_page("first_class_only.html", results.join("\n"))
  end
end

describe "search", :type => :feature, js: false do
  xit "finds flight" do
    search = {
        from: 'San Francisco, CA (SFO)',
        to: 'Frankfurt, Germany (FRA)',
        on: '4/20/2014'
    }

    login
    puts "Searching #{search[:on]}..."
    render_on_error do
      search_day(search)
    end
    doc = Nokogiri::HTML(page.html)
    result = parse_page(doc)
    write_html_page("foo.html", result)
  end
end

describe 'parsing', type: :feature do
  xit "parses the page" do
    doc = Nokogiri::HTML(open('spec/sample1.html'))
    rows = find_rows(doc)
    expect(rows.length).to eql(4)
    rows = find_rows(doc, first: true)
    expect(rows.length).to eql(0)
  end
end