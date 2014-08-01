begin
  require 'bundler/gem_tasks'

  namespace :spec do

    task :prepare do
      verbose false
      puts 'Prepare …'
      sh 'mkdir -p tmp'
      rm_rf 'tmp/*'
    end

    desc 'Run all integration specs'
    task :integration => [:prepare] do
      sh 'bundle exec bacon spec/integration.rb'
    end

    desc 'Run all specs'
    task :all => [
      :integration
    ]

  end

  desc 'Run all specs'
  task :spec => 'spec:all'
end
