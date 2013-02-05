class GitUtil
  include DirUtil

  attr_writer :repo_url
  attr_writer :repo_name

  def initialize(target_dir, repo_url = nil, repo_name=nil)
    @target_dir = switchDirectory(target_dir)
    @repo_url   = repo_url
    @repo_name  = repo_name
  end

  def clone
    ::Git.clone(@repo_url, insertSlash(@target_dir, @repo_name))
  end

  def pull
    remote      = 'origin'
    branch_name = 'master'
    g = ::Git.open(insertSlash(@target_dir, @repo_name))
    g.fetch(remote)
    g.merge(remote + '/' + branch_name)
  end
end

