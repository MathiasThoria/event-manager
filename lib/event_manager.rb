require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  # puts "InMethod> #{phone_number}"
  # puts "InMethod.gsub> #{phone_number.gsub(/[^0-9]/, '')}"

  phone_number.gsub!(/[^0-9]/, '')
  if phone_number.to_s.length > 10
    if phone_number.to_s[0] == 1 && phone_number.to_s.length == 11
      phone_number.to_s[1..10]
    else
      'bad_number'
    end
  elsif phone_number.to_s.length == 10
    phone_number
  else
    'bad_number'
  end
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

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)
timo = {}
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
puts "I don't know what to do whit this phone numbers. However, TOP asked."
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_number = clean_phone_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  puts "#{id} #{phone_number}"
  hour_of_registration = Time.strptime(row[:regdate], '%m/%d/%y %H:%M').hour
  #first hash element dont work with +=
  if timo.has_key?(hour_of_registration)
    timo[hour_of_registration] += 1
  else
    timo[hour_of_registration] = 0
  end
end
puts "Most of the people registered at:#{timo.key(timo.values.max)}hs."
