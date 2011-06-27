task :start => ['src:setup', 'dest:setup', 'dest:start', 'bridge:setup']

namespace :src do
  task :setup do
    File.exists? '/tmp/src' and rm_r '/tmp/src'
    cp_r 'test/data/src', '/tmp'
    cd '/tmp/src' do
      sh "git init"
      sh "git add content"
      sh "git commit -m'first commit'"
    end
  end
end

namespace :dest do
  task :setup  do
    File.exists? '/tmp/dest' and rm_r '/tmp/dest'
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
    sh "kill `cat /tmp/dest.pid`"
    rm '/tmp/dest.pid'
  end
end

namespace :bridge do
  task :setup do
    File.exists? '/tmp/bridge' and rm_r '/tmp/bridge'
    mkdir '/tmp/bridge'
    cd '/tmp/bridge' do
      sh "git clone /tmp/src ."
      sh "hg init"
    end
  end

  task :run do
    cd '/tmp/bridge' do
      sh "git pull"
      logs = `git log --oneline`.lines.to_a
      if File.exists? '/tmp/bridge.last'
        last = IO.read('/tmp/bridge.last').strip
        logs = logs.take_while { |log| log.split.first != last }
      end
      logs.reverse!
      last = nil
      logs.each do |log|
        revision = log.split.first
        last = revision
        sh "git checkout #{revision}"
        sh "hg addremove --exclude .git"
        sh "hg commit -m '#{log.strip}' -ubridge"
        sh "hg push http://localhost:8000"
      end
      sh "git checkout master"
      last and File.open('/tmp/bridge.last', 'w') { |f| f.write(last) }
    end
  end
end
