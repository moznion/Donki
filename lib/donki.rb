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
    @registered_repos.each do |repo|
      repo_url, repo_name, repo_branch = parseRepositoryInfo(repo)

      # When detect invalid JSON
      next if repo_url.nil?

      begin
        @git.repo_url  = protocolWrapper(repo_url)
        @git.repo_name = repo_name
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
    @registered_repos.each do |repo|
      repo_url, repo_name, repo_branch = parseRepositoryInfo(repo)

      # When detect invalid JSON
      next if repo_url.nil?

      begin
        if args.empty? || args.include?(repo_name)
          @git.repo_name = repo_name
          remote = protocolWrapper(repo_url)
          if repo_branch.nil?
            @git.pull(remote)
          else
            @git.pull(remote, repo_branch)
          end
        end
      rescue ArgumentError
        puts "! Not installed yet: #{getRepoName(repo)}"
      rescue Git::GitExecuteError => git_ex_msg
        $stderr.puts "! #{git_ex_msg}"
      end
    end
  end

  def clean
    remove_targets = getExistRepos - getRegisteredRepos
    if remove_targets.empty?
      puts 'All clean!'
      return
    end
    diag = "Following will be removed.\n"
    remove_targets.each { |target| diag. << '- ' << target << "\n" }
    executeWhenYes(diag) do
      remove_targets.map! { |target| target = insertSlash(@target_dir, target) } # Construct the directory path
      remove_targets.each do |target|
        removeDir(target)
        puts "Removed: #{target}"
      end
      puts "Done!"
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
        registered_repos = getRegisteredRepos
        args.each do |repo|
          if registered_repos.include?(repo)
            removeDir(insertSlash(@target_dir,repo))
          else
            $stderr.puts "! Not registered such a repository: #{repo}"
          end
        end
      end
    end
  end

  def list
    installed_repos = getRegisteredRepos & getExistRepos
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

  def getExistRepos
    Dir::entries(@target_dir).delete_if{ |repo| /^\.\.?$/ =~ repo } # ignoring '.' and '..'
  end
  private :getExistRepos

  def getRegisteredRepos
    registered_repos = []
    @registered_repos.each do |repo|
      if repo.instance_of?(Hash)
        if repo.key?('name')
          registered_repos.push(repo['name'])
        elsif repo.key?('url')
          registered_repos.push(getRepoName(repo['url']))
        else
          $stderr.puts '! Detected invalid element.'
        end
      else
        registered_repos.push(getRepoName(repo))
      end
    end
    return registered_repos
  end
  private :getRegisteredRepos

  def removeRegisteredRepos
    registered_repos = getRegisteredRepos
    registered_repos.map! { |target| target = insertSlash(@target_dir, target) }
    registered_repos.each { |remove_target| removeDir(remove_target) }
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
        return nil, nil, nil
      end
      repo_url = repo['url']

      if repo.key?('name')
        repo_name = repo['name']
      else
        repo_name = getRepoName(repo_url)
      end

      repo_branch = repo['branch'] if repo.key?('branch')
    else
      repo_url    = repo
      repo_name   = getRepoName(repo)
      repo_branch = nil
    end

    return repo_url, repo_name, repo_branch
  end
  private :parseRepositoryInfo

  def protocolWrapper(repo_url)
    url = repo_url.clone
    if @protocol == 'git'
      url.sub!(%r!^https://!, 'git://')
    elsif @protocol == 'https'
      url.sub!(%r!^git://!, 'https://')
      url.sub!(%r!^https://(.*?):(.+)!, 'https://\1/\2')
    end
    return url
  end
  private :protocolWrapper
end

