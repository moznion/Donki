#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe DonkiUtil do

  let(:donki_util) { DonkiUtil.new }

  context '#protocol_wrapper' do
    it 'switch protocol to git from https' do
      got = donki_util.send(:protocol_wrapper, 'https://example.com/user/foo.git', 'git')
      expected = 'git://example.com/user/foo.git'
      got.should eq expected
    end

    it 'switch protocol to https from git' do
      got = donki_util.send(:protocol_wrapper, 'git://example.com/user/foo.git', 'https')
      expected = 'https://example.com/user/foo.git'
      got.should eq expected
    end

    it 'through if given invalid protocol' do
      got = donki_util.send(:protocol_wrapper, 'https://example.com/user/foo.git', 'irc')
      expected = 'https://example.com/user/foo.git'
      got.should eq expected
    end
  end
end
