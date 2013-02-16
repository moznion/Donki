#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Configure do
  let(:file_location) { File.dirname(__FILE__) + '/resources/test_configure.json'}
  let(:configure_class) { Configure.new(file_location) }

  it 'can parse JSON type configure rightly' do
    configures = configure_class.parse
    repositories = configures['repositories']
    configures['default_directory'].should eq '~/.donki'
    configures['protocol'].should eq 'https'
    repositories[0].should eq 'repos1'
    repositories[1]['url'].should eq 'repos2'
    repositories[1]['name'].should eq 'foo'
    repositories[1]['branch'].should eq 'bar'
    repositories[1]['target'].should eq '~/temp'
  end
end
