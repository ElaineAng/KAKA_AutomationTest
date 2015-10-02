require 'net/ssh'

ARGV[0] ||= 'develop'
branch = ARGV[0]
server = { host: '192.168.1.142', user: 'cuihbin', password: '12345678' }

Net::SSH.start(server[:host],
               server[:user],
               password: server[:password]) do |ssh|
  projects = %w(otms-exchange otms-core/core)
  git_commonds = %W(checkout\ .
                    reset\ --hard\ HEAD
                    fetch
                    checkout\ #{branch}
                    pull)

  puts 'stopping server...'
  2.times do
    server_port = ssh.exec!('ps -ef | grep jetty:run').split[1]
    ssh.exec!("kill -9 #{server_port}")
  end

  unless ARGV[-1] == '--stop'
    war = 'cd ~/testing/otms-core/war'
    unless ARGV[-1] == '--start'
      projects.each do |project|
        puts "updating #{project}..."
        project_dir = "cd ~/testing/#{project}"
        git_commonds.each { |c| ssh.exec!("#{project_dir}; git #{c}") }
        puts ssh.exec!("#{project_dir}; git status")
        ssh.exec!("#{project_dir}; mvn clean install -Dmaven.test.skip=true")
      end

      puts 'updating otms-core/war...'
      ssh.exec!("#{war}; mvn clean install -Pcompile-widgetset
        -Dmaven.test.skip=true -Denvironment=test")

      puts 'updating config'
      config_dir = 'src/main/resources/META-INF/spring'
      database_config_file = "#{config_dir}/database.properties"
      dev_database = { host: '192.168.1.159',
                       port: '5432',
                       database: 'otms',
                       username: 'postgres',
                       password: 'postgres' }
      test_database = { host: '192.168.1.33',
                        port: '5432',
                        database: 'otmstest',
                        username: 'jetty',
                        password: 'jetty' }
      databases = { dev: dev_database, test: test_database }
      ARGV[1] ||= '--db=test'
      db = databases[ARGV[1].split('=')[-1].to_sym]
      database_config =
        "\ndatabase.url=jdbc:postgresql://#{
        db[:host]}:#{db[:port]}/#{db[:database]}
        \ndatabase.username=#{db[:username]}
        \ndatabase.password=#{db[:password]}
        \ndatabase.driverClassName=org.postgresql.Driver\n"
      database_read_unit_config =
        database_config.gsub('database', 'database_read_unit')
      ssh.exec!("#{war};
        echo '#{database_config}#{
        database_read_unit_config}' > #{database_config_file}")
      app_config_file = "#{config_dir}/applicationContext.xml"
      env_config_file = "#{config_dir}/environment.properties"
      sed_find = "property name=\"initialSize\" value=\".*\""
      sed_replace = "property name=\"initialSize\" value=\"1\""
      ssh.exec!("#{war};
        sed -i 's/#{sed_find}/#{sed_replace}/' #{app_config_file};
        sed -i 's/rmi.Mail.Flag=.*/rmi.Mail.Flag=false/' #{env_config_file};
        sed -i 's/rmi.Xtt.Flag=.*/rmi.Xtt.Flag=false/' #{env_config_file}")
    end

    puts 'starting server...'
    ssh.exec!("#{war};export MAVEN_OPTS=\"-Xms512m -Xmx1024m
      -XX:PermSize=512m -Xdebug -Xnoagent -Djava.compiler=NONE
      -Xrunjdwp:transport=dt_socket,address=4000,server=y,suspend=n\"")
    ssh.exec("#{war}; mvn jetty:run -Dmaven.test.skip=true")
  end
  puts 'done.'
  ssh.close
end
