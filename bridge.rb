WORKING_COPY = '/tmp/bridge'
HG_REPO = 'http://localhost:8000'

class Bridge
  def initialize() @scm = SCM.new end

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
      logs = @scm.get_logs
      logs.each do |log|
        last = log.revision
        @scm.change_working_copy_to_revision(log.revision)
        sh "hg addremove --quiet --exclude .git --exclude .last"
        sh "hg commit -m '#{log.revision}: #{log.message}' -ubridge"
        sh "hg push --quiet #{HG_REPO}"
      end
    end
  end
end

class SCM
  def make_working_copy
    sh "scm create workspace --username ben --password ben --repository-uri https://localhost:9443/ccm -s 'BRM Stream' ben-stream"
    sh "scm load --username ben --password ben ben-stream@https://localhost:9443/ccm"
  end

  def get_logs
    `scm compare ws "BRM Stream" stream ben-stream --password ben --include-types s`.
      lines.map { |line| Log.new(line) }
  end

  def change_working_copy_to_revision(revision)
    sh "scm accept --password ben --changes #{revision}"
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
