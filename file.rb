require './f'

File.open('./dsl.log') do |f|
  f.tail(5,0).each do
  	puts "WHY YES"
  end
end
