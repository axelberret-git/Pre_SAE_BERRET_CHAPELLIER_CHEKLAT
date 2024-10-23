require 'mysql2'
require 'time'
require 'socket'

# Configuration de la connexion à la base de données
DB_HOST = 'db'  # Nom du service MariaDB
DB_NAME = 'wordpress'
DB_USER = 'wp_user'
DB_PASSWORD = 'wp_password'

# Connexion à la base de données
client = Mysql2::Client.new(
  host: DB_HOST,
  username: DB_USER,
  password: DB_PASSWORD,
  database: DB_NAME
)

# Création de la table logs si elle n'existe pas
client.query(<<-SQL
  CREATE TABLE IF NOT EXISTS logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME,
    source VARCHAR(50),
    log_type VARCHAR(50),
    message TEXT
  );
SQL
)

# Fonction pour insérer un log dans la base de données
def insert_log(client, timestamp, source, log_type, message)
  client.query("INSERT INTO logs (timestamp, source, log_type, message) VALUES ('#{timestamp}', '#{source}', '#{log_type}', '#{client.escape(message)}')")
end

# Fonction pour écouter et traiter les logs entrants
def listen_for_logs(client)
  server = TCPServer.new(12345)  # Écoute sur le même port que le script de collecte
  loop do
    socket = server.accept
    data = socket.gets.chomp
    source, message = data.split(':', 2)  # Séparer la source du message

    timestamp = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')
    log_type = message.include?('ERROR') ? 'ERROR' : 'INFO'
    
    insert_log(client, timestamp, source, log_type, message)

    socket.close
  end
end

# Lancer l'écoute des logs
listen_for_logs(client)

