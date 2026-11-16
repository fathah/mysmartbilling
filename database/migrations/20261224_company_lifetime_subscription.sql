ALTER TABLE companies
  MODIFY subscription_mode ENUM('monthly','yearly','demo','lifetime') NOT NULL DEFAULT 'monthly';
