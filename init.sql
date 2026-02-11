CREATE DATABASE IF NOT EXISTS schule;
USE schule;

CREATE TABLE personen (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  ort VARCHAR(100)
);

INSERT INTO personen (name, ort) VALUES
('Anna', 'Berlin'),
('Ben', 'Hamburg'),
('Clara', 'München');
