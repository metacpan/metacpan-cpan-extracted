# Load this into a mysql database instance

CREATE TABLE user (
   id               INT NOT NULL AUTO_INCREMENT,
   username         VARCHAR(255),
   email            VARCHAR(255),
   password         VARCHAR(255),
   PRIMARY KEY (id)
);

INSERT INTO user ( username, password )
   VALUES        ( 'admin',  '$1$7c786c22$OVNZx7oK4UKBXXdD.aYad1'  ),
                 ( 'demo',   '$1$7c786c22$tdAL1QSJqM8Ugkka/YQlg/'  );
