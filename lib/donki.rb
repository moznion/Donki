class Donki < DonkiUtil
  include DirUtil

  def initialize(configurations, protocol)
    @git              = GitUtil.new
    @registered_repos = configurations['repositories']
    @default_dir      = configurations['default_directory']
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
        @git.clone(
          branch: repo_branch,
          repo_url: protocolWrapper(repo_url),
          repo_name: repo_name,
          target_dir: switchTargetDir(target_dir),
        )
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

    installed_repos = getInstalledReposNames(getRegisteredReposFullPaths)
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
          @git.pull(
            branch: repo_branch,
            remote: protocolWrapper(repo_url),
            repo_name: repo_name,
            target_dir: switchTargetDir(target_dir),
          )
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
        registered_repos_fullpath = getRegisteredReposFullPaths

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
    installed_repos = getInstalledReposNames(getRegisteredReposFullPaths)
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
    "default_directory": "#{ENV['HOME']}/.donki",
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
end
