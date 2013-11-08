namespace :rvm do

  desc "Install RVM"
  task :install do
    run "#{sudo_ops} '\\curl -L https://get.rvm.io | bash'"
    run "#{sudo_ops} 'rvm reload'"
  end   

  desc "Setup RVM"
  task :setup do
    ruby_version = get_deploy_config_value('ruby/version')
    
    upload "#{support_files_dir}/rvm", "#{rvm_tmp_dir}/support", { via: :scp, recursive: true }
    
    run "#{sudo_ops} 'rvm install #{ruby_version}'"
    run "#{sudo_ops} 'rvm ruby-#{ruby_version} --default'"
    run "#{sudo_ops} 'rvm use ruby-#{ruby_version} && gem install bundler'"
    run "#{sudo_ops} 'rvm use ruby-#{ruby_version} && gem install rake'"
    run "#{sudo_ops} 'rvm use ruby-#{ruby_version} && gem install unicorn'"
    run "#{sudo_ops} 'cp #{rvm_tmp_dir}/support/home/user/bashrc #{ops_home_dir}/.bashrc'"
    run "#{sudo_ops} 'cp #{rvm_tmp_dir}/support/home/user/rvmrc #{ops_home_dir}/.rvmrc'"
    run "#{sudo_ops} 'rvm rvmrc warning ignore all.rvmrcs'"
  end
  before 'rvm:setup', 'rvm:create_tmp_dir'
  before 'rvm:setup', "ops_user:sudo_enable"
  after 'rvm:setup', "ops_user:sudo_disable"

  task :create_tmp_dir do
    set :rvm_tmp_dir, "#{app_tmp_dir}/rvm"
    run "#{sudo} rm -rf #{rvm_tmp_dir}"
    run "mkdir -p #{rvm_tmp_dir}"    
  end
  
end
