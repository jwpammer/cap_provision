namespace :memcached do
  
  desc "Install Memcached"
  task :install do
    eval "#{os_type}.install"
  end

  desc "Setup Memcached" 
  task :setup do
    upload_sudoers('memcached', 'memcached-ops', 'memcached-ops')
  end
  
  namespace :ubuntu do
    
    task :install do
      run "#{sudo} apt-get -q -y install memcached"
    end
    
  end
  
  namespace :rhel do
    
    task :install do
      #TODO: Red Hat Enterprise Linux support 
      puts "No RHEL Memcached support. Skipping."
    end

  end

  
end