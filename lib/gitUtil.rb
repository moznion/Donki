class GitUtil
  include DirUtil

  def clone(args={})
    branch = args[:branch]
    repo_url = args[:repo_url]
    repo_name = args[:repo_name]
    target_dir = args[:target_dir]
    opts = {
      depth: 1,
    }
    ::Git.clone(repo_url, insertSlash(target_dir, repo_name), opts)
    self.checkout(target_dir: target_dir, repo_name: repo_name, branch: branch) unless branch.nil?
  end

  def checkout(args={})
    g = ::Git.open(insertSlash(args[:target_dir], args[:repo_name]))
    g.checkout(args[:branch])
  end

  def pull(args={})
    g = ::Git.open(insertSlash(args[:target_dir], args[:repo_name]))
    g.fetch(args[:remote])

    branch = args[:branch]
    if branch.nil?
      g.merge('origin/master')
    else
      g.merge('origin/' + branch)
    end
  end
end
