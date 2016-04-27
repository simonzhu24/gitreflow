desc 'Setup your GitHub account'
command :setup do |c|
  c.desc 'sets up your api token with GitHub'
  c.switch [:l, :local], default_value: false, desc: 'setup GitReflow for the current project only'
  c.switch [:e, :enterprise], default_value: false, desc: 'setup GitReflow with a Github Enterprise account'
  c.action do |global_options, options, args|
    reflow_options             = { project_only: options[:local], enterprise: options[:enterprise] }
    existing_git_include_paths = GitReflow::Config.get('include.path', all: true).split("\n")

    unless File.exist?(GitReflow::Config::CONFIG_FILE_PATH) or existing_git_include_paths.include?(GitReflow::Config::CONFIG_FILE_PATH)
      GitReflow.run "touch #{GitReflow::Config::CONFIG_FILE_PATH}"
      GitReflow.say "Created #{GitReflow::Config::CONFIG_FILE_PATH} for Reflow specific configurations", :notice
      GitReflow::Config.add "include.path", GitReflow::Config::CONFIG_FILE_PATH, global: true
      GitReflow.say "Added #{GitReflow::Config::CONFIG_FILE_PATH} to ~/.gitconfig include paths", :notice
    end

    choose do |menu|
      menu.header = "Available remote Git Server services"
      menu.prompt = "Which service would you like to use for this project?  "

      menu.choice('GitHub')    { GitReflow::GitServer.connect reflow_options.merge({ provider: 'GitHub', silent: false }) }
      menu.choice('BitBucket (team-owned repos only)') { GitReflow::GitServer.connect reflow_options.merge({ provider: 'BitBucket', silent: false }) }
    end

    GitReflow::Config.add "constants.minimumApprovals", ask("Set the minimum number of approvals (leaving blank will require approval from all commenters): "), local: reflow_options[:project_only]
    GitReflow::Config.add "constants.approvalRegex", GitReflow::GitServer::PullRequest::DEFAULT_APPROVAL_REGEX, local: reflow_options[:project_only]
    
    say("Enter the follow information associated with your remote repository: (The information is used to run 'git reflow deliver'.")
    GitReflow::Config.add "github.owner", ask("Enter the owner of the remote repository: "), local: reflow_options[:project_only]
    GitReflow::Config.add "github.repo", ask("Enter the name of the remote repository: "), local: reflow_options[:project_only]

    # Sets the user's github auth token
    GitReflow::Config.set "github.oauth-token", ask("Set the your local github authorization token: (You cannot run 'git reflow deliver' without it!) "), local: reflow_options[:project_only]
    say("Thanks! Your settings are saved to #{GitReflow::Config::CONFIG_FILE_PATH}.")
  end
end
