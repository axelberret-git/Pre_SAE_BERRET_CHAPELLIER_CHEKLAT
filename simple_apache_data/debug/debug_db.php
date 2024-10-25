<?php
// Paramètres de connexion
$servername = "db";
$username = "wp_user";
$password = "wp_password";
$dbname = "logs_database";

// Essayer de se connecter
try {
    // Créer une connexion
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    // Configurer PDO pour qu'il lance une exception en cas d'erreur
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "Connexion réussie à la base de données.<br>";

    // Afficher des informations sur la connexion
    echo "<h2>Détails de la connexion :</h2>";
    echo "Serveur: " . htmlspecialchars($servername) . "<br>";
    echo "Nom d'utilisateur: " . htmlspecialchars($username) . "<br>";
    echo "Nom de la base de données: " . htmlspecialchars($dbname) . "<br>";

    // Optionnel : Tester une requête simple
    $stmt = $conn->query("SELECT DATABASE() AS current_database");
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "Base de données actuelle: " . htmlspecialchars($result['current_database']) . "<br>";

} catch (PDOException $e) {
    echo "Erreur de connexion : " . htmlspecialchars($e->getMessage()) . "<br>";
    echo "<h2>Informations détaillées :</h2>";
    echo "<pre>";
    echo "Code d'erreur: " . htmlspecialchars($e->getCode()) . "\n";
    echo "Fichier: " . htmlspecialchars($e->getFile()) . "\n";
    echo "Ligne: " . htmlspecialchars($e->getLine()) . "\n";
    echo "Trace: " . htmlspecialchars($e->getTraceAsString());
    echo "</pre>";
}

// Fermer la connexion
$conn = null;
?>
