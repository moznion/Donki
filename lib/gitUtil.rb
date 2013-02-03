class GitUtil
  include DirUtil

  attr_writer :repo

  def initialize(target_dir, git_repo = nil)
    @target_dir = switchDirectory(target_dir)
    @repo      = git_repo
  end

  def clone
    ::Git.clone(@repo, insertSlash(@target_dir, getRepoName(@repo)))
  end

  def pull
    remote      = 'origin'
    branch_name = 'master'
    g = ::Git.open(insertSlash(@target_dir, getRepoName(@repo)))
    g.fetch(remote)
    g.merge(remote + '/' + branch_name)
  end
end

