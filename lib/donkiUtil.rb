class DonkiUtil
  include DirUtil

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

  def getRegisteredReposFullPaths
    registered_repos_fullpaths = []
    @registered_repos.each do |repo|
      repo_info = parseRepositoryInfo(repo)
      registered_repos_fullpaths.push(insertSlash(switchTargetDir(repo_info[:target_dir]), repo_info[:repo_name]))
    end
    return registered_repos_fullpaths
  end
  private :getRegisteredReposFullPaths

  def removeRegisteredRepos
    @registered_repos.each do |repo|
      repo_info = parseRepositoryInfo(repo)
      unless repo_info[:exclude_uninstall]
        removeDir(insertSlash(switchTargetDir(repo_info[:target_dir]), repo_info[:repo_name]))
      end
    end
  end
  private :removeRegisteredRepos

  def switchTargetDir(target_dir)
    target_dir = @default_dir if target_dir.nil?
    return target_dir
  end
  private :switchTargetDir

  def protocol_wrapper(repo_url, protocol)
    url = repo_url.clone
    if protocol == 'git'
      url.sub!(%r!^.+?://!, 'git://') # From http
      url.sub!(%r!^.+?@(.*?):(.*?)!, 'git://\1/\2') # From ssh
    elsif protocol == 'https'
      url.sub!(%r!^.*?://!, 'https://') # From git
      url.sub!(%r!^https://(.*?):(.*)!, 'https://\1/\2')
      url.sub!(%r!^.+?@(.*?):(.*?)!, 'https://\1/\2') # From ssh
    elsif protocol == 'ssh'
      url.sub!(%r!^.*?://(.*?)/(.*?/.*?)$!, 'git@\1:\2'); # From https or git
    elsif !protocol.nil?
      $stderr.puts '! Invalid protocol was specified.'
      $stderr.puts '! Default protocol will be used.'
    end
    return url
  end
  private :protocol_wrapper

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
      # JSON and YAML must have "url" key
      unless repo.key?('url')
        $stderr.puts '! Detected invalid element. JSON type element must have "url" key.'
        return {
          repo_url: nil,
          repo_name: nil,
          target_dir: nil,
          after_exec: nil,
          repo_branch: nil,
          exclude_uninstall: nil,
        }
      end
      repo_url = repo['url']

      if repo.key?('name')
        repo_name = repo['name']
      else
        repo_name = getRepoName(repo_url)
      end

      repo_branch       = repo['branch']
      target_dir        = repo['target']
      exclude_uninstall = repo['exclude_uninstall']
      after_exec        = repo['after_exec']
    else
      repo_url         = repo
      repo_name        = getRepoName(repo)
    end

    return {
      repo_url: repo_url,
      repo_name: repo_name,
      target_dir: target_dir,
      after_exec: after_exec,
      repo_branch: repo_branch,
      exclude_uninstall: exclude_uninstall,
    }
  end
  private :parseRepositoryInfo
end
