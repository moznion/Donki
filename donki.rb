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
    base_dir = configurations['base_directory']
    @git              = GitUtil.new(base_dir)
    @registered_repos = configurations['repositories']
    @target_dir       = base_dir
  end

  def install
    @registered_repos.each do |repo|
      repo_url, repo_name, repo_branch = parseRepositoryInfo(repo)

      # When detect invalid JSON
      next if repo_url.nil?

      begin
        @git.repo_url  = repo_url
        @git.repo_name = repo_name
        @git.clone
      rescue Git::GitExecuteError => git_ex_msg
        if git_ex_msg.message.match(/lready\sexists\sand\sis\snot\san\sempty\sdirectory\./)
          puts "Already installed: #{repo_name}"
        else
          $stderr.print "! "
          $stderr.puts git_ex_msg
        end
      end
    end
  end

  def parseRepositoryInfo(repo)
    if repo.instance_of?(Hash)
      # JSON must have "url" key
      unless repo.key?('url')
        $stderr.puts '! Detected invalid element. JSON type element must have "url" key.'
        return nil, nil, nil
      end
      repo_url = repo['url']

      if repo.key?('name')
        repo_name = repo['name']
      else
        repo_name = getRepoName(repo_url)
      end

      repo_branch = repo['branch'] if repo.key?('branch')
    else
      repo_url    = repo
      repo_name   = getRepoName(repo)
      repo_branch = nil
    end

    return repo_url, repo_name, repo_branch
  end
  private :parseRepositoryInfo

  def update
    @registered_repos.each do |repo|
      begin
        @git.repo_url = repo
        @git.repo_name = getRepoName(repo)
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
      puts 'Initializing...'
      contents = <<-RC
{
    "base_directory": "#{ENV['HOME']}/.donki",
    "repositories": [
    ]
}
      RC
      open(config_file, 'w') { |file| file.write contents }
      puts 'Done.'
      puts "\nPlease to make a path. Like so:"
      puts "\n\techo 'alias donki=\"#{File.expand_path(__FILE__)}\"' >> ~/.bashrc"
      puts "\nEnjoy!"
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
  print "Usage: ./donki.rb [command]\n\n"
  puts "Try `./donki.rb --help`"
  exit
end

# TODO improve the following help tips!
if COMMAND == '--help'
  print "Usage: ./donki.rb [command]\n\n"
  puts <<-HELP_MSG
Commands
    init                         Initialize
    install                      Install the all of repositories that are registered in rc file
    update                       Update the all of registered repositories
    clean                        Remove not registered repositories in install directory
    uninstall [repository(s)]    Uninstall repositories.
                                 If [repositorie(s)] is not specified, then uninstall the all of repositories
    reinstall                    Install the all of repositories after remove the all of them
    list                         Show the list of installed repositories
  HELP_MSG
  exit
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
