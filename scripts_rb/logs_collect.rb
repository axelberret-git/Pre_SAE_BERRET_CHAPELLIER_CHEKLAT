require 'socket'

LOG_FILES = {
  apache: '/var/log/apache2/access.log', 
  mariadb: '/var/log/mysql/error.log'
}

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

def send_log(source, message)
  retries = 5
  begin
    socket = TCPSocket.new('log_storer', 12345)
    socket.puts("#{source}:#{message}")
    socket.close
  rescue Errno::ECONNREFUSED
    retries -= 1
    if retries > 0
      sleep 1  # Attendre avant de réessayer
      retry
    else
      puts "Impossible de se connecter à log_storer après plusieurs tentatives."
    end
  rescue Errno::EPIPE
    puts "Le pipe a été cassé. Vérifiez que log_storer est en cours d'exécution."
  end
end

def load_offsets
  if File.exists?(OFFSET_FILE)
    File.readlines(OFFSET_FILE).map { |line| line.split(':') }.to_h
  else
    Hash.new('0')
  end
end

def save_offsets(offsets)
  File.open(OFFSET_FILE, 'w') do |file|
    offsets.each { |source, offset| file.puts "#{source}:#{offset}" }
  end
end

monitor_logs
