require 'sinatra'
require 'sinatra/base'
require 'mustache/sinatra'
require './f'
require 'yaml'
require 'mongo'
require 'mongoid'
include Mongo
require 'date'

class App < Sinatra::Base
  register Mustache::Sinatra
  require './views/layout'

  @@environment = 'development'
  @@config = {}

  configure do
    conn = Mongo::Connection.new.db('errors')
    set :mongo, conn
  end

  def initialize
    super()
    @@config = YAML.load_file(File.dirname(__FILE__) + '/config/config.yml')[@@environment]
  end

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


  post '/write/?' do
    settings.mongo['errors'].insert params
  end

  get '/f' do
    content_type :json

    settings.mongo['errors'].find.to_a.to_json
  end

  get '/d' do
    content_type :text
    settings.mongo['errors'].remove
  end

  get '/' do
    @content = "Giraffe"
    @logs = []
    @content = ''

    @logs = db_get_data()
    @show_button = true

    mustache :index
  end

  get '/search/*' do |term|
    @logs = db_get_data(0, '', term)
    @content = "Found #{@logs.length} results."

    mustache :index
  end

  post '/more/*' do
    n = params[:splat][0].to_i
    @logs = db_get_data(n)
    @content = ''

    mustache :more_posts, :layout => false
  end

  post '/more-filter/*/*' do
    f = params[:splat][0]
    n = params[:splat][1].to_i

    @logs = db_get_data(n, f)
    @content = ''
    @count = @logs.length

    mustache :more_posts, :layout => false
  end

  get '/filter/*' do |filter|
    f = params[:splat][0]

    @logs = db_get_data(0, filter)

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

def db_get_data(offset=0, filter='', searchterm = '')
  level = {
    1 => 'Fatal Error',
    2 => 'Warning',
    4 => 'Parse Error',
    8 => 'Notice',
    16 => 'Core Error',
    32 => 'Core Warning',
    64 => 'Fatal Compile Error',
    128 => 'Fatal Compile Warning',
    256 => 'User Error',
    512 => 'User Warning',
    1024 => 'User Notice',
    2048 => 'Strict Notice',
    4096 => 'Recoverable Fatal Error',
    8192 => 'Deprecated Notice',
    16384 => 'User Deprecated Notice',
  }
  level_class = {
    1 => 'error',
    2 => 'warning',
    4 => 'warning',
    8 => 'notice',
    16 => 'error',
    32 => 'warning',
    64 => 'exception',
    128 => 'exception',
    256 => 'error',
    512 => 'warning',
    1024 => 'notice',
    2048 => 'notice',
    4096 => 'exception',
    8192 => 'notice',
    16384 => 'notice',
  }

  @fargs = {}
  @sargs = {}

  if (!filter.empty?)
    ls = []
    level_class.each do |k, v|
      if (v == filter.downcase)
        ls.push(k.to_s)
      end
    end

    @fargs = {'level' => { '$in' => ls } }
    errors = settings.mongo['errors']
  else
    errors = settings.mongo['errors']
  end

  if (!searchterm.empty?)
    @sargs = {'message' => { '$regex' => ".*#{searchterm}.*" } }
  end

  if (!searchterm.empty?)
    if (!@sargs.empty?) 
      @m = @fargs.merge(@sargs)
    else
      @m = @fargs
    end
    errors = errors.find(@m)
  elsif (!filter.empty?)
    errors = errors.find(@fargs)
  else
    errors = errors.find
  end


  errors = errors.skip(offset).limit(App.rows_per_page).sort({ 'time' => -1 }).to_a

  @logs = []
  errors.each do |error|
    t = error['time'].to_i
    d = Time.at(t).to_formatted_s(:db)
    l = level[error['level'].to_i]
    lc = level_class[error['level'].to_i]
    

    @logs.push({
      'date' => d,
      'level' => l,
      'level_class' => lc,
      'errorat' => error['page'],
      'full_errorat' => error['page'],
      'errormsg' => error['message'],
      'error_line' => error['line'],
      'error_file' => error['file'],
    })
  end

  @logs
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
