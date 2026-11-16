ALTER TABLE subscription_requests
  MODIFY COLUMN status ENUM('pending_review','awaiting_payment','paid','rejected','cancelled') NOT NULL DEFAULT 'pending_review';