namespace :unicorn do

  task :setup, on_error: :continue do  
    unicorn_instance = "unicorn-#{application}"
    
    run "#{sudo} update-rc.d -f #{unicorn_instance} remove"
    run "#{sudo} rm -f /etc/init.d/#{unicorn_instance}"
    
    upload_template_file('unicorn', 'etc/init.d', 'unicorn-instance', unicorn_instance, true)       
    
    run "#{sudo} chmod +x /etc/init.d/#{unicorn_instance}"
    run "#{sudo} update-rc.d #{unicorn_instance} defaults"

    upload_sudoers('unicorn', 'unicorn-application-ops', "unicorn-#{application}-ops")
  end

end
