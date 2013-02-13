require 'yaml'

namespace :test do
  desc "Tests."
  task :test do
    mt = `mongo --version`
    if (mt.include? "Command not found")
      abort 'MongoDB does not appear to be installed.  Please install MongoDB before running the script.'
    end
  end
end

namespace :bundle do
  desc "Runs bundler."
  task :start do
    environment = 'development'
    config_file = File.dirname(__FILE__) + '/config/config.yml'

    config = YAML.load_file(config_file)
    mtime = File.mtime(File.dirname(__FILE__) + '/Gemfile').to_i

    if (mtime > config[environment]['last_bundle'])
      system "bundle install"
      config[environment]['last_bundle'] = Time.now.to_i
      File.open(config_file, 'w') do |f|
        YAML.dump(config, f)
      end
    end
  end
end

namespace :mongodb do
  desc "Start MongoDB for development."
  task :start do
    system "mongod"
  end
end

namespace :haystack do
  desc "Start Haystack for development."
  task :start do
    system "shotgun config.ru"
  end
end


desc "Start everything."
task :start => ['test:test','bundle:start','mongodb:start','haystack:start']
