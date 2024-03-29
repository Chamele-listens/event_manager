require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end


def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone,vaild_phone)

  clean_phone = phone.gsub(/[!. ()E+-]/,"") 

  if clean_phone.length < 10
    p "#{clean_phone} is a bad number"
  elsif clean_phone.length == 11 && clean_phone[0] == "1"
    vaild_phone << clean_phone[1..-1]
  elsif clean_phone.length == 11 && clean_phone[0] != "1"
    p "#{clean_phone} is bad cus 1st number isn't 1"
  elsif clean_phone.length > 11
    p "#{clean_phone} is bad cus its grater than 11"
  else
    vaild_phone << clean_phone
  end
end

def parse_date(date_time,date)
  temp_date = Date.strptime(date_time[0],"%y/%d/%m")
  date << DateTime.parse("#{temp_date.day}/#{temp_date.month}/#{temp_date.year} #{date_time[1]}")
end

def find_average_hour(date_array)
  hour = []
  date_array.each {|date_temp2| hour << date_temp2.hour}
  avg_hour = hour.sum/hour.length
end

def find_average_day(date)
  day = []
  date.each {|week| day << week.wday }
  avg_day = day.sum/day.length
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
vaild_phone = []
date = []

contents.each do |row|
  id = row[0]
  phone = row[5] 
  name = row[:first_name]
  date_time = row[1].split(" ")
  

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  clean_phone_number(phone,vaild_phone)

  parse_date(date_time,date)  

  form_letter = erb_template.result(binding)
  
  save_thank_you_letter(id,form_letter)
end

p "Most people registered on the #{find_average_day(date)}  day of the week"
p "The average date is #{find_average_hour(date)}"
