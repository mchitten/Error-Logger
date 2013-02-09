require 'sinatra'
require 'sinatra/base'
require 'mustache/sinatra'
require './f'
require 'yaml'

class App < Sinatra::Base
  register Mustache::Sinatra
  require './views/layout'

  # Makes rows_per_page variable accessible.
  @@rows_per_page = 150
  def self.rows_per_page
    @@rows_per_page
  end

  # Defines mustache configuration
  set :mustache, {
    :views     => './views/',
    :templates => './views/templates/'
  }


  get '/' do
    @content = "Giraffe"
    @logs = []
    @content = ''

    @logs = get_file_data()
    @show_button = true

    mustache :index
  end

  post '/more/*' do
    n = params[:splat][0].to_i
    @logs = get_file_data(n)
    @content = ''

    mustache :more_posts, :layout => false
  end

  post '/more-filter/*/*' do
    f = params[:splat][0]
    n = params[:splat][1]

    if f != 'Exception'
      filter = f + ':'
    end

    @logs = get_filtered_data(n, f)
    @content = ''
    @count = @logs.length

    mustache :more_posts, :layout => false
  end

  get '/filter/*' do |filter|
    f = params[:splat][0]

    if filter != 'Exception'
      filter = filter + ':'
    end

    @logs = get_filtered_data(0, filter)

    @content = "Found #{@logs.count}"
    @show_button = true
    if (@logs.count < @@rows_per_page)
      @show_button = false
    end
 
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
    f.tail(App.rows_per_page, offset, filter).each do |l|
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

def get_filtered_data(offset=0, filter='')
    @logs = []
    @i = 0
    n = offset.to_i + App.rows_per_page
    r = `grep "#{filter}" dsl.log | tail -n "#{n}" | head -n #{App.rows_per_page}`.split(/\n/).reverse
    #r = `tac 'dsl.log' | grep -m150 "#{filter}" | tail -n150`.split(/\n/).reverse
    #r = `sed -n 
    r.each do |l|
      if l.include? "#{filter}"
        if @i >= App.rows_per_page
          break
        end

        date = l.scan(/(([A-Za-z]{3})\s+(\d{1,2})\s+(\d{2}\:\d{2}\:\d{2}))/)
        status = l.scan(/\|(Notice|Warning|Error)\:/)
        message = l.scan(/\|([^|]+)$/)
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

        @logs.push({
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

        @i += 1
      end
    end

    @logs
end