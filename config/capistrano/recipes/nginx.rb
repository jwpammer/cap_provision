namespace :nginx do
  
  desc "Install Nginx"
  task :install do
    run "#{sudo} add-apt-repository -y ppa:nginx/stable"
    run "#{sudo} apt-get -q -y update"
    run "#{sudo} apt-get -q -y install nginx"
    run "#{sudo} service nginx start"
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

    if nginx_ssl_enabled.upcase.eql?('Y')
      upload_support_file('nginx', nginx_ssl_dir, nginx_ssl_crt_file, true)
      ch_ops "#{nginx_ssl_dir}/#{nginx_ssl_crt_file}"
                  
      upload_support_file('nginx', nginx_ssl_dir, nginx_ssl_key_file, true)
      ch_ops "#{nginx_ssl_dir}/#{nginx_ssl_key_file}"
    end

    upload_sudoers('nginx', 'nginx-ops', 'nginx-ops')

    run "#{sudo} service nginx restart"
  end
    
end