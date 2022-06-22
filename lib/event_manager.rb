require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
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

def clean_phone_number(phone)
  number = phone.split("")
  for i in 0..1
    number.each do |char|
      number.delete(char) if char != "0" && char.to_i == 0
    end
  end

  if number.length > 10 && number[0] == "1"
    number.shift
  elsif number.length > 10 || number.length < 10
    number = "0000000000"
  else
    number
  end

  begin
    number = number.join.to_i
  rescue
    number
  end
  number
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def create_hours_array(dates, hours)
  hours << dates[1].split(":")[0].to_i
end

def sort_popular_hours(hours)
  popular_hours = hours.reduce(Hash.new(0)) do |total, hour|
    if total[hour] == nil
      total[hour] == 0
    end
    total[hour] += 1
    total
  end
  popular_hours = popular_hours.sort_by {|hour, count| count}.reverse

  highest_reg = popular_hours[0][1]
  popular_hours.each do |hours|
    if hours[1] == highest_reg
      puts "Hour #{hours[0]} is most popular..."
    end
  end
end

def fill_days_array(regdate, days)
  month = regdate[0].to_i
  day = regdate[1].to_i
  year = regdate[2].to_i

  days << Date.new(year, month, day).wday
end

def sort_popular_days(days)
  days = days.map do |day|
    case day 
    when 0
      day = "Sunday"
    when 1
      day = "Monday"
    when 2
      day = "Tuesday"
    when 3
      day = "Wednesday"
    when 4
      day = "Thursday"
    when 5
      day = "Friday"
    when 6
      day = "Saturday"
    else
      next
    end
  end
  
  days = days.reduce(Hash.new(0)) do |total, day|
    if total[day] == nil
      total[day] = 0
    end
    total[day] += 1
    total
  end
  
  days = days.sort_by {|day, total| total}.reverse

  highest_reg = days[0][1]

  days.each do |day|
    if day[1] == highest_reg
      puts "#{day[0]} is the most popular day..."
    end
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hours = []
days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone = clean_phone_number(row[:homephone])

  create_hours_array(row[:regdate].split, hours)

  fill_days_array(row[:regdate].split(" ")[0].split("/"), days)

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
end

sort_popular_hours(hours)
sort_popular_days(days)
