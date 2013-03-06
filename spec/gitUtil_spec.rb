#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe GitUtil do
  include GitUtil

  let(:current_dir) { File.expand_path(File.dirname(__FILE__)) }
  let(:repository_name) { 'Donki_test' }
  let(:expected_installed_dir) { current_dir + '/' + repository_name }
  let(:repository_location) { current_dir + '/resources/test_repository' }

  before :each do
    git_clone(
      branch: 'master',
      repo_url: repository_location,
      repo_name: repository_name,
      target_dir: current_dir
    )
  end

  after :each do
    FileUtils.remove_entry_secure(expected_installed_dir)
  end

  context '#git_clone' do
    it 'clones remote repository rightly' do
      FileTest::directory?(expected_installed_dir)
    end
  end

  context '#git_checkout' do
    it 'checkout specified branch' do
      git_checkout(
        target_dir: current_dir,
        repo_name: repository_name,
        branch: 'branch_to_test'
      );
      Dir.chdir(expected_installed_dir)
      `git rev-parse --abbrev-ref HEAD`.chomp!.should eq 'branch_to_test'
      Dir.chdir(expected_installed_dir + '/../')
    end
  end

  context '#git_pull' do
    # FIXME It should be more effective test...
    it 'pulls remote repository rightly' do
      git_pull(
        branch: 'branch_to_test',
        remote: repository_location,
        repo_name: repository_name,
        target_dir: current_dir
      );
    end
  end
end
