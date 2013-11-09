# General utility
def assign_common_config_vars
  set :application, get_deploy_config_value('application/name')
  set :repository, get_deploy_config_value('application/repository')
  set :ops_home_dir, get_deploy_config_value('application/ops_home_dir')
  set :app_root_dir, get_deploy_config_value('application/app_root_dir')
  set :app_tmp_dir, File.join(get_deploy_config_value('application/app_tmp_dir'), application)
  set :command_log, get_deploy_config_value('debug/command_log')
  set :deploy_to, "#{app_root_dir}/#{application}"
  set :service_path, get_deploy_config_value("server_target/service_path")
end

def get_deploy_config_value(property_path, default_value = nil) 
  dc = fetch(:deploy_config, nil)
  
  if dc.nil? || !dc.is_a?(Hash)
    if default_value.nil?
      fail "Deploy configuration not found. Cannot continue."
    else
      puts "Deploy configuration not found. Returning default value: #{default_value}"
      return default_value
    end
  end
  
  property_parts = property_path.split('/')

  to_eval = "deploy_config[os_type]"
  
  property_parts.each do |property_part|
    to_eval << "['#{property_part}']"
  end
  
  value = nil
  begin; value = eval(to_eval); rescue; end;
  
  if value.nil?
    if default_value.nil?
      fail "No value found for property path: #{property_path}. Cannot continue. #{to_eval}"
    else
      puts "No value found for property path: #{property_path}. Returning default value: #{default_value}"
      return default_value
    end
  end
  
  # puts "Found value: #{value} for property_path: #{property_path}"
  
  return value
end

def append_to_command_log(cmd)
  system("mkdir -p log")
  open('log/commands.out', 'a') { |f|
    f.puts cmd
  }
end

def run(cmd, options={}, &block)
  append_to_command_log cmd if command_log
  
  if options[:eof].nil? && !cmd.include?(sudo)
    options = options.merge(:eof => !block_given?)
  end
  block ||= self.class.default_io_proc
  tree = Command::Tree.new(self) { |t| t.else(cmd, &block) }
  run_tree(tree, options)
end

def create_tmp_dir_structure(component)
  tmp_dirs = {}
  tmp_dirs[:base] = "#{app_tmp_dir}/#{component}"
  tmp_dirs[:support] = "#{tmp_dirs[:base]}/support"
  tmp_dirs[:templates] = "#{tmp_dirs[:base]}/templates"

  run "mkdir -p #{tmp_dirs[:base]}"
  run "mkdir -p #{tmp_dirs[:support]}"
  run "mkdir -p #{tmp_dirs[:templates]}"

  return tmp_dirs
end

def update_crontab(cmd, search_string) 
  cron_tmp_dir = "#{app_tmp_dir}/cron"
  
  run "mkdir -p #{cron_tmp_dir}"
  
  begin; run "crontab -l &> #{cron_tmp_dir}/crontab"; rescue; end;
  run %Q{sed -i "/no crontab for/d" #{cron_tmp_dir}/crontab}
  run %Q{sed -i "/#{search_string}/d" #{cron_tmp_dir}/crontab}
  run "echo '#{cmd}' >> #{cron_tmp_dir}/crontab"
  run "crontab #{cron_tmp_dir}/crontab"  
  puts "Created Crontab Entry: #{cmd}"
end

def upload_sudoers(component, template, to_file)
  upload_template_file(component, 'etc/sudoers.d', template, to_file, true)
  run "#{sudo} chmod 440 /etc/sudoers.d/#{to_file}"
end

def close_sessions
  sessions.values.each { |session| session.close }
  sessions.clear
end

# Prompt helpers
def press_enter(ch, stream, data)
  if data =~ /Press.\[ENTER\].to.continue/
    ch.send_data("\n")
  else
    Capistrano::Configuration.default_io_proc.call(ch, stream, data)
  end
end

def set_default(name, *args, &block)
  set(name, *args, &block) unless exists?(name)
end

def prompt_with_default(prompt, default = nil)
  if default.nil?
    response = Capistrano::CLI.ui.ask("#{prompt}:")
  else
    response = Capistrano::CLI.ui.ask("#{prompt} [default=#{default}]:")
    response = default if response.to_s.empty?
  end
  fail("A value must be specified for the prompt: '#{prompt}'") if response.to_s.empty?
  response
end

def set_with_prompt_default(property, prompt = nil, default = nil)
  value = fetch(property.to_sym, nil)
  return value unless value.nil? || value.to_s.empty?
  value = ENV[property.to_s.upcase] if value.nil? || value.to_s.empty?
  prompt = property.to_s if prompt.nil?
  value = prompt_with_default(prompt, default) if value.nil? || value.to_s.empty?
  set property.to_sym, value
  puts "#{property}=#{value}"
  return value
end

def prompt_and_set_os_type
  os_type = set_with_prompt_default('os_type', 'OS type (ubuntu/rhel)', 'ubuntu')
  set :os_type, os_type
end

def prompt_and_set_server_targets(roles = [:server], options = { primary: true, no_release: true })
  server_targets = set_with_prompt_default(:server_target, 'Server target - IP address or hostname (comma separated list for multiple)')
  roles << options
  server_targets.split(',').each do |server_target|
    server server_target, *roles
  end
end

def prompt_and_set_server_port
  ssh_port = set_with_prompt_default('ssh_port', 'SSH port to connect to remote target', 22)
  set :port, ssh_port
end

def prompt_and_set_ssh_key_files
  ssh_options[:keys] = []
  ssh_key_files = set_with_prompt_default(:ssh_key_file, 'SSH key file name, relative to config/capistrano/ssh_keys, comma separated for multiple', get_deploy_config_value('server_target/ssh_key_files'))
  ssh_key_files.split(',').each do |ssh_key_file|
    ssh_options[:keys] << File.join(File.expand_path(ssh_keys_dir, __FILE__), ssh_key_file)
  end
end

def prompt_for_common_context(roles = [:server], options = { primary: true, no_release: true })
  prompt_and_set_os_type
  prompt_and_set_server_targets(roles, options)
  prompt_and_set_server_port  
  prompt_and_set_ssh_key_files
end

# Upload helpers
def put_template(from, to)
  erb = File.read(File.expand_path(from))
  put ERB.new(erb).result(binding), to
end  

def upload_support_file(component, path, file, use_sudo = false, os_dependent = false)
  path = path.gsub(/^\//, '')
  tmp_dirs = create_tmp_dir_structure(component)  
  run "mkdir -p #{tmp_dirs[:support]}/#{path}"
  
  if os_dependent    
    upload "#{support_files_dir}/#{component}/#{os_type}/#{path}/#{file}", "#{tmp_dirs[:support]}/#{path}", { via: :scp } 
  else
    upload "#{support_files_dir}/#{component}/#{path}/#{file}", "#{tmp_dirs[:support]}/#{path}", { via: :scp } 
  end
  
  mkdir_cmd = "mkdir -p /#{path}"
  cp_cmd = "cp -rf #{tmp_dirs[:support]}/#{path}/#{file} /#{path}/#{file}"  
  
  if use_sudo
    run "#{sudo} #{mkdir_cmd}"
    run "#{sudo} #{cp_cmd}"
  else
    run "#{mkdir_cmd}"
    run "#{cp_cmd}"
  end
end

def upload_support_dir(component, path, dir, use_sudo = false, os_dependent = false)
  path = path.gsub(/^\//, '')
  tmp_dirs = create_tmp_dir_structure(component)
  run "mkdir -p #{tmp_dirs[:support]}/#{path}"
  
  if os_dependent
    upload "#{support_files_dir}/#{component}/#{os_type}/#{path}/#{dir}", "#{tmp_dirs[:support]}/#{path}", { via: :scp, recursive: true } 
  else
    upload "#{support_files_dir}/#{component}/#{path}/#{dir}", "#{tmp_dirs[:support]}/#{path}", { via: :scp, recursive: true } 
  end
  
  mkdir_cmd = "mkdir -p /#{path}"
  cp_cmd = "cp -rf #{tmp_dirs[:support]}/#{path}/#{dir} /#{path}"
  
  if use_sudo
    run "#{sudo} #{mkdir_cmd}"
    run "#{sudo} #{cp_cmd}"
  else
    run "#{mkdir_cmd}"
    run "#{cp_cmd}"  
  end
end

def upload_template_file(component, path, template, to_file, use_sudo = false, os_dependent = false)
  path = path.gsub(/^\//, '')
  tmp_dirs = create_tmp_dir_structure(component)
  run "mkdir -p #{tmp_dirs[:templates]}/#{path}"
  
  if os_dependent
    put_template("#{template_files_dir}/#{component}/#{os_type}/#{path}/#{template}.erb", "#{tmp_dirs[:templates]}/#{path}/#{to_file}")
  else
    put_template("#{template_files_dir}/#{component}/#{path}/#{template}.erb", "#{tmp_dirs[:templates]}/#{path}/#{to_file}")
  end

  mkdir_cmd = "mkdir -p /#{path}"
  cp_cmd = "cp -f #{tmp_dirs[:templates]}/#{path}/#{to_file} /#{path}/#{to_file}"
  
  if use_sudo
    run "#{sudo} #{mkdir_cmd}"
    run "#{sudo} #{cp_cmd}"
  else
    run "#{mkdir_cmd}"
    run "#{cp_cmd}"  
  end  
end  

def upload_ssh_key
  set :command_log, get_deploy_config_value('debug/command_log')
    
  to_user = prompt_with_default('User to upload SSH public key to', 'root')
  to_home_dir = prompt_with_default('User home directory', '/root')
  
  set :user, to_user
  
  upload "#{ssh_keys_dir}/server_target_rsa.pub", "#{to_home_dir}/.ssh/authorized_keys", { via: :scp } 
  run "#{sudo} chown -R #{to_user}:#{to_user} #{to_home_dir}/.ssh"
  run "chmod 700 #{to_home_dir}/.ssh"
  run "chmod 600 #{to_home_dir}/.ssh/authorized_keys"
end

# User helpers
def ch_ops(file_path, chmod = '700') 
  run "#{sudo} chown -R ops #{file_path}"
  run "#{sudo} chgrp -R ops #{file_path}"
  run "#{sudo} chmod #{chmod} #{file_path}"
end

def with_user(new_user, &block)
  old_user = user
  set :user, new_user

  close_sessions
  yield
  set :user, old_user
  close_sessions
end