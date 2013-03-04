require "bundler/capistrano"
#require 'thinking_sphinx/deploy/capistrano'

set :application, "sample_app"

set :repository,  "git@github.com:thebestname/types-of-cheeses.git"

set :deploy_to, "/home/deployer/grapefeed"

set :scm, :git
set :branch, "master"
set :deploy_via, :remote_cache
 
role :app, "ec2-23-22-105-162.compute-1.amazonaws.com"                              # This may be the same as your `Web` server
role :web, "ec2-23-22-105-162.compute-1.amazonaws.com"                              # This may be the same as your `Web` server
role :db,  "ec2-23-22-105-162.compute-1.amazonaws.com", :primary => true # This is where Rails migrations will run

set :user, "deployer" #this is your username for the server in role: app etc.

set :use_sudo, false
set :rails_env, "production"

before 'deploy:update_code', 'uploads:setup'
before 'deploy:update_code', 'god:unmonitor'
before 'deploy:update_code', 'sphinx:stop'
before 'deploy:update_code', 'unicorn:stop'
before 'deploy:update_code', 'resque:stop'

after 'deploy:finalize_update', 'sphinx:symlink_indexes'
after 'deploy:finalize_update', 'uploads:symlink'
after 'deploy:finalize_update', 'sphinx:rebuild'

before 'deploy:restart', 'god:start'

namespace :deploy do
  namespace :assets do
    task :precompile do
     end
  end
end

namespace :sphinx do
  desc "Rebild sphinx index"
  task :rebuild, :roles => :app, :except => { :no_release => true } do 
    run "sudo /usr/local/bin/ruby /usr/local/bin/rake -f /home/deployer/grapefeed/current/Rakefile ts:rebuild RAILS_ENV=production"
  end
  desc "Stop monitor sphinx so ts can reindex"
  task :stop, :roles => :app, :except => { :no_release => true } do 
    run "sudo /usr/local/bin/ruby /usr/local/bin/rake -f /home/deployer/grapefeed/current/Rakefile ts:stop RAILS_ENV=production"
  end
  desc "Symlink Sphinx indexes"
  task :symlink_indexes, :roles => [:app] do
    run "ln -nfs #{shared_path}/db/sphinx #{release_path}/db/sphinx"
  end
end


namespace :unicorn do
  task :stop, :roles => :app, :except => { :no_release => true } do 
    run "sudo god stop unicorn"
    run "sudo god remove unicorn"
  end
end

namespace :resque do
  task :stop, :roles => :app, :except => { :no_release => true } do 
    run "sudo god stop resque"
    run "sudo god remove resque"
  end
end

namespace :god do
  task :unmonitor, :roles => [:app] do
    run "sudo god unmonitor thinking-sphinx"
  end
  task :start, :roles => [:app] do
    run "sudo god load /etc/god/god.conf"
  end
end

namespace :uploads do
  desc "ensure upload folder exits"
  task :setup, :except => { :no_release => true } do
    run "mkdir -p #{shared_path}/uploads && chmod g+w #{shared_path}/uploads"
  end

  desc "symlink to shared/uploads to public/uploads"
  task :symlink, :except => { :no_release => true } do
    run "rm -rf #{release_path}/public/uploads"
    run "ln -nfs #{shared_path}/uploads #{release_path}/public/uploads"
  end
end

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"
