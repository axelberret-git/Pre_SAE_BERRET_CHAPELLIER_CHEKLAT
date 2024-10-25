<?php
// Variables de connexion
$servername = "db";
$username = "wp_user";
$password = "wp_password";
$dbname = "logs_database";

try {
    // Créer une connexion PDO
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Récupérer les paramètres de filtrage
    $source = $_GET['source'] ?? '';
    $log_type = $_GET['log_type'] ?? '';
    $timestamp = $_GET['timestamp'] ?? '';

    // Construire la requête SQL avec les filtres
    $sql = "SELECT * FROM logs WHERE 1=1";
    $params = [];

    if ($source) {
        $sql .= " AND source = :source";
        $params[':source'] = $source;
    }
    if ($log_type) {
        $sql .= " AND log_type = :log_type";
        $params[':log_type'] = $log_type;
    }
    if ($timestamp) {
        $sql .= " AND timestamp >= :timestamp";
        $params[':timestamp'] = $timestamp;
    }

    // Préparer la requête
    $stmt = $conn->prepare($sql);
    $stmt->execute($params);

    // Afficher les résultats
    if ($stmt->rowCount() > 0) {
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            echo "<tr>
                    <td>" . htmlspecialchars($row["id"]) . "</td>
                    <td>" . htmlspecialchars($row["timestamp"]) . "</td>
                    <td>" . htmlspecialchars($row["source"]) . "</td>
                    <td>" . htmlspecialchars($row["log_type"]) . "</td>
                    <td>" . htmlspecialchars($row["message"]) . "</td>
                  </tr>";
        }
    } else {
        echo "<tr><td colspan='5'>Aucun log trouvé</td></tr>";
    }
} catch (PDOException $e) {
    echo "<tr><td colspan='5'>Erreur de connexion : " . htmlspecialchars($e->getMessage()) . "</td></tr>";
}

// Fermer la connexion
$conn = null;
?>
