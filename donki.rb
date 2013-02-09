#!/usr/bin/env ruby

require 'git'
require 'json'
require 'fileutils'
require './lib/dirUtil'
require './lib/gitUtil'
require './lib/configure'
require './lib/donki'

COMMAND = ARGV[0]
arguments = ARGV[1, ARGV.length]
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
    update [repository(s)]       Update repositories
                                 If [repositorie(s)] is not specified, then update the all of registered repositories
    clean                        Remove not registered repositories in install directory
    uninstall [repository(s)]    Uninstall repositories
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

arguments, opts = Donki.optionAnalyzer(arguments) # Analyze options

donki = Donki.new(Configure.new(PROFILE_LOCATION).parse, opts[:protocol])

case COMMAND
when 'install'
  donki.install
when 'update'
  donki.update(arguments)
when 'reinstall'
  donki.reinstall
when 'clean'
  donki.clean
when 'list'
  donki.list
when 'uninstall'
  donki.uninstall(arguments)
else
  abort("Invalid command : " + COMMAND)
end
