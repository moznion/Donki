#!/usr/bin/env ruby

require 'json'
require 'grit'
include Grit

module Celler
  class Git
    def initialize(git_repos, temp_dir='./')
      @repos    = git_repos
      @temp_dir = temp_dir
    end

    def extractDirName
      # e.g.
      #   git://github.com/foo/bar.git
      #                        ~~~
      #                         |-- extract
      @dir = @repos.split('/')[-1].split('.')[0]
    end

    def clone
      repo = Grit::Git.new(@temp_dir)
      extractDirName
      repo.clone({
        :quiet => false,
        :verbose => true,
        :progress => true,
        :branch => "master"
      }, @repos, @dir)
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
end

config = Celler::Configure.new('./.script_cellar_profile') # FIXME rc file name and location
profiles = config.parse

repositories = profiles['repositories']
repositories.each do |repos|
  git = Celler::Git.new(repos)
  git.clone
end
