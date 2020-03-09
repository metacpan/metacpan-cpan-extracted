# NAME

Test::PostgreSQL::Docker - A Postgresql mock server for testing perl programs

# SYNOPSIS

    use Test::More;
    use Test::PostgreSQL::Docker;
    
    # 1. create a instance of Test::PostgreSQL::Docker with postgres:12-alpine image
    my $server = Test::PostgreSQL::Docker->new(tag => '12-alpine');
    
    # 2. create/run a container
    $server->run();
    
    # 3. puke initialization data into postgresql on a container
    $server->run_psql_scripts("/path/to/fixture.sql");
    
    # 4. get a Database Handler(a DBI::db object) from mock server object
    my $dbh = $server->dbh();
    
    # (or call steps of 2 to 4 as method-chain)
    my $dbh = $server->run->run_psql_scripts("/path/to/fixture.sql")->dbh;
    
    # 5. query to database
    my $sth = $dbh->prepare("SELECT * FROM Users WHERE id=?");
    $sth->execute(1);
    
    # 6. put your own test code below
    my $row $sth->fetchrow_hashref();
    is $row->{name}, "ytnobody";
    
    done_testing;

# DESCRIPTION

Test::PostgreSQL::Docker run the postgres container on the Docker, for testing your perl programs.

**\*\*NOTE\*\*** Maybe this module doesn't work on the Windows, because this module uses some backticks for use the Docker.

# METHODS

## new

    $server = Test::PostgreSQL::Docker->new(%opt)

- pgname (str)

    A distribution name. Default is `postgres`.

- tag (str)

    A tag of the PostgreSQL. Default is `latest`. 

- oid (str)

    An uniqe id. Default is the object memory addres.

- dbowner (str)

    Default is `postgres`.

- password (str)

    Default is `postgres`.

- dbname (str)

    Default is `test`.

## run

    $server = $server->run(%opt)

1\. Check image with `docker pull`.

2\. `docker run`

3\. `connect database`

- skip\_pull (bool)

    Skip image check. Default is `true`.

- skip\_connect (bool)

    Skip connect database. Default is `false`.

## oid

    $oid = $server->oid()

Return an unique id.

## container\_name

    $container_name = $server->container_name()

Return the docker container name `sprintf('%s-%s-%s', $pgname, $tag, $oid)`.

## image\_name

    $image_name = $server->image_name()

Return the docker image name.

## dsn

    $dsn = $server->dsn(%opt)

## port

    $port = $server->port()

Return a PostgreSQL server port.

## dbh

    $dbh = $server->dbh()

## psql\_args

    $psql_args = $server->psql_args()
    $psql_args = $server->psql_args($args)

Arguments to `psql` in `run_psql` and `run_psql_scripts`.
Default is `sprintf('-h %s -p %s -U %s -d %s', $self-`{host}, 5432, $self->{dbowner}, $self->{dbname})>.

## run\_psql

    $server = $server->run_psql(@args)

    $server->run_psql('-c', q|"INSERT INTO foo (bar) VALUES ('baz')"|);

## run\_psql\_scripts

    $server = $server->run_psql_scripts($path)

# REQUIREMENT

- Docker

    This module uses the Docker as ephemeral environment.

# LICENSE

Copyright (C) Satoshi Azuma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Satoshi Azuma <ytnobody@gmail.com>

# SEE ALSO

[https://hub.docker.com/\_/postgres](https://hub.docker.com/_/postgres)
