require 'mysql2'
require 'time'

# Configuration de la connexion à la base de données
DB_HOST = 'db'
DB_NAME = 'wordpress'
DB_USER = 'wp_user'
DB_PASSWORD = 'wp_password'

# Chemins des fichiers de logs à surveiller
LOG_FILES = {
  apache: '/var/log/apache2/access.log', 
  mariadb: '/var/log/mysql/error.log'  
}

# Fichier de suivi des offsets (positions)
OFFSET_FILE = '/usr/src/app/log_offsets.txt'

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

# Chargement ou initialisation des offsets
def load_offsets
  if File.exists?(OFFSET_FILE)
    File.readlines(OFFSET_FILE).map { |line| line.split(':') }.to_h
  else
    Hash.new('0')  # Si le fichier n'existe pas, on commence à l'offset 0
  end
end

# Enregistrement des offsets
def save_offsets(offsets)
  File.open(OFFSET_FILE, 'w') do |file|
    offsets.each { |source, offset| file.puts "#{source}:#{offset}" }
  end
end

# Fonction pour insérer un log dans la base de données
def insert_log(client, timestamp, source, log_type, message)
  client.query("INSERT INTO logs (timestamp, source, log_type, message) VALUES ('#{timestamp}', '#{source}', '#{log_type}', '#{client.escape(message)}')")
end

# Fonction pour surveiller les fichiers de logs et insérer dans la BDD
def monitor_logs(client)
  offsets = load_offsets
  LOG_FILES.each do |source, log_file|
    File.open(log_file, 'r') do |file|
      file.seek(offsets[source].to_i, IO::SEEK_SET)  # Reprendre à l'offset enregistré
      loop do
        changes = file.read
        unless changes.empty?
          changes.each_line do |line|
            timestamp = Time.now.utc.iso8601
            log_type = line.include?('ERROR') ? 'ERROR' : 'INFO'
            insert_log(client, timestamp, source, log_type, line.strip)
          end
          offsets[source] = file.pos  # Mise à jour de l'offset après lecture
          save_offsets(offsets)
        end
        sleep 5  # Attente de 5 secondes avant de vérifier à nouveau
      end
    end
  end
end

# Lancer la surveillance des logs
monitor_logs(client)

