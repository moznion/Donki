#!/usr/bin/env ruby

require 'json'
require 'grit'
include Grit

module Cellar
  class Git

    attr_writer :repos

    def initialize(target_dir, temp_dir, git_repos = nil)
      @target_dir = switchDirectory(target_dir)
      @temp_dir   = switchDirectory(temp_dir)
      @repos      = git_repos
    end

    def switchDirectory(dir)
      defaultPath = './'  # FIXME
      if dir.nil?
        return defaultPath
      else
        makeNotExistDir(dir)
      end
      return dir
    end
    private :switchDirectory

    def removeTrailSlash(str)
      str.sub(%r!/$!, '')
    end
    private :removeTrailSlash

    def makeNotExistDir(dir)
      unless FileTest::directory?(dir)
        Dir::mkdir(dir)
      end
    end
    private :makeNotExistDir

    # e.g.
    #   git://github.com/foo/bar.git
    #                        ~~~
    #                         |-- extract this!
    def extractReposName
      @repos.split('/')[-1].split('.')[0]
    end
    private :extractReposName

    def constructPath(parent, child)
      removeTrailSlash(parent) + '/' + child
    end
    private :constructPath

    def clone
      repos = Grit::Git.new(@temp_dir)
      repos.clone({
        :quiet => false,
        :verbose => true,
        :progress => true,
        :branch => "master" # <= TODO should be specifiable?
      }, @repos, constructPath(@target_dir, extractReposName))
    end

    def pull
      repos = Grit::Git.new(@temp_dir)
      repos.pull({
        :quiet => false,
        :verbose => true,
        :progress => true,
        :branch => "master" # <= TODO should be specifiable?
      }, @repos, constructPath(@target_dir, extractReposName))
    end
  end

  # TODO correspond to YAML?
  # Now, this class can handle JSON only.
  class Configure
    def initialize(filename)
      @config_file = filename
    end

    # TODO @config should be member?
    def readConfigFile
      File.open(@config_file, :encoding => Encoding::UTF_8) do |file|
        @config = file.read
      end
    end
    private :open

    def parse
      readConfigFile
      JSON.parse(@config)
    end
  end

  class Install
    def initialize(configurations)
      @configurations = configurations
    end

    def install
      git = Cellar::Git.new(@configurations['targetDir'], @configurations['tempDir'])
      repositories = @configurations['repositories']
      repositories.each do |repos|
        git.repos = repos
        git.clone
      end
    end
  end

  class Update
    def initialize(configurations)
      @configurations = configurations
    end

    def update
      git = Cellar::Git.new(@configurations['targetDir'], @configurations['tempDir'])
      repositories = @configurations['repositories']
      repositories.each do |repos|
        git.repos = repos
        git.pull
      end
    end
  end
end

# FIXME CHECK!!!!!!!!!!!!
# Path: absolute? or relative?
COMMANDS = ARGV
PROFILE_LOCATION = './.script_cellar_profile' # FIXME rc file name and location

if COMMANDS.empty?
  abort("Please specify the command") # FIXME change error message
end

configure = Cellar::Configure.new(PROFILE_LOCATION)
configurations = configure.parse

COMMANDS.each do |command|
  case command
  when 'install'
    install = Cellar::Install.new(configurations)
    install.install
  when 'update'
    update = Cellar::Update.new(configurations)
    update.update
  else
    abort("Invalid command : " + command)
  end
end
