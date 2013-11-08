namespace :unicorn do

  task :setup, on_error: :continue do  
    unicorn_instance = "unicorn-#{application}"
    
    eval "#{os_type}.uninstall_service(unicorn_instance)"
    
    upload_template_file('unicorn', 'etc/init.d', 'unicorn-instance', unicorn_instance, true)       
    
    eval "#{os_type}.install_service(unicorn_instance)"

    upload_sudoers('unicorn', 'unicorn-application-ops', "unicorn-#{application}-ops")
  end

  namespace :ubuntu do

    def uninstall_service(unicorn_instance)
      run "#{sudo} update-rc.d -f #{unicorn_instance} remove"
      run "#{sudo} rm -f /etc/init.d/#{unicorn_instance}"
    end
    
    def install_service(unicorn_instance)
      run "#{sudo} chmod +x /etc/init.d/#{unicorn_instance}"
      run "#{sudo} update-rc.d #{unicorn_instance} defaults"
    end

  end

  namespace :rhel do

    def uninstall_service(unicorn_instance)
      run "#{sudo} rm -f /etc/init.d/#{unicorn_instance}"
    end
    
    def install_service(unicorn_instance)
      run "#{sudo} chmod +x /etc/init.d/#{unicorn_instance}"
      run "#{sudo} chkconfig --add #{unicorn_instance}"
    end

  end

end
