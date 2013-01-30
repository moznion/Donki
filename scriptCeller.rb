#!/usr/bin/env ruby

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
      @dir = @repos.split('/')[-1].split('.')[0];
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

end

# clone repos
git = Celler::Git.new('git://github.com/moznion/vimrc.git')
git.clone
