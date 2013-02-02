#!/usr/bin/env ruby

require 'git'
require 'json'
require 'fileutils'

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

  def getReposName(repos_fullpath)
    repos_fullpath.split('/')[-1].sub(/\.git$/, '')
  end

  def removeDir(dir)
      FileUtils.remove_entry_secure(dir, true)
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
    ::Git.clone(@repos, insertSlash(@target_dir, getReposName(@repos)))
  end

  def pull
    remote      = 'origin'
    branch_name = 'master'
    g = ::Git.open(insertSlash(@target_dir, getReposName(@repos)))
    g.fetch(remote)
    g.merge(remote + '/' + branch_name)
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
  include DirUtil

  def initialize(configurations)
    @git            = GitUtil.new(configurations['targetDir'])
    @repositories   = configurations['repositories']
    @target_dir     = configurations['targetDir']
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

  def clean
    dir_entries = Dir::entries(@target_dir)
    dir_entries.delete_if{ |entry| /^\.\.?$/ =~ entry }

    repositories_name = []
    @repositories.each { |repos| repositories_name.push(getReposName(repos)) }

    remove_targets = dir_entries - repositories_name
    if remove_targets.empty?
      puts 'All clean!'
      return
    end
    puts 'Following will be removed.'
    remove_targets.each { |target| puts '- ' + target }
    print "\nOK? [y/n] "
    if ($stdin.gets.chomp == 'y')
      remove_targets.map! { |target| target = insertSlash(@target_dir, target) }
      remove_targets.each do |target|
        removeDir(target)
        puts "Removed: #{target}"
      end
    end
    puts "Done!"
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
  when 'clean'
    script_cellar.clean
  else
    abort("Invalid command : " + command)
  end
end
