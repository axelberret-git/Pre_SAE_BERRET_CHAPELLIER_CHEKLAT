require 'socket'

# Chemins des fichiers de logs à surveiller
LOG_FILES = {
  apache: '/var/log/apache2/access.log', 
  mariadb: '/var/log/mysql/error.log'  
}

# Chemin pour le fichier de suivi des offsets
OFFSET_FILE = '/usr/src/app/log_offsets.txt'

def monitor_logs
  puts "Démarrage de la surveillance des logs..."
  offsets = load_offsets
  LOG_FILES.each do |source, log_file|
    puts "Surveillance de #{log_file}..."
    File.open(log_file, 'r') do |file|
      file.seek(offsets[source].to_i, IO::SEEK_SET)
      loop do
        changes = file.read
        unless changes.empty?
          puts "Logs collectés :"
          changes.each_line do |line|
            puts "Envoi de log : #{line.strip}"
            send_log(source, line.strip)
          end
          offsets[source] = file.pos
          save_offsets(offsets)
        end
        sleep 5
      end
    end
  end
end


# Fonction pour envoyer un log à un serveur ou à un autre script
def send_log(source, message)
  socket = TCPSocket.new('log_storer', 12345)
  socket.puts("#{source}:#{message}")
  socket.close
end

# Chargement ou initialisation des offsets
def load_offsets
  if File.exists?(OFFSET_FILE)
    File.readlines(OFFSET_FILE).map { |line| line.split(':') }.to_h
  else
    Hash.new('0')
  end
end

# Enregistrement des offsets
def save_offsets(offsets)
  File.open(OFFSET_FILE, 'w') do |file|
    offsets.each { |source, offset| file.puts "#{source}:#{offset}" }
  end
end

# Lancer la surveillance des logs
monitor_logs
