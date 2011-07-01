task :start => ['dest:setup', 'dest:start', 'bridge:setup']
task :stop => ['dest:stop']
task :run => ['bridge:run']

task :test => [:stop, :start, :run]

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
    File.exists? '/tmp/dest.pid' and sh "kill `cat /tmp/dest.pid`" and rm '/tmp/dest.pid'
  end
end

namespace :bridge do
  task :setup do
    sh "./rtc-git-bridge --init #{args}"
  end

  task :run do
    sh "./rtc-git-bridge --run #{args}"
  end
end

def args
  "-d /tmp/foo -m http://localhost:8000 -t https://localhost:9443/ccm -w #{ws} -u ben -p ben -s 'BRM Stream'"
end

def ws
  'test-ws-6'
end
