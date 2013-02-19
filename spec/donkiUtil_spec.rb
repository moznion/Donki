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
      expected = {
        repo_url:  'https://example.com/user/repository',
        repo_name: 'repository',
        target_dir: nil,
        after_exec: nil,
        repo_branch: nil,
        exclude_uninstall: nil,
      }
      got.should eq expected
    end

    it 'parse full described hash' do
      hash = {
        'url'  => 'https://example.com/user/repository',
        'name' => 'foo',
        'branch' => 'develop',
        'target' => '~/tmp',
        'after_exec' => 'mvn install',
        'exclude_uninstall' => 'false',
      }
      got = donki_util.send(:parseRepositoryInfo, hash)
      expected = {
        repo_url:  'https://example.com/user/repository',
        repo_name: 'foo',
        target_dir: '~/tmp',
        after_exec: 'mvn install',
        repo_branch: 'develop',
        exclude_uninstall: 'false',
      }
      got.should eq expected
    end

    it 'parse hash that several omitted' do
      hash = {
        'url'  => 'https://example.com/user/repository',
      }
      got = donki_util.send(:parseRepositoryInfo, hash)
      expected = {
        repo_url:  'https://example.com/user/repository',
        repo_name: 'repository',
        target_dir: nil,
        after_exec: nil,
        repo_branch: nil,
        exclude_uninstall: nil,
      }
      got.should eq expected
    end

    it 'does not have url value' do
      hash = Hash.new
      got = donki_util.send(:parseRepositoryInfo, hash)
      expected = {
        repo_url:  nil,
        repo_name: nil,
        target_dir: nil,
        after_exec: nil,
        repo_branch: nil,
        exclude_uninstall: nil,
      }
      got.should eq expected
    end
  end
end
