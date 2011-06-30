WORKING_COPY = '/tmp/bridge'
HG_REPO = 'http://localhost:8000'

class Bridge
  def initialize() @scm = GitSCM.new end

  def setup
    File.exists? WORKING_COPY and rm_r WORKING_COPY
    mkdir WORKING_COPY
    cd WORKING_COPY do
      @scm.make_working_copy
      sh "hg init"
    end
  end

  def run
    cd WORKING_COPY do
      @scm.update_working_copy
      logs = @scm.get_logs
      # With RTC we can ensure that we only get the changes we need.
      #
      # if File.exists? "#{WORKING_COPY}/.last"
      #   last = IO.read("#{WORKING_COPY}/.last").strip
      #   logs = logs.take_while { |log| log.revision != last }
      # end
      # logs.reverse!
      # last = nil
      logs.each do |log|
        last = log.revision
        @scm.change_working_copy_to_revision(log.revision)
        sh "hg addremove --quiet --exclude .git --exclude .last"
        sh "hg commit -m '#{log.revision}: #{log.message}' -ubridge"
        sh "hg push --quiet #{HG_REPO}"
      end
      @scm.clean_up_working_copy
      # last and File.open("#{WORKING_COPY}/.last", 'w') { |f| f.write(last) }
    end
  end
end

class GitSCM
  def make_working_copy
    sh "git clone /tmp/src ."
  end

  def update_working_copy
    sh "git pull --quiet"
  end

  def get_logs
    `git log --oneline`.lines.map { |line| Log.new(line) }
  end

  def change_working_copy_to_revision(revision)
    sh "git checkout --quiet #{revision}"
  end

  # may only be necessary for git
  def clean_up_working_copy
    sh "git checkout --quiet master"
  end

  class Log
    def initialize(line) @line = line end

    def revision
      @line.split.first
    end

    def message
      @line.split[1..-1].join(' ')
    end
  end
end

class RTCSCM
  def make_working_copy
    sh "scm create workspace --username ben --password ben --repository-uri https://localhost:9443/ccm -s 'BRM Stream' ben-stream"
    sh "scm load --username ben --password ben ben-stream@https://localhost:9443/ccm"
  end

  def update_working_copy
    # not needed for RTC
  end

  def get_logs
    `scm compare ws "BRM Stream" stream ben-stream --password ben --include-types s`.
      lines.map { |line| Log.new(line) }
  end

  def change_working_copy_to_revision(revision)
    sh "scm accept --password ben --changes #{revision}"
  end

  def clean_up_working_copy
    # not needed for RTC
  end

  class Log
    attr_reader :revision, :message

    def initialize(line)
      parse = /\(([0-9])\) (.*)/.match(line)
      @revision = parse[1]
      @message = parse[2]
    end
  end
end
