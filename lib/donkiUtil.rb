class DonkiUtil

  def initialize
  end
  private :initialize

  def getInstalledReposNames(registered_repos_fullpath)
    installed_repos = []
    registered_repos_fullpath.each do |repo_location|
      if File.directory?(repo_location)
        repo_name = repo_location.match(%r!([^/]+)$!)
        installed_repos.push(repo_name[1])
      end
    end
    return installed_repos
  end
  private :getInstalledReposNames

  def getRegisteredReposFullPath
    registered_repos_fullpath = []
    @registered_repos.each do |repo|
      _, repo_name, _, target_dir = parseRepositoryInfo(repo)
      registered_repos_fullpath.push(insertSlash(switchTargetDir(target_dir), repo_name))
    end
    return registered_repos_fullpath
  end
  private :getRegisteredReposFullPath

  def removeRegisteredRepos
    @registered_repos.each do |repo|
      _, repo_name, _, target_dir = parseRepositoryInfo(repo)
      removeDir(insertSlash(switchTargetDir(target_dir), repo_name))
    end
  end
  private :removeRegisteredRepos

  def switchTargetDir(target_dir)
    target_dir = @default_dir if target_dir.nil?
    return target_dir
  end
  private :switchTargetDir

  def protocolWrapper(repo_url)
    url = repo_url.clone
    if @protocol == 'git'
      url.sub!(%r!^https://!, 'git://')
    elsif @protocol == 'https'
      url.sub!(%r!^git://!, 'https://')
      url.sub!(%r!^https://(.*?):(.+)!, 'https://\1/\2')
    elsif !@protocol.nil?
      $stderr.puts '! Invalid protocol was specified.'
      $stderr.puts '! Default protocol will be used.'
    end
    return url
  end
  private :protocolWrapper

  def executeWhenYes(msg, &code)
    puts msg
    print "\nOK? [y/n] "
    if $stdin.gets.chomp == 'y'
      code.call if code
    end
  end
  private :executeWhenYes

  def parseRepositoryInfo(repo)
    if repo.instance_of?(Hash)
      # JSON must have "url" key
      unless repo.key?('url')
        $stderr.puts '! Detected invalid element. JSON type element must have "url" key.'
        return nil, nil, nil, nil
      end
      repo_url = repo['url']

      if repo.key?('name')
        repo_name = repo['name']
      else
        repo_name = getRepoName(repo_url)
      end

      repo_branch = repo['branch'] if repo.key?('branch')
      target_dir  = repo['target'] if repo.key?('target')
    else
      repo_url    = repo
      repo_name   = getRepoName(repo)
      repo_branch = nil
      target_dir  = nil
    end

    return repo_url, repo_name, repo_branch, target_dir
  end
  private :parseRepositoryInfo
end
