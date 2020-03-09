CREATE TABLE Users(
  account_id        SERIAL PRIMARY KEY,
  account_name      VARCHAR(20),
  email             VARCHAR(100),
  password          VARCHAR(64)
);

INSERT INTO Users (account_name, email, password) 
VALUES ('ytnobody', 'ytnobody@gmail.com', 'hogehoge');

CREATE TABLE UserStatus(
  status            VARCHAR(20) PRIMARY KEY
);