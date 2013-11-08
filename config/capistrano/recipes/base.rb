namespace :base do

  desc "Install base"
  task :install do
    eval "#{os_type}.install"
  end

  desc "Perform system-level OS updates"
  task :os_update do
    eval "#{os_type}.os_update"
    base.reboot
  end

  desc "Reboot the system"
  task :reboot do
    run "#{sudo} reboot"
  end
        
  namespace :ubuntu do
    
    task :install do
      run "#{sudo} apt-get -q -y update"
      run "#{sudo} apt-get -q -y upgrade"
      run "#{sudo} apt-get -q -y install build-essential zlib1g-dev libssl-dev libreadline-dev libyaml-dev libcurl4-openssl-dev curl git-core python-software-properties nodejs libxml2-dev libxslt-dev libpcre3-dev libpq-dev debconf-utils unzip zip"
      
      run "#{sudo} locale-gen en_US.UTF-8"
      run "#{sudo} dpkg-reconfigure locales"

      timezone = get_deploy_config_value('server_target/timezone')
      run "echo '#{timezone}' | sudo tee /etc/timezone"
      run "#{sudo} dpkg-reconfigure --frontend noninteractive tzdata"

      run "#{sudo} apt-get -q -y install ntp"
    end  

    task :os_update do
      run "#{sudo} apt-get -q -y update"
      run "#{sudo} apt-get -q -y dist-upgrade"
    end
                  
  end
  
  namespace :rhel do
    
    task :install do
      run "#{sudo} yum update -y"
      
      begin
        run "#{sudo} curl -O http://download-i2.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm"
        run "#{sudo} rpm -ivh epel-release-6-8.noarch.rpm"
      rescue; end
      
      run "#{sudo} yum install -y libyaml-devel gcc-c++ readline-devel zlib-devel libffi-devel openssl-devel autoconf automake libtool bison git npm ntp cronie"
    
      timezone = get_deploy_config_value('server_target/timezone')
      run "#{sudo} mv -f /etc/localtime /etc/localtime.bak"
      run "#{sudo} ln -sf /usr/share/zoneinfo/#{timezone} /etc/localtime"
      
      run "#{sudo} chkconfig ntpd on"
      run "#{sudo} service ntpd start"
      
      begin; run "#{sudo} ntpdate pool.ntp.org"; rescue; end
    end    

    task :os_update do
      run "#{sudo} yum update -y"
    end
                
  end
        
end

