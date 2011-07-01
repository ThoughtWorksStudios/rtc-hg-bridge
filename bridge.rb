#!/usr/bin/env ruby

require 'fileutils'
require 'optparse'

HG_REPO = 'http://localhost:8000'

module Shell
  def sh command
    system(command) or raise "Command failed with status #{$?}: [#{command}]"
  end
end

class Bridge
  include FileUtils
  include Shell

  def initialize(opts)
    @opts = opts
    @scm = SCM.new
  end

  def init
    File.exists? directory and rm_r directory
    mkdir directory
    cd directory do
      @scm.make_working_copy
      sh "hg init"
      push_change 'Initial bridge checkin.'
    end
  end

  def run
    cd directory do
      logs = @scm.get_logs
      logs.each do |log|
        puts "Syncing #{log.revision}"
        @scm.change_working_copy_to_revision(log.revision)
        push_change '#{log.revision}: #{log.message}'
      end
    end
  end

  private
  def push_change message
    sh "hg addremove --quiet --exclude .jazz5 --exclude .metadata"
    sh "hg commit -m '#{message}' -ubridge"
    sh "hg push --quiet #{HG_REPO}"
  end

  def directory() @opts[:directory] end
end

class SCM
  include Shell

  REPO = 'https://localhost:9443/ccm'
  USER = 'ben'
  PASSWORD = 'ben'
  STREAM = "'BRM Stream'"
  WORKSPACE = 'bridge-workspace-2'

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
      parse = /\(([0-9]+)\) (.*)/.match(line)
      @revision = parse[1]
      @message = parse[2]
    end
  end
end

if __FILE__ == $0
  action = nil
  options = {}

  optparse = OptionParser.new do|opts|
    opts.banner = "Usage: #{$0} [--init | --run] [parameters]"
    opts.separator ''
    opts.separator 'Actions:'
    opts.separator '  give one'

    opts.on('-i', '--init', 'Initialize the bridge') do
      action = :init
    end
    opts.on('-r', '--run', 'Run the bridge') do
      action = :run
    end

    opts.separator ''
    opts.separator 'Parameters:'
    opts.separator '  all mandatory'

    opts.on('-d', '--directory DIRECTORY', 'Working directory',
            '  Created or emptied on initialization.', '  Do not delete between runs.') do |dir|
      options[:directory] = dir
    end

    opts.on( '-h', '--help', 'Display this help' ) do
      puts opts
      exit
    end
  end

  optparse.parse(ARGV)

  unless action
    puts opts
    exit 1
  end

  Bridge.new(options).send(action)
end

puts __FILE__
puts $0
