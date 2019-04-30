### Configuring and Using Authentication with MongoDB

Copyright (c) 2016 by Ashley Willis.

#### Configuring

* Create a key file for multiple `mongod` processes to auth against each other,
  making sure it is owned by and only readable by the `mongod` process:

        touch mongodb-keyfile
        chmod 600 mongodb-keyfile
        openssl rand -base64 741 > mongodb-keyfile
        # copy to desired location and change owner

* Add the following to `/etc/mongod.conf`:

        auth=true
        keyFile=/etc/mongodb-keyfile

* Restart `mongod`

* Create needed users

#### Connecting with the MongoDB shell

After connecting with the `mongo` shell, you can authenticate against the
authentication database via:

    use admin
    db.auth(user, password)

You can also also pass `mongo` the following options and the shell will prompt
for the password. `--authenticationDatabase` is only needed if the
authentication database is different from the database you want to use.

    mongo -u $USER -p --authenticationDatabase $AUTH_DB $HOST/$DATABASE

#### Connecting with the MongoDB perl driver

* In perl, connect with the following (`db_name` is the optional authentication
  database and defaults to `admin`):

        my $mongo = MongoDB->connect($host, {username => $username, password => $password, db_name => $auth_database});
