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
      sh "hg addremove --quiet --exclude .jazz5 --exclude .metadata"
      sh "hg commit -m 'Initial bridge checkin.' -ubridge"
      sh "hg push --quiet #{HG_REPO}"
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
  REPO = 'https://localhost:9443/ccm'
  USER = 'ben'
  PASSWORD = 'ben'
  STREAM = "'BRM Stream'"
  WORKSPACE = 'bridge-workspace-1'

  def make_working_copy
    sh "scm create workspace --username #{USER} --password #{PASSWORD} \
          --repository-uri #{REPO} --stream #{STREAM} #{WORKSPACE}"
    sh "scm load --username #{USER} --password #{PASSWORD} #{WORKSPACE}@#{REPO}"
  end

  def get_logs
    `scm compare ws #{WORKSPACE} stream #{STREAM} --password #{PASSWORD} --include-types s`.
      lines.map { |line| Log.new(line) }
  end

  def change_working_copy_to_revision(revision)
    sh "scm accept --password #{PASSWORD} --changes #{revision}"
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
