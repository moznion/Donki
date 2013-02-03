#!/usr/bin/env ruby

require 'git'
require 'json'
require 'fileutils'
require './lib/dirUtil'
require './lib/gitUtil'
require './lib/configure'

class Donki
  include DirUtil

  def initialize(configurations)
    @git              = GitUtil.new(configurations['targetDir'])
    @registered_repos = configurations['repositories']
    @target_dir       = configurations['targetDir']
  end

  def install
    @registered_repos.each do |repo|
      begin
        @git.repo = repo
        @git.clone
      rescue Git::GitExecuteError
        puts "Already installed: #{getRepoName(repo)}"
      end
    end
  end

  def update
    @registered_repos.each do |repo|
      begin
        @git.repo = repo
        @git.pull
      rescue ArgumentError
        puts "Not installed yet: #{getRepoName(repo)}"
      end
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

  def self.init
    config_file = ENV['HOME'] + '/.donkirc'
    if File.exist?(config_file)
      puts 'Already initialized.'
    else
      contents = <<-EOB
{
    "targetDir": "#{ENV['HOME']}/.donki",
    "repositories": [
    ]
}
      EOB
      open(config_file, 'w') { |file| file.write contents }
    end
  end

  def getExistRepos
    Dir::entries(@target_dir).delete_if{ |repo| /^\.\.?$/ =~ repo } # ignoring '.' and '..'
  end
  private :getExistRepos

  def getInstalledRepos
    registered_repos = []
    @registered_repos.each { |repo| registered_repos.push(getRepoName(repo)) }
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

COMMAND = ARGV[0]
ARGMENTS = ARGV[1, ARGV.length]
PROFILE_LOCATION = "#{ENV['HOME']}/.donkirc"

if COMMAND.nil?
  abort("Please specify the command") # FIXME change error message
end

if COMMAND == 'init'
  Donki.init
  exit
end

donki = Donki.new(Configure.new(PROFILE_LOCATION).parse)

case COMMAND
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
  abort("Invalid command : " + COMMAND)
end
