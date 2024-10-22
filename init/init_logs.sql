CREATE DATABASE IF NOT EXISTS logs_database;

USE logs_database;

CREATE TABLE IF NOT EXISTS logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME,
    source VARCHAR(50),
    log_type VARCHAR(50),
    message TEXT
);

