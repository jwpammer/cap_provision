namespace :nginx do
  
  desc "Install Nginx"
  task :install do
    eval "#{os_type}.install"
  end
  
  task :setup do
    set_with_prompt_default(:nginx_http_port, 'Nginx HTTP port', get_deploy_config_value('nginx/defaults/http_port'))
    set_with_prompt_default(:nginx_ssl_enabled, 'Nginx enable SSL (Y/N)', get_deploy_config_value('nginx/defaults/ssl_enabled'))

    if nginx_ssl_enabled.upcase.eql?('Y')
      set_with_prompt_default(:nginx_https_port, 'Nginx HTTPS port', get_deploy_config_value('nginx/defaults/https_port'))
      set_with_prompt_default(:nginx_ssl_crt_file, 'Nginx SSL certificate file name, relative to ap_server_management/ssl_certs', get_deploy_config_value('nginx/defaults/nginx_ssl_crt_file'))
      set_with_prompt_default(:nginx_ssl_key_file, 'Nginx SSL certificate key file name, is relative to ap_server_management/ssl_certs', get_deploy_config_value('nginx/defaults/nginx_ssl_key_file'))
      set :nginx_ssl_dir, "#{ops_home_dir}/ssl"
    end

    tmp_dirs = create_tmp_dir_structure 'nginx'

    upload_template_file('nginx', 'etc/nginx/sites-available', 'application', application, true)          
    run "#{sudo} ln -nfs /etc/nginx/sites-available/#{application} /etc/nginx/sites-enabled/#{application}"
    run "#{sudo} rm -f /etc/nginx/sites-enabled/default"

    eval "#{os_type}.insert_firewall_rule(nginx_http_port)"

    if nginx_ssl_enabled.upcase.eql?('Y')
      upload_support_file('nginx', nginx_ssl_dir, nginx_ssl_crt_file, true)
      ch_ops "#{nginx_ssl_dir}/#{nginx_ssl_crt_file}"
                  
      upload_support_file('nginx', nginx_ssl_dir, nginx_ssl_key_file, true)
      ch_ops "#{nginx_ssl_dir}/#{nginx_ssl_key_file}"

      eval "#{os_type}.insert_firewall_rule(nginx_https_port)"
    end

    upload_sudoers('nginx', 'nginx-ops', 'nginx-ops')

    run "#{sudo} service nginx restart"
  end
  
  namespace :ubuntu do
    
    task :install do
      run "#{sudo} add-apt-repository -y ppa:nginx/stable"
      run "#{sudo} apt-get -q -y update"
      run "#{sudo} apt-get -q -y install nginx"
      run "#{sudo} service nginx start"
    end

    def insert_firewall_rule(port)
      puts 'No firewall configuration update required.'
    end
    
  end
  
  namespace :rhel do
    
    task :install do
      upload_support_file('nginx', 'etc/yum.repos.d', 'nginx.repo', true, true)
      
      run "#{sudo} yum install -y nginx"
      
      upload_support_file('nginx', 'etc/nginx', 'nginx.conf', true, true)

      run "#{sudo} mkdir -p /etc/nginx/sites-available/"          
      run "#{sudo} mkdir -p /etc/nginx/sites-enabled/"
      
      run "#{sudo} service nginx start"
    end

    def insert_firewall_rule(port)
      run "#{sudo} iptables -I INPUT 1 -p tcp -m state --state NEW -m tcp --dport #{port} -j ACCEPT"
      run "#{sudo} service iptables save"
    end
    
  end
    
end