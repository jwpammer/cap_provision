task :process_task_exclusions do
  task_list(all: true).each { |task_definition|
    tn = task_definition.fully_qualified_name
    if task_exclusions.include?(tn)
      puts "Will exclude task: #{tn}"
      skip_proc = Proc.new { |o| puts "Excluding task: #{tn}" }
      task_definition.instance_variable_set(:@body, skip_proc)
    end
  }
end

task :create_app_tmp_dir do
  with_user(get_deploy_config_value('server_target/pro_user')) do
    run "#{sudo} rm -rf #{app_tmp_dir}"
    run "#{sudo} mkdir -p #{app_tmp_dir}"
    run "#{sudo} chmod 777 #{get_deploy_config_value('application/app_tmp_dir')}"
    run "#{sudo} chmod 777 #{app_tmp_dir}"
  end
end