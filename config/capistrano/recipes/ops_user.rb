namespace :ops_user do

  desc "Install ops user"
  task :install do
    begin; run "#{sudo} userdel -r -f ops"; rescue; end;
    begin; run "#{sudo} groupdel ops"; rescue; end;
    
    run "#{sudo} groupadd ops";
    run "#{sudo} useradd -d #{ops_home_dir} -m ops -g ops -s /bin/bash"
    run "#{sudo} cp -r #{pro_home_dir}/.ssh #{ops_home_dir}/.ssh"
    run "#{sudo} chown -R ops #{ops_home_dir}/.ssh"
    run "#{sudo} chgrp -R ops #{ops_home_dir}/.ssh"
    
    run "#{sudo} rm -rf #{app_root_dir}"
    run "#{sudo} mkdir -p #{app_root_dir}"
    run "#{sudo} chown -R ops #{app_root_dir}"
    run "#{sudo} chgrp -R ops #{app_root_dir}"  
    run "#{sudo} chmod 775 #{app_root_dir}"   
  end
  
  task :setup do
    ops_user_tmp_dir = "#{app_tmp_dir}/ops_user"
    
    run "mkdir -p #{ops_user_tmp_dir}"    
    
    upload "#{support_files_dir}/ops_user", "#{ops_user_tmp_dir}/support", { via: :scp, recursive: true }

    run %Q{#{sudo_ops} 'cp -r #{ops_user_tmp_dir}/support/ssh/* #{ops_home_dir}/.ssh'}
    run %Q{#{sudo_ops} 'chmod 600 #{ops_home_dir}/.ssh/github_rsa'}
    run %Q{#{sudo_ops} 'chmod 600 #{ops_home_dir}/.ssh/config'}
    run %Q{#{sudo_ops} 'chmod 644 #{ops_home_dir}/.ssh/known_hosts'}
    
    run %Q{#{sudo_ops} 'mkdir -p #{app_root_dir}/runtime'}
    run %Q{#{sudo_ops} 'touch ~/.bash_profile ; touch ~/.profile '}
    
    run %Q{#{sudo_ops} 'sed -i "/^source/d" ~/.bash_profile'}
    run %Q{#{sudo_ops} "echo 'source ~/.profile' >> ~/.bash_profile"}
  end
  
  task :sudo_enable do
    upload_support_file('ops_user', 'etc/sudoers.d', 'ops-user', true)
    run "#{sudo} chmod 440 /etc/sudoers.d/ops-user"
  end
  
  task :sudo_disable do
    run "#{sudo} rm /etc/sudoers.d/ops-user"
  end
  
end

