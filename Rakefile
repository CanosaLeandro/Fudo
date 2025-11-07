require 'sequel'
require 'sequel/extensions/migration'
require 'yaml'
require 'dotenv/load'

namespace :db do
  # - creates db (Postgres) if isn't exists
  # - runs migrations
  # - creates a user admin default (user: ADMIN env or admin, password: ADMIN_PASSWORD or 'admin')
  desc "Create the database, run migrations and seed an admin user"
  task :create do
    db_config = YAML.load_file('config/database.yml')
    env = ENV['RACK_ENV'] || 'development'
    config = db_config[env]

    unless config
      puts "No database configuration for environment: #{env}"
      exit 1
    end

    # Crear la base de datos principal
    if config['adapter'] == 'postgres' || (config['url'] && config['url'].include?('postgres'))
      maint_config = config.dup
      maint_config['database'] = 'postgres'

      begin
        puts "Connecting to Postgres maintenance DB (#{maint_config['host']}) to ensure database exists..."
        maint_db = Sequel.connect(maint_config)
        dbname = config['database']

        exists = maint_db[:pg_database].where(datname: dbname).count > 0 rescue false
        if exists
          puts "Database '#{dbname}' already exists"
        else
          puts "Creating database '#{dbname}'..."
          begin
            maint_db.run("CREATE DATABASE \"#{dbname}\"")
            puts "Database '#{dbname}' created"
          rescue Sequel::DatabaseError => e
            if e.message =~ /duplicate key value/ || e.message =~ /already exists/
              puts "Database '#{dbname}' already exists (caught race condition)"
            else
              raise
            end
          end
        end

        # Crear la base de datos de test
        test_config = db_config['test']
        if test_config && test_config['database']
          test_dbname = test_config['database']
          test_exists = maint_db[:pg_database].where(datname: test_dbname).count > 0 rescue false
          if test_exists
            puts "Database '#{test_dbname}' already exists"
          else
            puts "Creating database '#{test_dbname}'..."
            begin
              maint_db.run("CREATE DATABASE \"#{test_dbname}\"")
              puts "Database '#{test_dbname}' created"
            rescue Sequel::DatabaseError => e
              if e.message =~ /duplicate key value/ || e.message =~ /already exists/
                puts "Database '#{test_dbname}' already exists (caught race condition)"
              else
                raise
              end
            end
          end
        end
      rescue Sequel::DatabaseError => e
        puts "Warning: could not create database via SQL (maybe insufficient privileges): #{e.message}"
        puts "You may need to create the database manually. Continuing to run migrations..."
      ensure
        maint_db.disconnect if maint_db
      end
    else
      puts "Automatic DB creation currently supports only Postgres. Skipping creation step."
    end

    # Run migrations para la base de datos principal
    Rake::Task['db:migrate'].invoke

    # Run migrations para la base de datos de test
    if db_config['test']
      ENV['RACK_ENV'] = 'test'
      Rake::Task['db:migrate'].reenable
      Rake::Task['db:migrate'].invoke
      ENV['RACK_ENV'] = env # restaurar env original
    end

    # Connect to the target DB and create admin user if not present
    db = Sequel.connect(config)
    Sequel::Model.db = db

    # Load the model
    require_relative 'api/models/user'

    admin_user = 'admin'
    admin_password = 'admin'

    if User.where(user: admin_user).first
      puts "User #{admin_user} already exists."
    else
      puts "Creating user (#{admin_user}) with default password..."
      User.create(user: admin_user, password: admin_password)
      puts "Admin user created. Change the password after first login."
    end
  end

  desc 'Run database migrations'
  task :migrate, [:version] do |_, args|
    env = ENV['RACK_ENV'] || 'development'
    config = YAML.load_file('config/database.yml')[env]
    db = Sequel.connect(config)
    
    # Get current version before migrations
    current = db[:schema_info].first[:version] rescue 0
    
    # Run migrations
    if args[:version]
      target = args[:version].to_i
      direction = target > current ? 'up' : 'down'
      puts "\nMigrating #{direction} to version #{target}"
      Sequel::Migrator.run(db, 'db/migrate', target: target)
    else
      puts "\nRunning pending migrations"
      Sequel::Migrator.run(db, 'db/migrate')
    end
    
    # Get new version and show applied migrations
    new_version = db[:schema_info].first[:version]
    if new_version != current
      puts "\nApplied migrations:"
      Dir["db/migrate/*.rb"].sort.each do |file|
        version = File.basename(file)[/^\d+/].to_i
        if (current..new_version).include?(version) || (new_version..current).include?(version)
          puts "  • #{File.basename(file)}"
        end
      end
      puts "\nMigrated from version #{current} to #{new_version}"
    else
      puts "No migrations were pending"
    end
  end

  desc 'Rollback migration'
  task :rollback do
    env = ENV['RACK_ENV'] || 'development'
    config = YAML.load_file('config/database.yml')[env]
    db = Sequel.connect(config)
    
    current_version = db[:schema_info].first[:version]
    target_version = current_version - 1
    
    if target_version >= 0
      puts "\nRolling back migration:"
      Dir["db/migrate/*.rb"].sort.each do |file|
        version = File.basename(file)[/^\d+/].to_i
        if version == current_version
          puts "  • #{File.basename(file)}"
        end
      end
      
      Sequel::Migrator.run(db, 'db/migrate', target: target_version)
      puts "\nRolled back from version #{current_version} to #{target_version}"
    else
      puts "Cannot rollback: already at version 0"
    end
  end

  desc "Drop the database (Postgres). Requires interactive confirmation or set ENV['CONFIRM']='yes' or ENV['FORCE']='true'"
  task :drop do
    env = ENV['RACK_ENV'] || 'development'
    config = YAML.load_file('config/database.yml')[env]

    unless config
      puts "No database configuration for environment: #{env}"
      exit 1
    end

    if config['adapter'] == 'postgres' || (config['url'] && config['url'].include?('postgres'))
      dbname = config['database']

      confirmed = false
      if ENV['FORCE'] == 'true' || ENV['CONFIRM'] == 'yes'
        confirmed = true
      else
        confirm_options = ['Yes', 'yes', 'y', '']
        puts "You are about to DROP database '#{dbname}' for environment '#{env}'."
        print "This operation is destructive. Confirm to proceed. [Yes/no] "
        answer = STDIN.gets
        answer = answer ? answer.strip : ''
        confirmed = confirm_options.include?(answer)
      end

      unless confirmed
        puts "Confirmation failed. Aborting without dropping database."
        exit 1
      end

      maint_config = config.dup
      maint_config['database'] = 'postgres'

      begin
        puts "Connecting to Postgres maintenance DB (#{maint_config['host']}) to drop database '#{dbname}'..."
        maint_db = Sequel.connect(maint_config)

        # Terminate connections to the target DB (Postgres >= 9.2 uses pid)
        begin
          maint_db.run("SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='#{dbname}' AND pid <> pg_backend_pid();")
        rescue Sequel::DatabaseError
          # Older Postgres versions use procpid
          maint_db.run("SELECT pg_terminate_backend(procpid) FROM pg_stat_activity WHERE datname='#{dbname}' AND procpid <> pg_backend_pid();") rescue nil
        end

        maint_db.run("DROP DATABASE IF EXISTS \"#{dbname}\"")
        puts "Database '#{dbname}' dropped."
      rescue Sequel::DatabaseError => e
        puts "Error dropping database: #{e.message}"
        exit 1
      ensure
        maint_db.disconnect if maint_db
      end
    else
      puts "Automatic DB drop currently supports only Postgres. Skipping drop."
    end
  end
end
