namespace :postgresql do

  desc "Install Postgresql"
  task :install do
    eval "#{os_type}.install"
  end

  desc "Setup Postgresql" 
  task :setup do
    password = get_deploy_config_value('postgresql/password')
    version = get_deploy_config_value('postgresql/version')
    
    run "#{sudo} pg_dropcluster --stop #{version} main"
    run "#{sudo} pg_createcluster --locale=en_US.utf8 --start #{version} main"
        
    run "#{sudo} -u postgres psql -U postgres -d postgres -c \"CREATE USER ops WITH PASSWORD '#{password}';\""
    run "#{sudo} -u postgres psql -U postgres -d postgres -c \"ALTER USER ops CREATEDB;\""
    
    upload_sudoers('postgresql', 'postgresql-ops', 'postgresql-ops')
  end

  namespace :ubuntu do
    
    task :install do
      run "#{sudo} apt-get -q -y install postgresql pgadmin3"
    end        
    
  end
  
  namespace :rhel do
    
    task :install do
      #TODO: Red Hat Enterprise Linux support 
      puts "No RHEL Postgresql support. Skipping."
    end
    
  end

end
