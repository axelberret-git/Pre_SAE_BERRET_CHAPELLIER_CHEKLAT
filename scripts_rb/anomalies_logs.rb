require 'mysql2'
require 'time'

client = Mysql2::Client.new(
  host: 'localhost',
  username: 'wp_user', 
  password: 'wp_password', 
  database: 'logs_database' 
)

CPU_THRESHOLD = 80    # Ne doit pas dépasser 80% du CPU
MEMORY_THRESHOLD = 80 # Ne doit pas dépasser 80% de mémoire
ERROR_500_LIMIT = 5   # Limite d'erreur 500 (dans notre cas 5)
TIME_WINDOW = 300     

results = client.query("SELECT * FROM logs ORDER BY timestamp ASC")

failed_attempts = Hash.new(0)
error_500_timestamps = []

File.open('logs_output.txt', 'w') do |file|
   results.each do |row|
    message = row['message']
    timestamp = Time.parse(row['timestamp'].to_s)
    source = row['source']

    if match = message.match(/HTTP\/\d\.\d" (\d{3})/)
      http_code = match[1].to_i

      if http_code >= 400
        file.puts "ID: #{row['id']}, Source: #{source}, HTTP Code: #{http_code}"
      end

      if http_code == 500
        error_500_timestamps << timestamp

        error_500_timestamps.reject! { |t| t < timestamp - TIME_WINDOW }

        if error_500_timestamps.size > ERROR_500_LIMIT
          file.puts "\nAlerte : Plus de #{ERROR_500_LIMIT} erreurs 500 détectées en moins de 5 minutes."
          file.puts "Timestamps des erreurs 500 : #{error_500_timestamps}"
        end
      end
    end

    # Détecter les tentatives de connexion échouées
    if message.include?("Failed login attempt") || message.include?("Authentication failed")
      if match = message.match(/\[client (\d+\.\d+\.\d+\.\d+)\]/)
        ip_address = match[1]
        failed_attempts[ip_address] += 1
      end
    end
  end

  # Exécuter la commande top pour surveiller l'utilisation des ressources
  output = `top -b -n 1`
  cpu_usage = nil
  memory_usage = nil

  output.each_line do |line|
    if line.start_with?('%Cpu(s):')
      cpu_match = line.match(/(\d+\.\d+) id/)
      if cpu_match
        idle_cpu = cpu_match[1].to_f
        cpu_usage = 100 - idle_cpu 
        if cpu_usage > CPU_THRESHOLD
          file.puts "Pic d'utilisation CPU détecté: #{cpu_usage.round(2)}%"
        end
      end
    end

    # Extraire l'utilisation de la mémoire
    if line.start_with?('MiB Mem :')
      memory_match = line.match(/(\d+\.\d+) total.*(\d+\.\d+) free.*(\d+\.\d+) used/)
      if memory_match
        total_memory = memory_match[1].to_f
        free_memory = memory_match[2].to_f
        used_memory = memory_match[3].to_f
        memory_usage_percentage = (used_memory / total_memory) * 100

        if memory_usage_percentage > MEMORY_THRESHOLD
          file.puts "Pic d'utilisation mémoire détecté: #{memory_usage_percentage.round(2)}%"
        end
      end
    end
  end

  # Afficher les adresses IP avec des tentatives de connexion échouées répétées
 failed_attempts.each do |ip, count|
    if count > 3 
      file.puts "Adresse IP: #{ip}, Nombre de tentatives échouées: #{count}"
    end
  end
end


client.close
