require 'bundler/capistrano'
require 'capistrano-unicorn'

# Import helpers
load 'config/capistrano/helpers/methods'
load 'config/capistrano/helpers/tasks'

# Import project recipes
load 'config/capistrano/recipes/base'
load 'config/capistrano/recipes/nginx'
load 'config/capistrano/recipes/ops_user'
load 'config/capistrano/recipes/postgresql'
load 'config/capistrano/recipes/rvm'
load 'config/capistrano/recipes/unicorn'

# Global Configuration
set :deploy_config, YAML::load(File.open('config/capistrano/deploy.yml'))
set :use_sudo, false  
set :sudo_ops, "#{sudo} su - ops -c "
set :support_files_dir, File.expand_path('config/capistrano/support/')
set :template_files_dir, File.expand_path('config/capistrano/templates/')
set :ssh_keys_dir, File.expand_path('config/capistrano/ssh_keys')
set :ssl_certs_dir, File.expand_path('config/capistrano/ssl_certs')
set :scm, 'git'
set :branch, :master
set :rails_env, :production

default_run_options[:pty] = true
ssh_options[:forward_agent] = true  

namespace :deploy do
  
  namespace :provision do

    task :prompt_for_context do
      prompt_for_common_context
    end
    
    task :assign_config_vars do
      assign_common_config_vars
      set :user, get_deploy_config_value('server_target/pro_user')
      set :pro_home_dir, get_deploy_config_value('server_target/pro_home_dir')
    end
    after 'deploy:provision:prompt_for_context', 'deploy:provision:assign_config_vars'
    
    task :install do
      base.install  
      ops_user.install
      rvm.install
      postgresql.install
      nginx.install
    end
    before 'deploy:provision:install', 'deploy:provision:prompt_for_context'
    
    task :setup do
      ops_user.setup
      rvm.setup
      postgresql.setup
      nginx.setup
      unicorn.setup       
    end
    before 'deploy:provision:setup', 'deploy:provision:prompt_for_context' 
  end
  
  namespace :db do
    
    task :init, roles: :db do
      run "cd #{current_path} && RAILS_ENV=production bundle exec rake db:drop db:create db:migrate db:seed"
    end
    before 'deploy:db:init', 'deploy:prompt_for_context'
    
  end
  
  # Additional Setup tasks  
  task :prompt_for_context do
    prompt_for_common_context([:web, :app, :db], { primary: true, no_release: false })
  end

  task :assign_config_vars do
    assign_common_config_vars
    set :user, 'ops'
  end
  after 'deploy:prompt_for_context', 'deploy:assign_config_vars'

  task :setup_app_config do
    run "mkdir -p #{shared_path}/config"
    put_template("#{template_files_dir}/app.yml.erb", "#{shared_path}/config/app.yml")
  end
  after 'deploy:setup', 'deploy:setup_app_config'

  task :deploy_app_config do
    run "rm -f #{release_path}/config/app.yml"
    run "ln -nfs #{shared_path}/config/app.yml #{release_path}/config/app.yml"
  end
  after 'deploy:finalize_update', 'deploy:deploy_app_config'

  before 'deploy', 'deploy:prompt_for_context'
  before 'deploy:setup', 'deploy:prompt_for_context'
  
  after 'deploy', 'deploy:cleanup'
  after 'deploy:restart', 'unicorn:reload'
  after 'deploy:restart', 'unicorn:restart'    
end
