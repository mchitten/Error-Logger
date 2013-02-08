require 'sinatra'
require 'mustache/sinatra'
require 'mongoid'
require 'json'
require './f'

Mongoid.load!('./config/mongoid.yml')

class Error
	include Mongoid::Document

	field :error_id, type: Integer
	field :date, type: Time
	field :level, type: String
	field :page, type: String
	field :referrer, type: String
	field :message, type: String
	field :line, type: Integer
	field :file, type: String
end

class App < Sinatra::Base
  register Mustache::Sinatra
  require './views/layout'

  set :mustache, {
    :views     => './views/',
    :templates => './views/templates/'
  }

  get '/' do
    @content = "Giraffe"
    @logs = []
    @content = ''

    @logs = get_file_data()
    Error.create(
		error_id: 1,
		date: '2012-12-01',
		level: 'Critical',
		page: 'google.com',
		referrer: 'facebook.com',
		message: 'blah',
		line: 6,
		file: 'example.jpg'
    )
    mustache :index
  end

  post '/more/*' do
    n = params[:splat][0].to_i
    @logs = get_file_data(n)
    @content = ''

    mustache :more_posts, :layout => false
  end

  get '/filter/*' do |filter|
    f = params[:splat][0]
    @logs = get_file_data(0, filter)
    @content = ''

    mustache :index
  end

  get '/nolayout' do
    content_type 'text/plain'
    mustache :nolayout, :layout => false
  end
end

def get_file_data(offset=0, filter='')
  File.open('./dsl.log') do |f|
    @clogs = []
    f.tail(150, offset, filter).each do |l|
      date = l.scan(/(([A-Za-z]{3})\s+(\d{1,2})\s+(\d{2}\:\d{2}\:\d{2}))/)
      status = l.scan(/\|(Notice|Warning|Error)\:/)
      message = l.scan(/\|([^|]+)\.$/)
      http = l.scan(/(http\:\/\/[^\|]+)\|/)
      stat = l.scan(/\(line ([0-9]+) of ([^\)]+)\)/)

      if !status[0].nil?
        case status[0][0]
          when 'Notice'
            level_class = 'notice'
          when 'Warning'
            level_class = 'warning'
          when 'Error'
            level_class = 'error'
        end
      else
        if !message[0].nil?
          m = message[0][0]
          if (m.include? "Exception")
            level_class = 'critical'
          else
            level_class = 'nada'
          end
        else
          level_class = 'nada'
        end
      end

      @clogs.push({
        'date' => (!date[0].nil? ? date[0][0] : 'Unknown'),
        'level' => (!status[0].nil? ? status[0][0] : '(None)'),
        'level_class' => level_class,
        'referer' => (!http[1].nil? ? http[1][0][0..75] + (http[1][0].length > 75 ? "..." : '') : 'Unknown'),
        'full_referer' => (!http[1].nil? ? http[1][0] : ''),
        'errorat' => (!http[2].nil? ? http[2][0][0..75] + (http[2][0].length > 75 ? "..." : '') : 'Unknown'),
        'full_errorat' => (!http[2].nil? ? http[2][0] : ''),
        'errormsg' => (!message[0].nil? ? message[0][0] : '(No msg)'),
        'error_line' => (!stat[0].nil? ? stat[0][0] : 'N/A'),
        'error_file' => (!stat[0].nil? ? stat[0][1] : 'N/A')
      })
    end
  end

  @clogs
end
