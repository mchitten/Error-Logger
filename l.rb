IO.foreach('./dsl.log') do |l|
  if l.include? "Exception"
    p l
  end
end