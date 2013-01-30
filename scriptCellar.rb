#!/usr/bin/env ruby

require 'git'
require 'json'

module DirUtil
  def switchDirectory(dir)
    defaultPath = './'  # FIXME

    if dir.nil?
      return defaultPath
    end

    makeNotExistDir(dir)
    return dir
  end

  def makeNotExistDir(dir)
    unless FileTest::directory?(dir)
      Dir::mkdir(dir)
    end
  end

  def removeTrailSlash(str)
    str.sub(%r!/$!, '')
  end

  def insertSlash(parent, child)
    removeTrailSlash(parent) + '/' + child
  end
end

class GitUtil
  include DirUtil

  attr_writer :repos

  def initialize(target_dir, git_repos = nil)
    @target_dir = switchDirectory(target_dir)
    @repos      = git_repos
  end

  def clone
    ::Git.clone(@repos, insertSlash(@target_dir, getReposName))
  end

  def pull
    remote      = 'origin'
    branch_name = 'master'
    g = ::Git.open(insertSlash(@target_dir, getReposName))
    g.fetch(remote)
    g.merge(remote + '/' + branch_name)
  end

  private
  def getReposName
    @repos.split('/')[-1].sub(/\.git$/, '')
  end
end

# TODO correspond to YAML?
class Configure
  def initialize(filename)
    @config_file = filename
  end

  def parse
    JSON.parse(fetchConfigFile)
  end

  private
  def fetchConfigFile
    File.open(@config_file, :encoding => Encoding::UTF_8) { |file| file.read }
  end
end

class ScriptCellar
  def initialize(configurations)
    @git            = GitUtil.new(configurations['targetDir'])
    @repositories   = configurations['repositories']
  end

  def install
    @repositories.each do |repos|
      @git.repos = repos
      @git.clone
    end
  end

  def update
    @repositories.each do |repos|
      @git.repos = repos
      @git.pull
    end
  end
end

# FIXME CHECK
# Path: absolute? or relative?
COMMANDS = ARGV
PROFILE_LOCATION = './.script_cellar_profile' # FIXME rc file name and location

if COMMANDS.empty?
  abort("Please specify the command") # FIXME change error message
end

configure = Configure.new(PROFILE_LOCATION)
configurations = configure.parse
script_cellar = ScriptCellar.new(configurations)

COMMANDS.each do |command|
  case command
  when 'install'
    script_cellar.install
  when 'update'
    script_cellar.update
  else
    abort("Invalid command : " + command)
  end
end
