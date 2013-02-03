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

class Donki
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
    remove_targets = getExistRepos - getInstalledRepos
    if remove_targets.empty?
      puts 'All clean!'
      return
    end
    diag = "Following will be removed.\n"
    remove_targets.each { |target| diag. << '- ' << target << "\n" }
    executeWhenYes(diag) do
      remove_targets.map! { |target| target = insertSlash(@target_dir, target) } # Construct the directory path
      remove_targets.each do |target|
        removeDir(target)
        puts "Removed: #{target}"
      end
      puts "Done!"
    end
  end

  def reinstall
    executeWhenYes('Really do you want to reinstall?') do
      removeInstalledRepos
      self.install
    end
  end

  def uninstall(args)
    if args.empty?
      executeWhenYes('Uninstall the all of repositories.') do
        removeInstalledRepos
      end
    else
      executeWhenYes('Uninstall?') do
        registered_repos = getInstalledRepos
        args.each do |repo|
          if registered_repos.include?(repo)
            removeDir(insertSlash(@target_dir,repo))
          else
            puts "Not registered such repository: #{repo}"
          end
        end
      end
    end
  end

  def list
    installed_repos = getInstalledRepos & getExistRepos
    installed_repos.each { |repo| puts repo }
  end

  def getExistRepos
    Dir::entries(@target_dir).delete_if{ |repo| /^\.\.?$/ =~ repo } # ignoring '.' and '..'
  end
  private :getExistRepos

  def getInstalledRepos
    registered_repos = []
    @repositories.each { |repo| registered_repos.push(getReposName(repo)) }
    return registered_repos
  end
  private :getInstalledRepos

  def removeInstalledRepos
    installed_repos = getInstalledRepos
    installed_repos.map! { |target| target = insertSlash(@target_dir, target) }
    installed_repos.each { |remove_target| removeDir(remove_target) }
  end
  private :removeInstalledRepos

  def executeWhenYes(msg, &code)
    puts msg
    print "\nOK? [y/n] "
    if $stdin.gets.chomp == 'y'
      code.call if code
    end
  end
  private :executeWhenYes

end

# FIXME CHECK
# Path: absolute? or relative?
COMMANDS = ARGV[0]
ARGMENTS = ARGV[1, ARGV.length]
PROFILE_LOCATION = './.donki_profile' # FIXME rc file name and location

if COMMANDS.nil?
  abort("Please specify the command") # FIXME change error message
end

donki = Donki.new(Configure.new(PROFILE_LOCATION).parse)

case COMMANDS
when 'install'
  donki.install
when 'update'
  donki.update
when 'clean'
  donki.clean
when 'list'
  donki.list
when 'reinstall'
  donki.reinstall
when 'uninstall'
  donki.uninstall(ARGMENTS)
else
  abort("Invalid command : " + command)
end
