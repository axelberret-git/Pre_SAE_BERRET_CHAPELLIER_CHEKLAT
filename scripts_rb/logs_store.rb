require 'mysql2'
require 'time'
require 'socket'

DB_HOST = 'db'
DB_NAME = 'logs_database'
DB_USER = 'wp_user'
DB_PASSWORD = 'wp_password'

client = Mysql2::Client.new(
  host: DB_HOST,
  username: DB_USER,
  password: DB_PASSWORD,
  database: DB_NAME
)

def insert_log(client, timestamp, source, log_type, message)
  client.query("INSERT INTO logs (timestamp, source, log_type, message) VALUES ('#{timestamp}', '#{source}', '#{log_type}', '#{client.escape(message)}')")
end

def process_apache_log(client, message)
  # Extraction et conversion du timestamp
  # Supposons que le format du log est standard
  if message =~ /(\d+\.\d+\.\d+\.\d+) - - \[(.*?)\] "(.*?)" (.*?) (.*)/
    ip = $1
    timestamp_str = $2
    request = $3
    status_code = $4
    response_size = $5

    timestamp = Time.strptime(timestamp_str, '%d/%b/%Y:%H:%M:%S %z').strftime('%Y-%m-%d %H:%M:%S')
    log_type = status_code.to_i >= 400 ? 'ERROR' : 'INFO' # Exemple de logique pour déterminer le type
    insert_log(client, timestamp, 'apache', log_type, message)
  else
    puts "Format de log Apache non reconnu : #{message}"
  end
end

def process_mysql_log(client, message)
  timestamp = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')
  log_type = message.include?('Warning') ? 'WARNING' : 'INFO'
  insert_log(client, timestamp, 'mariadb', log_type, message)
end

def listen_for_logs(client)
  server = TCPServer.new('0.0.0.0', 12345)
  loop do
    socket = server.accept
    data = socket.gets
    
    if data
      data = data.chomp
      source, message = data.split(':', 2) 

      case source
      when 'apache'
        process_apache_log(client, message)
      when 'mariadb'
        process_mysql_log(client, message)
      end
    else
      puts "Aucune donnée reçue, attente..."
    end

    socket.close
  end
end

listen_for_logs(client)
