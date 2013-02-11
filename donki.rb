#!/usr/bin/env ruby

require 'git'
require 'json'
require 'fileutils'
require File.expand_path(File.dirname(__FILE__)) + '/lib/dirUtil'
require File.expand_path(File.dirname(__FILE__)) + '/lib/gitUtil'
require File.expand_path(File.dirname(__FILE__)) + '/lib/configure'
require File.expand_path(File.dirname(__FILE__)) + '/lib/donkiUtil'
require File.expand_path(File.dirname(__FILE__)) + '/lib/donki'

COMMAND = ARGV[0]
arguments = ARGV[1, ARGV.length]
PROFILE_LOCATION = "#{ENV['HOME']}/.donkirc"

if COMMAND.nil?
  print "Usage: ./donki.rb [command]\n\n"
  puts "Try `./donki.rb --help`"
  exit
end

if COMMAND == '--help'
  print "Usage: ./donki.rb [options] [command]\n\n"
  puts <<-HELP_MSG
Commands
    init                              Initialize
    install                           Install the all of repositories that are registered in rc file
    update [repository(s) name]       Update installed repositories
                                      If [repositorie(s) name] is not specified, then update the all of registered repositories
    uninstall [repository(s) name]    Uninstall repositories
                                      If [repositorie(s) name] is not specified, then uninstall the all of repositories
    reinstall                         Install the all of repositories after remove the all of them
    list                              Show the list of installed repositories

Options
    -p=[protocol]                     This option can specify using protocol. (Now, 'git' and 'https' protocol are available)
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
when 'list'
  donki.list
when 'uninstall'
  donki.uninstall(arguments)
else
  abort("Invalid command : " + COMMAND)
end
