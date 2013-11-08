namespace :base do

  desc "Install base"
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

  desc "Perform system-level OS updates"
  task :os_update do
    run "#{sudo} apt-get -q -y update"
    run "#{sudo} apt-get -q -y dist-upgrade"
    base.reboot
  end

  desc "Reboot the system"
  task :reboot do
    run "#{sudo} reboot"
  end
 
end

