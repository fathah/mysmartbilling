ALTER TABLE mobile_wallet_withdrawals
  ADD COLUMN movement_type ENUM('Deposit','Withdraw') NOT NULL DEFAULT 'Withdraw' AFTER amount,
  ADD COLUMN wallet_account ENUM('Cash','Bank') NOT NULL DEFAULT 'Cash' AFTER movement_type;
