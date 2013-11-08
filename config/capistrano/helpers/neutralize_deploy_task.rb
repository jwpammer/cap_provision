# Neutralize default deployment tasks when not needed, i.e server setup scripts.
namespace :deploy do
  [:setup, :update, :update_code, :finalize_update, :symlink, :restart].each do |default_task|
    task default_task do 
      # Neutralize default tasks
    end
  end
end