#!/usr/bin/env ruby

require 'methadone'
require 'yaml'
require 'colorize'

include Methadone::Main
include Methadone::CLILogging

main do |repository| 

  ############################################
  # Default System error message
  ############################################
  def system_error  
  	debug 'system command error'.colorize(:green)
  	error 'Aborted due a System command failure'.colorize(:red)
  	abort("Aborted due a System command failure")
  end

  # Parse repository name from repo url
  debug "Parsing url to obtain name ... #{repository}".colorize(:green)
  puts "Parsing url to obtain name ..."
  info "Parsing url to obtain name ...".colorize(:blue)
  repository_name = repository.split('Web/')[1].split('.git')[0]
  if repository_name.include? "-org"
   	db_name = repository_name.split('-org')[0]
  else
  	db_name = repository_name.split('-com')[0]
  end

  debug "repository name: #{repository_name}".colorize(:green)
  puts "repository name: #{repository_name}"
  info "repository name: #{repository_name}".colorize(:blue)

  ############################################
  # Unninstall
  ############################################
  if !options[:unninstall].nil?
  	 system("sudo rm /etc/apache2/sites-available/#{repository_name}.conf") or system_error
  	 system("sudo rm /etc/apache2/sites-enabled/#{repository_name}.conf") or system_error
  	 system("sudo rm -rf ~/#{repository_name}") or system_error  	 
  	 system("mysql -uroot -p -e \"drop database #{db_name};\"") or system_error
  	 abort("unninstall complete")
  end

  ############################################
  # Check Symlink
  ############################################
  begin
  	apache_conf = "/etc/apache2/sites-available/#{repository_name}.conf"
  	debug "Checking apache config file ... #{apache_conf}"
  	puts "Checking apache config file ..."
  	info "Checking apache config file ...".colorize(:blue)
  	config_file = File.readlink("#{apache_conf}")
  rescue
  	debug "symlink: #{config_file} does not exists!".colorize(:green)
  	puts "Symlink does not exists!"
  	info "Symlink does not exists!".colorize(:blue)
  	debug "run install".colorize(:green)
  	puts "Proceed to run install"
  	info "Proceed to run install".colorize(:blue)
  	config_file = nil
  end

  ############################################
  # Abort system
  ############################################  
  unless ( config_file.nil? )  	
  	error "config file: #{apache_conf}".colorize(:red)
  	warn "The config file exists abort app".colorize(:yellow)
  	abort("Config file problem")
  end

  ############################################
  # Run Install
  ############################################
  clone_opts = ''
  base_path = "~/"
  project_path = "#{base_path}/#{repository_name}"
  type = options[:type].nil? ? '' : options[:type]

  debug "project type: #{type}".colorize(:green)
  puts "Checking project type"
  info "Checking project type".colorize(:blue)
  if(type.downcase == 'wordpress' || type.downcase == 'wp-deploy')
  	debug "type: wordpress wp-deploy run clone with --recursive".colorize(:green)
  	info "Project type is Wordpress".colorize(:blue)
  	clone_opts = '--recursive'
  end

  # Clone GIT Repository
  debug "Running ... git clone #{clone_opts} #{repository}".colorize(:green)
  puts "Running ... git clone"
  info "Running ... git clone".colorize(:blue)  
  system("cd #{base_path} && git clone #{clone_opts} #{repository}") or system_error
  
  # Apache Config
  project_conf = "#{project_path}/#{repository_name}.conf"
  debug "Check if apache config exists ... #{project_path}/#{repository_name}.conf".colorize(:green)
  puts "Check if apache config exists"
  info "Check if apache config exists".colorize(:blue)  
  
  if File.exist?("#{project_path}/#{repository_name}.conf")
  	  debug "sudo ln -s #{project_conf} #{apache_conf}".colorize(:green)  	  
	  system("sudo ln -s #{project_conf} #{apache_conf}") or system_error
	  debug "sudo a2ensite #{repository_name}.conf".colorize(:green)
	  system("sudo a2ensite #{repository_name}.conf") or system_error
	  debug "sudo service apache2 reload".colorize(:green)
	  system("sudo service apache2 reload") or system_error
  end
  # Check Project Type lamp
  if(type.downcase == 'lamp')
  	 # Create local database
  	 debug "drop if db exists and create db".colorize(:green)
  	 puts "Create local database"
  	 info "Create local database".colorize(:blue)
     db_file = '#{project_path}/#{repository_name}.sql'     
     debug 'mysql -uroot -p -e "drop database #{db_name};"'.colorize(:green)
     system("mysql -uroot -p -e \"drop database #{db_name};\"")
     debug 'mysql -uroot -p -e "drop database #{db_name};"'.colorize(:green)
     system("mysql -uroot -p -e \"create database #{db_name};\"") or system_error
     # Import sql to local database
     debug "mysql -uroot -p #{db_name} < #{project_path}/#{db_name}.sql".colorize(:green)
     puts "Import data to local database"
     info "Import data to local database".colorize(:blue)
     system("mysql -uroot -p #{db_name} < #{project_path}/#{db_name}.sql") or system_error
  end
  # Check Project Type wordpress (wp-deploy)
  if(type.downcase == 'wordpress' || type.downcase == 'wp-deploy')  	
  	db_file = "#{project_path}/config/database.yml"    
  	debug "Create database.yml file #{db_file}".colorize(:green)
  	puts "Create database.yml file"
  	info "Create database.yml file".colorize(:blue)
  	system("cp #{project_path}/config/database.example.yml #{db_file}") or system_error
  	# Open database.yml file
  	db_config = YAML.load_file(db_file)	
	db_config['local']['database'] = "#{db_name}"
	db_config['local']['username'] = 'root'
	db_config['local']['password'] = ''
	# Promt user to type database credentials
	puts "Enter staging database connection details"
	puts "database_name:".colorize(:yellow)
	STDOUT.flush
	db_config['staging']['database'] = STDIN.gets.chomp
	puts "database_user:".colorize(:yellow)
	STDOUT.flush
	db_config['staging']['username'] = STDIN.gets.chomp
	puts "database_password:".colorize(:yellow)	
	db_config['staging']['password'] = STDIN.gets.chomp
	# Write database.yml file
	debug "Write database.yml file with user input #{db_file}".colorize(:green)	
  	info "Write database.yml file with user input".colorize(:blue)
	File.open(db_file,'w') do |h| 
	   h.write db_config.to_yaml
	end
	# Create local database
	puts "Creating local database"
	info "Creating local database".colorize(:blue)
    debug 'mysql -uroot -p -e "drop database #{db_name};"'.colorize(:green)
    system("mysql -uroot -p -e \"drop database #{db_name};\"")
    debug 'mysql -uroot -p -e "drop database #{db_name};"'.colorize(:green)
    system("mysql -uroot -p -e \"create database #{db_name};\"") or system_error

    # run wp-deploy commands
    puts "Running wp-deploy commands ..."
    info "Running wp-deploy commands ...".colorize(:blue)
    debug 'bundle exec cap staging wp:setup:local"'.colorize(:green)
	system("cd #{project_path} && bundle exec cap staging wp:setup:local") or system_error
	debug 'bundle exec cap staging db:pull"'.colorize(:green)
	system("cd #{project_path} && bundle exec cap staging db:pull") or system_error
	system("cp #{project_path}/config/templates/.htaccess.erb #{project_path}/.htaccess") or system_error
	debug 'bundle exec cap staging uploads:sync'.colorize(:green)
	system("cd #{project_path} && bundle exec cap staging uploads:sync") or system_error
  end
puts 'Intallation complete!'
puts 'bye.'

end

version     '0.0.1'
description 'Install and configure websites with repository url'
arg         :repository, :required

on("repository","repository url (ssh or https) git@github.com:Web/example.git")
on("-t TYPE","--type","repository type: wordpress | wp-deploy | lamp") do |type|
	options[:type] = type
end
on("-u","--unninstall","remove project") do 
	options[:unninstall] = true
end

go!