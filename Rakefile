require 'bridge.rb'

task :start => ['dest:setup', 'dest:start', 'bridge:setup']
task :stop => ['dest:stop', 'bridge:stop']

namespace :dest do
  task :setup  do
    mkdir '/tmp/dest'
    cd '/tmp/dest' do
      sh "hg init"
    end
  end

  task :start do
    cd '/tmp/dest' do
      sh "hg serve --daemon --pid-file /tmp/dest.pid --accesslog /tmp/dest.log --errorlog /tmp/dest.err --config web.allow_push='*' --config web.push_ssl=false"
    end
  end

  task :stop do
    File.exists? '/tmp/dest' and rm_r '/tmp/dest'
    sh "kill `cat /tmp/dest.pid`"
    rm '/tmp/dest.pid'
  end
end

namespace :bridge do
  task :setup do
    Bridge.new.setup
  end

  task :run do
    Bridge.new.run
  end

  task :stop do
    File.exists? '/tmp/bridge' and rm_r '/tmp/bridge'
  end
end
