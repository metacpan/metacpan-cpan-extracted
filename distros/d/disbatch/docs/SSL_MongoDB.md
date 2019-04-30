### Configuring and Using SSL with MongoDB

Copyright (c) 2016 by Ashley Willis.

#### Configuring

This assumes you already have an SSL certificate.

* Add the following to `/etc/mongod.conf`, making sure the cert is owned by and
  only readable by the `mongod` process:

        sslMode=requireSSL
        sslPEMKeyFile=/etc/ssl/certs/mongodb-cert.pem	# set the correct path

* Restart `mongod`.

#### Connecting with the MongoDB shell

To connect using the `mongo` shell, you must include the `--ssl` option.

In addition, you must pass the Certificate Authority file for SSL with
`--sslCAFile` and use the fully qualified domain name:

    mongo --ssl --sslCAFile $PATH --host $FQDN $DATABASE

or:

    mongo --ssl --sslCAFile $PATH $FQDN/$DATABASE

To connect to `localhost` where the domain in your cert will not match, you can
instead pass `--sslAllowInvalidCertificates` and omit the host.

    mongo --ssl --sslAllowInvalidCertificates $DATABASE

#### Connecting with the MongoDB perl driver

In perl, you connect with the following:

    my $mongo = MongoDB->connect($fqdn, {ssl => {SSL_ca_file => $path}});

Or if connecting to `localhost`, with:

    my $mongo = MongoDB->connect("localhost", {ssl => {SSL_verify_mode => 0x00}});
