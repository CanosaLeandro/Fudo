require 'sequel'
require 'sequel/extensions/migration'
require 'yaml'
require 'dotenv/load'

namespace :db do
  desc 'Run database migrations'
  task :migrate, [:version] do |_, args|
    env = ENV['RACK_ENV'] || 'development'
    config = YAML.load_file('config/database.yml')[env]
    db = Sequel.connect(config)
    
    if args[:version]
      Sequel::Migrator.run(db, 'db/migrate', target: args[:version].to_i)
    else
      Sequel::Migrator.run(db, 'db/migrate')
    end
  end

  desc 'Rollback migration'
  task :rollback do
    env = ENV['RACK_ENV'] || 'development'
    config = YAML.load_file('config/database.yml')[env]
    db = Sequel.connect(config)
    
    current_version = db[:schema_info].first[:version]
    Sequel::Migrator.run(db, 'db/migrate', target: current_version - 1)
  end

  # Tarea top-level `rake create`:
  # - crea la base de datos (Postgres) si no existe
  # - corre las migraciones
  # - crea un usuario admin por defecto (email: ADMIN_EMAIL env or admin@example.com, password: ADMIN_PASSWORD or 'admin')
  desc "Create the database, run migrations and seed an admin user"
  task :create do
    env = ENV['RACK_ENV'] || 'development'
    config = YAML.load_file('config/database.yml')[env]

    unless config
      puts "No database configuration for environment: #{env}"
      exit 1
    end

    # Only implement create for Postgres here.
    if config['adapter'] == 'postgres' || (config['url'] && config['url'].include?('postgres'))
      maint_config = config.dup
      # Connect to the default maintenance DB to create the target database
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
              maint_db.run("CREATE DATABASE \"#{dbname}\"")
          puts "Database '#{dbname}' created"
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

    # Run migrations
    Rake::Task['db:migrate'].invoke

    # Connect to the target DB and create admin user if not present
    db = Sequel.connect(config)
    Sequel::Model.db = db

    # Load the model (path used in this project)
    require_relative 'lib/models/user'

    admin_email = ENV['ADMIN_EMAIL'] || 'admin@example.com'
    admin_password = ENV['ADMIN_PASSWORD'] || 'admin'

    if User.where(email: admin_email).first
      puts "Admin user with email #{admin_email} already exists."
    else
      puts "Creating admin user (#{admin_email}) with default password..."
      User.create(email: admin_email, password: admin_password)
      puts "Admin user created. Change the password after first login."
    end
  end
end
