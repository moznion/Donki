class Donki
  include DirUtil

  def initialize(configurations, protocol)
    base_dir = configurations['base_directory']
    @git              = GitUtil.new(base_dir)
    @registered_repos = configurations['repositories']
    @target_dir       = base_dir
    @protocol         = protocol || configurations['protocol']
  end

  def install
    puts 'Installing...'
    @registered_repos.each do |repo|
      repo_url, repo_name, repo_branch, target_dir = parseRepositoryInfo(repo)

      # When detect invalid JSON
      next if repo_url.nil?

      puts "- #{repo_name}"
      begin
        @git.repo_url  = protocolWrapper(repo_url)
        @git.repo_name = repo_name
        switchTargetDir(target_dir)
        @git.clone(repo_branch)
      rescue Git::GitExecuteError => git_ex_msg
        if git_ex_msg.message.match(/already\sexists\sand\sis\snot\san\sempty\sdirectory\./)
          # Already exists.
          puts "Already installed: #{repo_name}"
        elsif git_ex_msg.message.match(/did\snot\smatch\sany\sfile\(s\)\sknown\sto\sgit\./)
          # Not exists the specified branch name on the remote.
          $stderr.puts "! Branch name does not exist: '#{repo_branch}'"
          $stderr.puts "! #{repo_name} was installed as 'master' branch."
        else
          $stderr.puts "! #{git_ex_msg}"
        end
      end
    end
  end

  def update(args)
    puts 'Updating...'

    registered_repos_fullpath = getRegisteredReposFullPath
    installed_repos = getInstalledReposName(registered_repos_fullpath)

    args.each do |arg|
      unless installed_repos.include?(arg)
        $stderr.puts "! Not installed yet: #{arg}"
      end
    end

    @registered_repos.each do |repo|
      repo_url, repo_name, repo_branch, target_dir = parseRepositoryInfo(repo)

      # When detect invalid JSON
      next if repo_url.nil?

      begin
        if args.empty? || args.include?(repo_name)
          puts "- #{repo_name}"
          @git.repo_name = repo_name
          remote = protocolWrapper(repo_url)
          switchTargetDir(target_dir)
          if repo_branch.nil?
            @git.pull(remote)
          else
            @git.pull(remote, repo_branch)
          end
        end
      rescue Git::GitExecuteError => git_ex_msg
        $stderr.puts "! #{git_ex_msg}"
      rescue ArgumentError
        $stderr.puts "! Not installed yet: #{repo_name}"
      end
    end
  end

  def reinstall
    executeWhenYes('Really do you want to reinstall?') do
      removeRegisteredRepos
      self.install
    end
  end

  def uninstall(args)
    if args.empty?
      executeWhenYes('Uninstall the all of repositories.') do
        removeRegisteredRepos
      end
    else
      executeWhenYes('Uninstall?') do
        registered_repos_fullpath = getRegisteredReposFullPath

        registered_repos_fullpath.each do |repo|
          repo_name = repo.match(%r!([^/]+)$!)
          if args.include?(repo_name[1])
            removeDir(repo)
            args.delete(repo_name[1])
          end
        end

        unless args.empty?
          args.each do |arg|
            $stderr.puts "! Not registered such a repository: #{arg}"
          end
        end
      end
    end
  end

  def list
    registered_repos_fullpath = getRegisteredReposFullPath

    installed_repos = getInstalledReposName(registered_repos_fullpath)
    installed_repos.each { |repo| puts repo }
  end

  def self.init
    config_file = ENV['HOME'] + '/.donkirc'
    if File.exist?(config_file)
      puts 'Already initialized.'
    else
      puts 'Initializing...'
      contents = <<-RC
{
    "base_directory": "#{ENV['HOME']}/.donki",
    "repositories": [
    ]
}
      RC
      open(config_file, 'w') { |file| file.write contents }
      puts 'Done.'
      puts "\nPlease to make a path. Like so:"
      puts "\n\techo 'alias donki=\"#{File.expand_path(__FILE__)}\"' >> ~/.bashrc"
      puts "\nEnjoy!"
    end
  end

  def self.optionAnalyzer(args)
    # Collect valid options
    valid_opts = Hash.new
    args.each do |arg|
      if protocol = arg.match(/^-p=(.+)/)
        valid_opts[:protocol] = protocol[1]
      end
    end

    args.delete_if{ |arg| arg =~ /^\-.*$/ } # Remove all option from arguments

    return args, valid_opts
  end

  def removeRegisteredRepos
    @registered_repos.each do |repo|
      _, repo_name, _, target_dir = parseRepositoryInfo(repo)
      target_dir = @target_dir if target_dir.nil?
      removeDir(insertSlash(target_dir, repo_name))
    end
  end
  private :removeRegisteredRepos

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

  def switchTargetDir(target_dir)
    if target_dir.nil?
      @git.target_dir = @target_dir
    else
      @git.target_dir = target_dir
    end
  end
  private :switchTargetDir

  def getRegisteredReposFullPath
    registered_repos_fullpath = []
    @registered_repos.each do |repo|
      _, repo_name, _, target_dir = parseRepositoryInfo(repo)
      target_dir = @target_dir if target_dir.nil?
      registered_repos_fullpath.push(insertSlash(target_dir, repo_name))
    end
    return registered_repos_fullpath
  end
  private :getRegisteredReposFullPath

  def getInstalledReposName(registered_repos_fullpath)
    installed_repos = []
    registered_repos_fullpath.each do |repo_location|
      if File.directory?(repo_location)
        repo_name = repo_location.match(%r!([^/]+)$!)
        installed_repos.push(repo_name[1])
      end
    end
    return installed_repos
  end
  private :getInstalledReposName
end
