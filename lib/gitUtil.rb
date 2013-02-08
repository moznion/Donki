class GitUtil
  include DirUtil

  attr_writer :repo_url
  attr_writer :repo_name

  def initialize(target_dir, repo_url = nil, repo_name=nil)
    @target_dir = switchDirectory(target_dir)
    @repo_url   = repo_url
    @repo_name  = repo_name
  end

  def clone(branch)
    opts = Hash.new
    opts[:depth] = 1 if branch.nil?
    ::Git.clone(@repo_url, insertSlash(@target_dir, @repo_name), opts)
    self.checkout(branch) unless branch.nil?
  end

  def checkout(branch)
    g = ::Git.open(insertSlash(@target_dir, @repo_name))
    g.checkout(branch)
  end

  def pull(branch_name='master')
    remote = 'origin'
    g = ::Git.open(insertSlash(@target_dir, @repo_name))
    g.fetch(remote)
    g.merge(remote + '/' + branch_name)
  end
end

