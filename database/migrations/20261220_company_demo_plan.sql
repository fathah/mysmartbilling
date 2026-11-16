ALTER TABLE companies
  MODIFY subscription_mode ENUM('monthly','yearly','demo') NOT NULL DEFAULT 'monthly';