module GitUtil
  include DirUtil

  def git_clone(args={})
    branch = args[:branch]
    repo_url = args[:repo_url]
    repo_name = args[:repo_name]
    target_dir = args[:target_dir]
    opts = {
      depth: 1,
    }
    ::Git.clone(repo_url, insertSlash(target_dir, repo_name), opts)
    self.git_checkout(target_dir: target_dir, repo_name: repo_name, branch: branch) unless branch.nil?
  end

  def git_checkout(args={})
    g = ::Git.open(insertSlash(args[:target_dir], args[:repo_name]))
    g.checkout(args[:branch])
  end

  def git_pull(args={})
    g = ::Git.open(insertSlash(args[:target_dir], args[:repo_name]))
    if args[:branch]
      g.fetch(args[:remote] + '" "' + args[:branch])
    else
      g.fetch(args[:remote])
    end

    merge_msg = g.merge('FETCH_HEAD')
    puts merge_msg

    if merge_msg.match(%r!^Already up-to-date\.$!)
      is_up_to_date = true
    else
      is_up_to_date = false
    end
  end
end
