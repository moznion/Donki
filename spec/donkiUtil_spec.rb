#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe DonkiUtil do

  include DirUtil

  let(:donki_util) { DonkiUtil.new }

  context '#protocol_wrapper' do
    it 'switch protocol to git from https' do
      got = donki_util.send(:protocol_wrapper, 'https://example.com/user/foo.git', 'git')
      expected = 'git://example.com/user/foo.git'
      got.should eq expected
    end

    it 'switch protocol to git from git' do
      got = donki_util.send(:protocol_wrapper, 'git://example.com/user/foo.git', 'git')
      expected = 'git://example.com/user/foo.git'
      got.should eq expected
    end

    it 'switch protocol to git from ssh' do
      got = donki_util.send(:protocol_wrapper, 'git@example.com:user/foo.git', 'git')
      expected = 'git://example.com/user/foo.git'
      got.should eq expected
    end

    it 'switch protocol to https from https' do
      got = donki_util.send(:protocol_wrapper, 'https://example.com/user/foo.git', 'https')
      expected = 'https://example.com/user/foo.git'
      got.should eq expected
    end
    it 'switch protocol to https from git' do
      got = donki_util.send(:protocol_wrapper, 'git://example.com/user/foo.git', 'https')
      expected = 'https://example.com/user/foo.git'
      got.should eq expected
    end

    it 'switch protocol to https from ssh' do
      got = donki_util.send(:protocol_wrapper, 'git@example.com:user/foo.git', 'https')
      expected = 'https://example.com/user/foo.git'
      got.should eq expected
    end

    it 'switch protocol to ssh from https' do
      got = donki_util.send(:protocol_wrapper, 'https://example.com/user/foo.git', 'ssh')
      expected = 'git@example.com:user/foo.git'
      got.should eq expected
    end

    it 'switch protocol to ssh from git' do
      got = donki_util.send(:protocol_wrapper, 'git://example.com/user/foo.git', 'ssh')
      expected = 'git@example.com:user/foo.git'
      got.should eq expected
    end

    it 'switch protocol to ssh from ssh' do
      got = donki_util.send(:protocol_wrapper, 'git@example.com:user/foo.git', 'ssh')
      expected = 'git@example.com:user/foo.git'
      got.should eq expected
    end

    it 'through if given invalid protocol' do
      got = donki_util.send(:protocol_wrapper, 'https://example.com/user/foo.git', 'irc')
      expected = 'https://example.com/user/foo.git'
      got.should eq expected
    end
  end

  context '#parseRepositoryInfo' do
    it 'convert from not hash' do
      got = donki_util.send(:parseRepositoryInfo, 'https://example.com/user/repository')
      got.should eq ['https://example.com/user/repository', 'repository', nil, nil, nil]
    end

    it 'parse full described hash' do
      hash = {
        'url'  => 'https://example.com/user/repository',
        'name' => 'foo',
        'branch' => 'develop',
        'target' => '~/tmp',
        'exclude_uninstall' => 'false',
      }
      got = donki_util.send(:parseRepositoryInfo, hash)
      got.should eq ['https://example.com/user/repository', 'foo', 'develop', '~/tmp', 'false']
    end

    it 'parse hash that several omitted' do
      hash = {
        'url'  => 'https://example.com/user/repository',
      }
      got = donki_util.send(:parseRepositoryInfo, hash)
      got.should eq ['https://example.com/user/repository', 'repository', nil, nil, nil]
    end

    it 'does not have url value' do
      hash = Hash.new
      got = donki_util.send(:parseRepositoryInfo, hash)
      got.should eq [nil, nil, nil, nil, nil]
    end
  end
end
