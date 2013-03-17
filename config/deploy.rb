require "bundler/capistrano"
#require 'thinking_sphinx/deploy/capistrano'

set :application, "sample_app"

set :repository,  "git@github.com:thebestname/sample_app.git"

set :deploy_to, "/home/deployer/sample_app"

set :scm, :git
set :branch, "master"
set :deploy_via, :remote_cache
 
role :app, "ec2-23-22-32-180.compute-1.amazonaws.com"                              # This may be the same as your `Web` server
role :web, "ec2-23-22-32-180.compute-1.amazonaws.com"                              # This may be the same as your `Web` server
role :db,  "ec2-23-22-32-180.compute-1.amazonaws.com", :primary => true # This is where Rails migrations will run

set :user, "deployer" #this is your username for the server in role: app etc.

set :use_sudo, false
set :rails_env, "production"

# before 'deploy:update_code', 'unicorn:stop'
# before 'deploy:update_code', 'resque:stop'

before 'deploy:restart', 'god:start'

namespace :deploy do
  namespace :assets do
    task :symlink do
    end
    task :precompile do
    end
    task :clean do
    end
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
  task :start, :roles => [:app] do
    run "sudo god load /etc/god/god.conf"
  end
end

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"
