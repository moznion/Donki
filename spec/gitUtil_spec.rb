#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe GitUtil do
  include GitUtil

  let(:current_dir) { File.expand_path(File.dirname(__FILE__)) }
  let(:expected_installed_dir) { current_dir + '/Donki_test' }

  before :all do
      git_clone(
        branch: 'master',
        repo_url: 'git@github.com:moznion/Donki.git',
        repo_name: 'Donki_test',
        target_dir: current_dir
      );
  end

  context '#git_clone' do
    it 'clones remote repository rightly' do
      FileTest::directory?(expected_installed_dir)
    end
  end

  context '#git_checkout' do
    before :all do
      Dir.chdir(expected_installed_dir)
    end

    it 'checkout specified branch' do
      git_checkout(
        branch: 'branch_to_test',
        repo_name: 'Donki_test',
        target_dir: current_dir
      );
      `git rev-parse --abbrev-ref HEAD`.chomp!.should eq 'branch_to_test'
    end

    after :all do
      Dir.chdir(expected_installed_dir + '/../')
    end
  end

  context '#git_pull' do
    # FIXME It should be more effective test...
    it 'pulls remote repository rightly' do
      git_pull(
        branch: 'master',
        remote: 'git@github.com:moznion/Donki.git',
        repo_name: 'Donki_test',
        target_dir: current_dir
      );
    end
  end

  after :all do
    FileUtils.remove_entry_secure(expected_installed_dir)
  end
end
