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

    desc 'Run all unit specs'
    task :unit do
      sh "bundle exec bacon #{specs('unit/**/*')}"
    end

    def specs(dir)
      FileList["spec/#{dir}_spec.rb"].shuffle.join(' ')
    end

    desc 'Run all specs'
    task :all => [
      :unit,
      :integration
    ]

  end

  desc 'Run all specs'
  task :spec => 'spec:all'
end
