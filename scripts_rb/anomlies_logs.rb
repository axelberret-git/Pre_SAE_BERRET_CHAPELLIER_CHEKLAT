require 'mysql2'

# Configurer la connexion à la base de données
client = Mysql2::Client.new(
  host: 'localhost',
  username: 'root', # Remplace par ton nom d'utilisateur
  password: 'root', # Remplace par ton mot de passe
  database: 'logs_database' # Remplace par le nom de ta base de données
)

# Récupérer les logs de la base de données
results = client.query("SELECT * FROM logs ORDER BY timestamp ASC")

# Hash pour stocker les tentatives de connexion échouées
failed_attempts = Hash.new(0)

# Analyser et afficher les logs
results.each do |row|
  message = row['message']

  # Détecter les codes d'erreur HTTP
  if match = message.match(/HTTP\/\d\.\d" (\d{3})/)
    http_code = match[1].to_i

    # Afficher uniquement les logs avec un code d'erreur HTTP (400 et supérieurs)
    if http_code >= 400
      puts "ID: #{row['id']}, HTTP Code: #{http_code}"
    end
  end

  # Détecter les tentatives de connexion échouées
  if message.include?("Failed login attempt") || message.include?("Authentication failed")
    # Extraire l'adresse IP si disponible
    if match = message.match(/\[client (\d+\.\d+\.\d+\.\d+)\]/)
      ip_address = match[1]
      failed_attempts[ip_address] += 1
    end
  end
end

# Afficher les adresses IP avec des tentatives de connexion échouées répétées
puts "\nTentatives de connexion échouées répétées :"
failed_attempts.each do |ip, count|
  if count > 3 # seuil pour considérer comme suspect
    puts "Adresse IP: #{ip}, Nombre de tentatives échouées: #{count}"
  end
end

# Fermer la connexion
client.close
