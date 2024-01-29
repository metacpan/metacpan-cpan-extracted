package WWW::Suffit::AuthDB::Model;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::AuthDB::Model - WWW::Suffit::AuthDB model (store) class

=head1 SYNOPSIS

    use WWW::Suffit::AuthDB::Model;

    my $model = WWW::Suffit::AuthDB::Model->new(
        "sqlite:///tmp/test.db?RaiseError=0&PrintError=0&sqlite_unicode=1"
    );

    my $model = WWW::Suffit::AuthDB::Model->new(
        "mysql://user:pass@mysql.example.com/authdb?mysql_auto_reconnect=1&mysql_enable_utf8=1"
    );

    die($model->error) unless $model->status;

=head1 DESCRIPTION

This module provides model methods

=head2 SQLITE DDL

    CREATE TABLE IF NOT EXISTS "users" (
        "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
        "username"      CHAR(64) NOT NULL UNIQUE, -- User name
        "name"          CHAR(255) DEFAULT NULL, -- Full user name
        "email"         CHAR(255) DEFAULT NULL, -- Email address
        "password"      CHAR(255) NOT NULL, -- Password hash
        "algorithm"     CHAR(64) DEFAULT NULL, -- Password hash Algorithm (SHA256)
        "role"          CHAR(255) DEFAULT NULL, -- Role name
        "flags"         INTEGER DEFAULT 0, -- Flags
        "created"       INTEGER DEFAULT NULL, -- Created at
        "not_before"    INTEGER DEFAULT NULL, -- Not Before
        "not_after"     INTEGER DEFAULT NULL, -- Not After
        "public_key"    TEXT DEFAULT NULL, -- Public Key (RSA/X509)
        "private_key"   TEXT DEFAULT NULL, -- Private Key (RSA/X509)
        "attributes"    TEXT DEFAULT NULL, -- Attributes (JSON)
        "comment"       TEXT DEFAULT NULL -- Comment
    );
    CREATE TABLE IF NOT EXISTS "groups" (
        "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
        "groupname"     CHAR(64) NOT NULL UNIQUE, -- Group name
        "description"   TEXT DEFAULT NULL -- Description
    );
    CREATE TABLE IF NOT EXISTS "realms" (
        "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
        "realmname"     CHAR(64) NOT NULL UNIQUE, -- Realm name
        "realm"         CHAR(255) DEFAULT NULL, -- Realm string
        "satisfy"       CHAR(16) DEFAULT NULL, -- The satisfy policy (All, Any)
        "description"   TEXT DEFAULT NULL -- Description
    );
    CREATE TABLE IF NOT EXISTS "routes" (
        "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
        "realmname"     CHAR(64) DEFAULT NULL, -- Realm name
        "routename"     CHAR(64) DEFAULT NULL, -- Route name
        "method"        CHAR(16) DEFAULT NULL, -- HTTP method (ANY, GET, POST, ...)
        "url"           CHAR(255) DEFAULT NULL, -- URL
        "base"          CHAR(255) DEFAULT NULL, -- Base URL
        "path"          CHAR(255) DEFAULT NULL -- Path of URL (pattern)
    );
    CREATE TABLE IF NOT EXISTS "requirements" (
        "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
        "realmname"     CHAR(64) DEFAULT NULL, -- Realm name
        "provider"      CHAR(64) DEFAULT NULL, -- Provider name (user,group,ip and etc.)
        "entity"        CHAR(64) DEFAULT NULL, -- Entity (operand of expression)
        "op"            CHAR(2) DEFAULT NULL, -- Comparison Operator
        "value"         CHAR(255) DEFAULT NULL -- Test value
    );
    CREATE TABLE IF NOT EXISTS "grpsusrs" (
        "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
        "groupname"     CHAR(64) DEFAULT NULL, -- Group name
        "username"      CHAR(64) DEFAULT NULL -- User name
    );
    CREATE TABLE IF NOT EXISTS "meta" (
        "key"           CHAR(255) NOT NULL UNIQUE PRIMARY KEY,
        "value"         TEXT DEFAULT NULL
    );
    CREATE TABLE IF NOT EXISTS "stats" (
        "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
        "address"       CHAR(40) DEFAULT NULL, -- IPv4/IPv6 client address
        "username"      CHAR(64) DEFAULT NULL, -- User name
        "dismiss"       INTEGER DEFAULT 0, -- Dismissal count
        "updated"       INTEGER DEFAULT NULL -- Update date
    );
    CREATE TABLE IF NOT EXISTS "tokens" (
        "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
        "jti"           CHAR(32) DEFAULT NULL, -- Request ID
        "username"      CHAR(64) DEFAULT NULL, -- User name
        "type"          CHAR(20) DEFAULT NULL, -- Token type (session, refresh, api)
        "clientid"      CAHR(32) DEFAULT NULL, -- Clientid as md5 (User-Agent . Remote-Address)
        "iat"           INTEGER DEFAULT NULL, -- Issue time
        "exp"           INTEGER DEFAULT NULL, -- Expiration time
        "address"       CAHR(40) DEFAULT NULL -- IPv4/IPv6 client address
    );

=head2 MYSQL DDL

    CREATE DATABASE `authdb` /*!40100 DEFAULT CHARACTER SET utf8 COLLATE utf8_bin */;
    CREATE TABLE IF NOT EXISTS `users` (
        `id`            INT(11) NOT NULL AUTO_INCREMENT,
        `username`      VARCHAR(64) NOT NULL, -- User name
        `name`          VARCHAR(255) DEFAULT NULL, -- Full user name
        `email`         VARCHAR(255) DEFAULT NULL, -- Email address
        `password`      VARCHAR(255) NOT NULL, -- Password hash
        `algorithm`     VARCHAR(64) DEFAULT NULL, -- Password hash Algorithm (SHA256)
        `role`          VARCHAR(255) DEFAULT NULL, -- Role name
        `flags`         INT(11) DEFAULT 0, -- Flags
        `created`       INT(11) DEFAULT NULL, -- Created at
        `not_before`    INT(11) DEFAULT NULL, -- Not Before
        `not_after`     INT(11) DEFAULT NULL, -- Not After
        `public_key`    TEXT DEFAULT NULL, -- Public Key (RSA/X509)
        `private_key`   TEXT DEFAULT NULL, -- Private Key (RSA/X509)
        `attributes`    TEXT DEFAULT NULL, -- Attributes (JSON)
        `comment`       TEXT DEFAULT NULL, -- Comment
        PRIMARY KEY (`id`),
        UNIQUE KEY `username` (`username`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
    CREATE TABLE IF NOT EXISTS `groups` (
        `id`            INT(11) NOT NULL AUTO_INCREMENT,
        `groupname`     VARCHAR(64) NOT NULL, -- Group name
        `description`   TEXT DEFAULT NULL, -- Description
        PRIMARY KEY (`id`),
        UNIQUE KEY `groupname` (`groupname`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
    CREATE TABLE IF NOT EXISTS `realms` (
        `id`            INT(11) NOT NULL AUTO_INCREMENT,
        `realmname`     VARCHAR(64) NOT NULL, -- Realm name
        `realm`         VARCHAR(255) DEFAULT NULL, -- Realm string
        `satisfy`       VARCHAR(16) DEFAULT NULL, -- The satisfy policy (All, Any)
        `description`   TEXT DEFAULT NULL, -- Description
        PRIMARY KEY (`id`),
        UNIQUE KEY `realmname` (`realmname`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
    CREATE TABLE IF NOT EXISTS `routes` (
        `id`            INT NOT NULL AUTO_INCREMENT,
        `realmname`     VARCHAR(64) DEFAULT NULL, -- Realm name
        `routename`     VARCHAR(64) DEFAULT NULL, -- Route name
        `method`        VARCHAR(16) DEFAULT NULL, -- HTTP method (ANY, GET, POST, ...)
        `url`           VARCHAR(255) DEFAULT NULL, -- URL
        `base`          VARCHAR(255) DEFAULT NULL, -- Base URL
        `path`          VARCHAR(255) DEFAULT NULL, -- Path of URL (pattern)
        PRIMARY KEY (`id`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
    CREATE TABLE IF NOT EXISTS `requirements` (
        `id`            INT(11) NOT NULL AUTO_INCREMENT,
        `realmname`     VARCHAR(64) DEFAULT NULL, -- Realm name
        `provider`      VARCHAR(64) DEFAULT NULL, -- Provider name (user,group,ip and etc.)
        `entity`        VARCHAR(64) DEFAULT NULL, -- Entity (operand of expression)
        `op`            VARCHAR(2) DEFAULT NULL, -- Comparison Operator
        `value`         VARCHAR(255) DEFAULT NULL, -- Test value
        PRIMARY KEY (`id`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
    CREATE TABLE IF NOT EXISTS `grpsusrs` (
        `id`            INT(11) NOT NULL AUTO_INCREMENT,
        `groupname`     VARCHAR(64) DEFAULT NULL, -- Group name
        `username`      VARCHAR(64) DEFAULT NULL, -- User name
        PRIMARY KEY (`id`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
    CREATE TABLE IF NOT EXISTS `meta` (
        `key`           VARCHAR(255) NOT NULL,
        `value`         TEXT DEFAULT NULL,
        PRIMARY KEY (`key`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
    CREATE TABLE IF NOT EXISTS `stats` (
        `id`            INT(11) NOT NULL AUTO_INCREMENT,
        `address`       VARCHAR(40) DEFAULT NULL, -- IPv4/IPv6 client address
        `username`      VARCHAR(64) DEFAULT NULL, -- User name
        `dismiss`       INT(11) DEFAULT 0, -- Dismissal count
        `updated`       INT(11) DEFAULT NULL, -- Update date
        PRIMARY KEY (`id`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
    CREATE TABLE IF NOT EXISTS `tokens` (
        `id`            INT(11) NOT NULL AUTO_INCREMENT,
        `jti`           VARCHAR(32) DEFAULT NULL, -- Request ID
        `username`      VARCHAR(64) DEFAULT NULL, -- User name
        `type`          VARCHAR(20) DEFAULT NULL, -- Token type (session, refresh, api)
        `clientid`      VARCHAR(32) DEFAULT NULL, -- Clientid as md5 (User-Agent . Remote-Address)
        `iat`           INT(11) DEFAULT NULL, -- Issue time
        `exp`           INT(11) DEFAULT NULL, -- Expiration time
        `address`       VARCHAR(40) DEFAULT NULL, -- IPv4/IPv6 client address
        PRIMARY KEY (`id`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

=head1 METHODS

=head2 new

    my $model = WWW::Suffit::AuthDB::Model->new(
        "sqlite:///tmp/test.db?sqlite_unicode=1"
    );

Creates DBI object

=head2 error

    my $error = $model->error;

Returns error message

    my $status = $model->error( "Error message" );

Sets error message if argument is provided.
This method in "set" context returns status of the operation as status() method.

=head2 dbi

    my $dbi = $model->dbi;

Returns CTK::DBI object of current database connection

=head2 dsn

    my $dsn = $model->dsn;

Returns DSN string of current database connection

=head2 group_add

    $model->group_add(
        groupname   => "wheel",
        description => "This administrator group added by default",
    ) or die($model->error);

Add new group recored

=head2 group_del

    $model->group_del("wheel") or die($model->error);

Delete record by groupname

=head2 group_get

    my %data = $model->group_get("wheel");

Returns data from database by groupname

=head2 group_getall

    my @table = $model->group_getall();

Returns pure data from database

=head2 group_members

    my @members = $model->group_members( "wheel" );

Returns members of specified group

=head2 group_set

    $model->group_set(
        username    => "wheel",
        description => "This administrator group added by default",
    ) or die($model->error);

Update recored by groupname

=head2 grpusr_add

    $model->grpusr_add(
        groupname   => "wheel",
        username    => "root",
    ) or die($model->error);

Add the user to the group

=head2 grpusr_del

    $model->grpusr_del( id => 123 ) or die($model->error);
    $model->grpusr_del( groupname => "wheel" ) or die($model->error);
    $model->grpusr_del( username => "root" ) or die($model->error);

Delete members from groups by id, groupname or username

=head2 grpusr_get

    my %data = $model->grpusr_get( id => 123 );
    my @table = $model->grpusr_get( groupname => "wheel");
    my @table = $model->grpusr_get( username => "root" );

Returns members of groups by id, groupname or username

=head2 init

Initialize DB instance. This method for internal use only

=head2 is_mysql

    print $model->is_mysql ? "Is MySQL" : "Is NOT MySQL"

Returns true if type of current database is MySQL

=head2 is_oracle

    print $model->is_oracle ? "Is Oracle" : "Is NOT Oracle"

Returns true if type of current database is Oracle

=head2 is_pg

    print $model->is_pg ? "Is PostgreSQL" : "Is NOT PostgreSQL"

Returns true if type of current database is PostgreSQL

=head2 is_sqlite

    print $model->is_sqlite ? "Is SQLite" : "Is NOT SQLite"

Returns true if type of current database is SQLite

=head2 meta_del

    $model->meta_del("key") or die($model->error);

Delete record by key

=head2 meta_get

    my %data = $model->meta_get("key");

Returns pair - key and value

    my @table = $model->meta_get();

Returns all data from meta table

=head2 meta_set

    $model->meta_set(key => "value") or die($model->error);

Set pair - key and value

=head2 ping

    $model->ping ? 'OK' : 'Database session is expired';

Checks the connection to database

=head2 realm_add

    $model->realm_add(
        realmname   => "root",
        realm       => "Root pages",
        satisfy     => "Any",
        description => "Index page",
    ) or die($model->error);

Add new realm recored

=head2 realm_del

    $model->realm_del("root") or die($model->error);

Delete record by realmname

=head2 realm_get

    my %data = $model->realm_get("root");

Returns data from database by realmname

=head2 realm_getall

    my @table = $model->realm_getall();

Returns pure data from database

=head2 realm_requirement_add

    $model->realm_requirement_add(
        realmname   => "root",
        provider    => "user",
        entity      => "username",
        op          => "eq",
        value       => "admin",
    ) or die($model->error);

Add the new requirement

=head2 realm_requirement_del

    $model->realm_requirement_del("default") or die($model->error);

Delete requirements by realmname

=head2 realm_requirements

    my @table = $model->realm_requirements("default");

Returns realm's requirements from database by realmname

=head2 realm_routes

    my @table = $model->realm_routes( "realmname" );

Returns realm's routes from database by realmname

=head2 realm_set

    $model->realm_set(
        realmname   => "root",
        realm       => "Root pages",
        satisfy     => "Any",
        description => "Index page (modified)",
    ) or die($model->error);

Update recored by realmname

=head2 reconnect

    $model->reconnect;

This method performs reconnecting to database and returns model object

=head2 route_add

    $model->route_add(
        realmname   => "root",
        routename   => "root",
        method      => "GET",
        url         => "https://localhost:8695/foo/bar",
        base        => "https://localhost:8695/`,
        path        => "/foo/bar",
    ) or die($model->error);

Add the new route to realm

=head2 route_del

    $model->route_del(123) or die($model->error);

Delete record by id

    $model->route_del("root") or die($model->error);

Delete record by realmname

=head2 route_release

    $model->route_release("default") or die($model->error);

Releases the route (removes relation with realm) by realmname

=head2 route_assign

    $model->route_add(
        realmname   => "default",
        routename   => "index",
    ) or die($model->error);

Assignees the realm for route by routename

=head2 route_get

    my %data = $model->route_get(123);

Returns data from database by id

    my @table = $model->route_get("root");

Returns data from database by realmname

=head2 route_getall

    my @table = $model->route_getall();

Returns pure data from database

=head2 route_search

    my @routes = $model->route_search( "ind" );

Performs search route by specified fragment and returns list of found routes

=head2 route_set

    $model->route_set(
        id          => 123,
        realmname   => "root",
        routename   => "root",
        method      => "POST",
        url         => "https://localhost:8695",
        base        => "https://localhost:8695/`,
        path        => "/foo/bar",
    ) or die($model->error);

Update record by id

=head2 stat_get

    my %st = $model->stat_get($address, $username);

Returns statistic information by address and username

=head2 stat_set

    $model->stat_set(
        address => $address,
        username => $username,
        dismiss => 1,
        updated => time,
    ) or die($model->error);

Sets statistic information by address and username

=head2 status

    my $status = $model->status;
    my $status = $model->status( 1 ); # Sets the status value and returns it

Gets or sets the BOOL status of the operation

=head2 token_add

    $model->token_add(
        type        => 'api',
        jti         => $jti,
        username    => $username,
        clientid    => 'qwertyuiqwertyui',
        iat         => time,
        exp         => time + 3600,
        address     => '127.0.0.1',
    ) or die($model->error);

Adds new token for user

=head2 token_del

    $model->token_del( 123 ) or die($model->error);

Delete record by id

    $model->token_del() or die($model->error);

Delete all expired tokens

=head2 token_get

    my %data = $model->token_get( 123 );

Returns data from database by id

=head2 token_get_cond

    my %data = $model->token_get_cond('api', username => $username, jti => $jti);
    my %data = $model->token_get_cond('session', username => $username, clientid => $clientid);

Returns data from database by id jti or clientid

=head2 token_getall

    my @table = $model->token_getall();

Returns all tokens

=head2 token_set

    $model->token_set(
        id          => 123,
        type        => 'api',
        jti         => $jti,
        username    => $username,
        clientid    => 'qwertyuiqwertyui',
        iat         => time,
        exp         => time + 3600,
        address     => '127.0.0.1',
    ) or die($model->error);

Update record by id

=head2 user_add

    $model->user_add(
        username    => "admin",
        name        => "Administrator",
        email       => 'root@localhost',
        password    => "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918",
        algorithm   => "SHA256",
        role        => "System administrator",
        flags       => 0,
        created     => time(),
        not_before  => time(),
        not_after   => undef,
        public_key  => "",
        private_key => "",
        attributes  => qq/{"disabled": 0}/,
        comment     => "This user added by default",
    ) or die($model->error);

Add new user recored

=head2 user_del

    $model->user_del("admin") or die($model->error);

Delete record by username

=head2 user_edit

    $model->user_edit(
        id          => 123,
        username    => $username,
        comment     => $comment,
        email       => $email,
        name        => $name,
        role        => $role,
    ) or die($model->error);

Edit user data by id

=head2 user_get

    my %data = $model->user_get("admin");

Returns data from database by username

=head2 user_getall

    my @table = $model->user_getall();

Returns pure data from database (array of hash)

=head2 user_groups

    my @groups = $model->user_groups( "admin" );

Returns groups of specified user

=head2 user_passwd

    $model->user_passwd(
        username    => "admin",
        password    => "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918",
    ) or die($model->error);

Changes password for user

=head2 user_search

    my @users = $model->user_search( "ad" );

Performs search user by specified fragment and returns list of found users

=head2 user_set

    $model->user_set(
        username    => "admin",
        name        => "Administrator",
        email       => 'root@localhost',
        password    => "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918",
        algorithm   => "SHA256",
        role        => "System administrator",
        flags       => 0,
        not_before  => time(),
        not_after   => undef,
        public_key  => "",
        private_key => "",
        attributes  => qq/{"disabled": 0}/,
        comment     => "This user added by default",
    ) or die($model->error);

Update recored by username

=head2 user_setkeys

    $model->user_setkeys(
        id          => 123,
        public_key  => $public_key,
        private_key => $private_key,
    ) or die($model->error);

Sets keys to user's data

=head2 user_tokens

    my @table = $model->user_tokens($username);

Returns all tokens for user

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<WWW::Suffit::AuthDB>, L<CTK::DBI>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.00';
our $DEBUG //= $ENV{WWW_SUFFIT_AUTHDB_MODEL_DEBUG} || 0;

use Carp;
use CTK::DBI;

use Mojo::URL;
use Mojo::File qw/path/;
use Mojo::Util qw/encode decode monkey_patch/;

use constant {
    DEFAULT_MODEL_URI   => 'sponge://',
    DEFAULT_MODEL_DSN   => 'DBI:Sponge:',
    DEFAULT_MODEL_ATTR  => {
            RaiseError => 0,
            PrintError => 0,
            PrintWarn  => 0,
        },
    DEFAULT_ALGORITHM   => "SHA256",
};

# DDLs
use constant DDL_CREATE_USERS => <<'DDL';
CREATE TABLE IF NOT EXISTS "users" (
    "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    "username"      CHAR(64) NOT NULL UNIQUE, -- User name
    "name"          CHAR(255) DEFAULT NULL, -- Full user name
    "email"         CHAR(255) DEFAULT NULL, -- Email address
    "password"      CHAR(255) NOT NULL, -- Password hash
    "algorithm"     CHAR(64) DEFAULT NULL, -- Password hash Algorithm (SHA256)
    "role"          CHAR(255) DEFAULT NULL, -- Role name
    "flags"         INTEGER DEFAULT 0, -- Flags
    "created"       INTEGER DEFAULT NULL, -- Created at
    "not_before"    INTEGER DEFAULT NULL, -- Not Before
    "not_after"     INTEGER DEFAULT NULL, -- Not After
    "public_key"    TEXT DEFAULT NULL, -- Public Key (RSA/X509)
    "private_key"   TEXT DEFAULT NULL, -- Private Key (RSA/X509)
    "attributes"    TEXT DEFAULT NULL, -- Attributes (JSON)
    "comment"       TEXT DEFAULT NULL -- Comment
)
DDL
use constant DDL_CREATE_GROUPS => <<'DDL';
CREATE TABLE IF NOT EXISTS "groups" (
    "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    "groupname"     CHAR(64) NOT NULL UNIQUE, -- Group name
    "description"   TEXT DEFAULT NULL -- Description
)
DDL
use constant DDL_CREATE_REALMS => <<'DDL';
CREATE TABLE IF NOT EXISTS "realms" (
    "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    "realmname"     CHAR(64) NOT NULL UNIQUE, -- Realm name
    "realm"         CHAR(255) DEFAULT NULL, -- Realm string
    "satisfy"       CHAR(16) DEFAULT NULL, -- The satisfy policy (All, Any)
    "description"   TEXT DEFAULT NULL -- Description
)
DDL
use constant DDL_CREATE_REQUIREMENTS => <<'DDL';
CREATE TABLE IF NOT EXISTS "requirements" (
    "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    "realmname"     CHAR(64) DEFAULT NULL, -- Realm name
    "provider"      CHAR(64) DEFAULT NULL, -- Provider name (user,group,ip and etc.)
    "entity"        CHAR(64) DEFAULT NULL, -- Entity (operand of expression)
    "op"            CHAR(2) DEFAULT NULL, -- Comparison Operator
    "value"         CHAR(255) DEFAULT NULL -- Test value
)
DDL
use constant DDL_CREATE_ROUTES => <<'DDL';
CREATE TABLE IF NOT EXISTS "routes" (
    "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    "realmname"     CHAR(64) DEFAULT NULL, -- Realm name
    "routename"     CHAR(64) DEFAULT NULL, -- Route name
    "method"        CHAR(16) DEFAULT NULL, -- HTTP method (ANY, GET, POST, ...)
    "url"           CHAR(255) DEFAULT NULL, -- URL
    "base"          CHAR(255) DEFAULT NULL, -- Base URL
    "path"          CHAR(255) DEFAULT NULL -- Path of URL (pattern)
)
DDL
use constant DDL_CREATE_GRPSUSRS => <<'DDL';
CREATE TABLE IF NOT EXISTS "grpsusrs" (
    "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    "groupname"     CHAR(64) DEFAULT NULL, -- Group name
    "username"      CHAR(64) DEFAULT NULL -- User name
)
DDL
use constant DDL_CREATE_META => <<'DDL';
CREATE TABLE IF NOT EXISTS "meta" (
    "key"           CHAR(255) NOT NULL UNIQUE PRIMARY KEY,
    "value"         TEXT DEFAULT NULL
)
DDL
use constant DDL_CREATE_STATS => <<'DDL';
CREATE TABLE IF NOT EXISTS "stats" (
    "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    "address"       CHAR(40) DEFAULT NULL, -- IPv4/IPv6 client address
    "username"      CHAR(64) DEFAULT NULL, -- User name
    "dismiss"       INTEGER DEFAULT 0, -- Dismissal count
    "updated"       INTEGER DEFAULT NULL -- Update date
)
DDL
use constant DDL_CREATE_TOKENS => <<'DDL';
CREATE TABLE IF NOT EXISTS "tokens" (
    "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    "jti"           CHAR(32) DEFAULT NULL, -- Request ID
    "username"      CHAR(64) DEFAULT NULL, -- User name
    "type"          CHAR(20) DEFAULT NULL, -- Token type (session, refresh, api)
    "clientid"      CHAR(32) DEFAULT NULL, -- Clientid as md5 (User-Agent . Remote-Address)
    "iat"           INTEGER DEFAULT NULL, -- Issue time
    "exp"           INTEGER DEFAULT NULL, -- Expiration time
    "address"       CHAR(40) DEFAULT NULL -- IPv4/IPv6 client address
)
DDL


# Users
use constant DML_USER_ADD => <<'DML';
INSERT INTO `users`
    (`username`,`name`,`email`,`password`,`algorithm`,`role`,`flags`,`created`,
     `not_before`,`not_after`,`public_key`,`private_key`,`attributes`,`comment`
    )
VALUES
    (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
DML
use constant DML_USER_GET => <<'DML';
SELECT `id`,`username`,`name`,`email`,`password`,`algorithm`,`role`,`flags`,`created`,
       `not_before`,`not_after`,`public_key`,`private_key`,`attributes`,`comment`
FROM `users`
WHERE `username` = ?
DML
use constant DML_USER_SET => <<'DML';
UPDATE `users`
SET `name` = ?, `email` = ?, `password` = ?, `algorithm` = ?, `role` = ?, `flags` = ?,
    `not_before` = ?, `not_after` = ?, `public_key` = ?, `private_key` = ?,
    `attributes` = ?, `comment` = ?
WHERE `username` = ?
DML
use constant DML_USER_DEL => <<'DML';
DELETE FROM `users` WHERE `username` = ?
DML
use constant DML_USER_GETALL => <<'DML';
SELECT `id`,`username`,`name`,`email`,`password`,`algorithm`,`role`,`flags`,`created`,
       `not_before`,`not_after`,`public_key`,`private_key`,`attributes`,`comment`
FROM `users`
ORDER BY `username` ASC
DML
use constant DML_PASSWD => <<'DML';
UPDATE `users`
SET `password` = ?
WHERE `username` = ?
DML
use constant DML_USER_SEARCH => <<'DML';
SELECT `id`,`username`,`name`,`role`
FROM `users`
WHERE 1 = 1
%s
ORDER BY `username` ASC
LIMIT 10
DML
use constant DML_USER_GROUPS => <<'DML';
SELECT
    groups.`id` AS `id`,
    groups.`groupname` AS `groupname`,
    groups.`description` AS `description`
FROM
    grpsusrs
    LEFT OUTER JOIN groups ON (groups.`groupname` = grpsusrs.`groupname`)
WHERE 1 = 1
    AND grpsusrs.`username` = ?
ORDER BY
    grpsusrs.`groupname` ASC
DML
use constant DML_USER_EDIT => <<'DML';
UPDATE `users`
SET `name` = ?, `email` = ?, `role` = ?, `comment` = ?
WHERE `id` = ?
DML
use constant DML_USER_SETKEYS => <<'DML';
UPDATE `users`
SET `public_key` = ?, `private_key` = ?
WHERE `id` = ?
DML

# Groups
use constant DML_GROUP_ADD => <<'DML';
INSERT INTO `groups` (`groupname`,`description`)
VALUES (?,?)
DML
use constant DML_GROUP_GET => <<'DML';
SELECT `id`,`groupname`,`description`
FROM `groups`
WHERE `groupname` = ?
DML
use constant DML_GROUP_SET => <<'DML';
UPDATE `groups`
SET `description` = ?
WHERE `groupname` = ?
DML
use constant DML_GROUP_DEL => <<'DML';
DELETE FROM `groups` WHERE `groupname` = ?
DML
use constant DML_GROUP_GETALL => <<'DML';
SELECT `id`,`groupname`,`description`
FROM `groups`
ORDER BY `groupname` ASC
DML
use constant DML_GROUP_MEMBERS => <<'DML';
SELECT
    users.`id` AS `id`,
    users.`username` AS `username`,
    users.`name` AS `name`,
    users.`role` AS `role`
FROM
    users
    LEFT OUTER JOIN grpsusrs ON (grpsusrs.`username` = users.`username`)
WHERE 1 = 1
    AND grpsusrs.`groupname` = ?
ORDER BY
    grpsusrs.`username` ASC
DML


# Realms
use constant DML_REALM_ADD => <<'DML';
INSERT INTO `realms` (`realmname`,`realm`,`satisfy`,`description`)
VALUES (?,?,?,?)
DML
use constant DML_REALM_GET => <<'DML';
SELECT `id`,`realmname`,`realm`,`satisfy`,`description`
FROM `realms`
WHERE `realmname` = ?
DML
use constant DML_REALM_SET => <<'DML';
UPDATE `realms`
SET `realm` = ?,`satisfy` =?, `description` = ?
WHERE `realmname` = ?
DML
use constant DML_REALM_DEL => <<'DML';
DELETE FROM `realms` WHERE `realmname` = ?
DML
use constant DML_REALM_GETALL => <<'DML';
SELECT `id`,`realmname`,`realm`,`satisfy`,`description`
FROM `realms`
ORDER BY `realmname` ASC
DML


# Routes
use constant DML_ROUTE_ADD => <<'DML';
INSERT INTO `routes`
    (`realmname`,`routename`,`method`,`url`,`base`,`path`)
VALUES
    (?,?,?,?,?,?)
DML
use constant DML_ROUTE_GET_BY_ROUTE => <<'DML';
SELECT `id`,`realmname`,`routename`,`method`,`url`,`base`,`path`
FROM `routes`
WHERE `routename` = ?
DML
use constant DML_ROUTE_GET_BY_REALM => <<'DML';
SELECT `id`,`realmname`,`routename`,`method`,`url`,`base`,`path`
FROM `routes`
WHERE `realmname` = ?
ORDER BY `routename` ASC
DML
use constant DML_ROUTE_SET => <<'DML';
UPDATE `routes`
SET `realmname` = ?, `method` = ?, `url` = ?, `base` = ?, `path` = ?
WHERE `routename` = ?
DML
use constant DML_ROUTE_DEL_BY_ROUTE => <<DML;
DELETE FROM `routes`
WHERE `routename` = ?
DML
use constant DML_ROUTE_DEL_BY_REALM => <<DML;
DELETE FROM `routes`
WHERE `realmname` = ?
DML
use constant DML_ROUTE_GETALL => <<'DML';
SELECT `id`,`realmname`,`routename`,`method`,`url`,`base`,`path`
FROM `routes`
ORDER BY `routename` ASC
DML
use constant DML_ROUTE_SEARCH => <<'DML';
SELECT `id`,`realmname`,`routename`,`method`,`url`,`base`,`path`
FROM `routes`
WHERE 1 = 1
%s
ORDER BY `routename` ASC
LIMIT 10
DML
use constant DML_ROUTE_RELEASE_BY_REALM => <<DML;
UPDATE `routes`
SET `realmname` = NULL
WHERE `realmname` = ?
DML
use constant DML_ROUTE_ASSIGN_BY_ROUTE => <<DML;
UPDATE `routes`
SET `realmname` = ?
WHERE `routename` = ?
DML


# Requirements
use constant DML_REQUIREMENT_ADD => <<'DML';
INSERT INTO `requirements`
    (`realmname`,`provider`,`entity`,`op`,`value`)
VALUES
    (?,?,?,?,?)
DML
use constant DML_REQUIREMENT_GET_BY_ID => <<'DML';
SELECT `id`,`realmname`,`provider`,`entity`,`op`,`value`
FROM `requirements`
WHERE `id` = ?
DML
use constant DML_REQUIREMENT_GET_BY_REALM => <<'DML';
SELECT `id`,`realmname`,`provider`,`entity`,`op`,`value`
FROM `requirements`
WHERE `realmname` = ?
ORDER BY `provider` ASC, `entity` ASC, `op` ASC, `value` ASC
DML
use constant DML_REQUIREMENT_DEL_BY_ID => <<DML;
DELETE FROM `requirements`
WHERE `id` = ?
DML
use constant DML_REQUIREMENT_DEL_BY_REALM => <<DML;
DELETE FROM `requirements`
WHERE `realmname` = ?
DML

# Groups-Users
use constant DML_GRPUSR_ADD => <<'DML';
INSERT INTO `grpsusrs`
    (`groupname`,`username`)
VALUES
    (?,?)
DML
use constant DML_GRPUSR_GET_BY_ID => <<'DML';
SELECT `id`,`groupname`,`username`
FROM `grpsusrs`
WHERE `id` = ?
DML
use constant DML_GRPUSR_GET_BY_GROUP_USER => <<'DML';
SELECT `id`,`groupname`,`username`
FROM `grpsusrs`
WHERE `groupname` = ? AND `username` = ?
DML
use constant DML_GRPUSR_GET_BY_GROUP => <<'DML';
SELECT `id`,`groupname`,`username`
FROM `grpsusrs`
WHERE `groupname` = ?
DML
use constant DML_GRPUSR_GET_BY_USER => <<'DML';
SELECT `id`,`groupname`,`username`
FROM `grpsusrs`
WHERE `username` = ?
DML
use constant DML_GRPUSR_DEL_BY_ID => <<DML;
DELETE FROM `grpsusrs`
WHERE `id` = ?
DML
use constant DML_GRPUSR_DEL_BY_GROUP => <<DML;
DELETE FROM `grpsusrs`
WHERE `groupname` = ?
DML
use constant DML_GRPUSR_DEL_BY_USER => <<DML;
DELETE FROM `grpsusrs`
WHERE `username` = ?
DML

# Meta
use constant DML_META_ADD => <<'DML';
INSERT INTO `meta`
    (`key`,`value`)
VALUES
    (?,?)
DML
use constant DML_META_GET => <<'DML';
SELECT `key`,`value`
FROM `meta`
WHERE `key` = ?
DML
use constant DML_META_GETALL => <<'DML';
SELECT `key`,`value`
FROM `meta`
ORDER BY `key` ASC
DML
use constant DML_META_SET => <<'DML';
UPDATE `meta`
SET `value` = ?
WHERE `key` = ?
DML
use constant DML_META_DEL => <<DML;
DELETE FROM `meta`
WHERE `key` = ?
DML

# Tokens
use constant DML_TOKEN_GET => <<'DML';
SELECT `id`,`jti`,`username`,`type`,`clientid`,`iat`,`exp`,`address`
FROM `tokens`
WHERE `id` =?
DML
use constant DML_TOKEN_GET_BY_USERNAME_AND_CLIENTID => <<'DML';
SELECT `id`,`jti`,`username`,`type`,`clientid`,`iat`,`exp`,`address`
FROM `tokens`
WHERE `username` = ? AND `clientid` = ? AND `type` = "session"
DML
use constant DML_TOKEN_GET_BY_USERNAME_AND_JTI => <<'DML';
SELECT `id`,`jti`,`username`,`type`,`clientid`,`iat`,`exp`,`address`
FROM `tokens`
WHERE `username` = ? AND `jti` = ?
DML
use constant DML_TOKEN_ADD => <<'DML';
INSERT INTO `tokens` (`jti`,`username`,`type`,`clientid`,`iat`,`exp`,`address`)
VALUES (?,?,?,?,?,?,?)
DML
use constant DML_TOKEN_SET => <<'DML';
UPDATE `tokens`
SET `jti` = ?, `username` =?, `type` = ?, `clientid` = ?, `iat` = ?, `exp` = ?, `address` = ?
WHERE `id` = ?
DML
use constant DML_TOKEN_GET_BY_USERNAME => <<DML;
SELECT `id`,`jti`,`username`,`type`,`clientid`,`iat`,`exp`,`address`
FROM `tokens`
WHERE `username` = ?
ORDER BY `iat` DESC
DML
use constant DML_TOKEN_GET_ALL => <<'DML';
SELECT `id`,`jti`,`username`,`type`,`clientid`,`iat`,`exp`,`address`
FROM `tokens`
ORDER BY `username` ASC, `iat` DESC
DML
use constant DML_TOKEN_DEL => <<'DML';
DELETE FROM `tokens`
WHERE `id` = ?
DML
use constant DML_TOKEN_DEL_EXPIRED => <<'DML';
DELETE FROM `tokens`
WHERE `exp` IS NOT NULL AND `exp` > 0 AND `exp` < ?
DML

# Stat
use constant DML_STAT_GET => <<'DML';
SELECT `id`,`address`,`username`,`dismiss`,`updated`
FROM `stats`
WHERE `address` = ? AND `username` = ?
DML
use constant DML_STAT_ADD => <<'DML';
INSERT INTO `stats` (`address`,`username`,`dismiss`,`updated`)
VALUES (?,?,?,?)
DML
use constant DML_STAT_SET => <<'DML';
UPDATE `stats`
SET `address` = ?, `username` =?, `dismiss` = ?, `updated` = ?
WHERE `id` = ?
DML

# Set method ping to DBD::Sponge
monkey_patch 'DBD::Sponge::db', ping => sub { 1 };

sub new {
    my $class = shift;
    my $model_uri = shift || DEFAULT_MODEL_URI;
       croak 'Invalid model URI' unless $model_uri;
    my $opts = scalar(@_) ? scalar(@_) > 1 ? {@_} : {%{$_[0]}} : {};
    my $uri = Mojo::URL->new($model_uri);
    my $driver = lc($uri->protocol // '');
    my $host = $uri->host || 'localhost';
    my $port = $uri->port;
    my $query = $uri->query;

    # Default attributes
    my %attrs = ();
    $attrs{$_} = $query->param($_) for @{$query->names};
    my %dma = (%{(DEFAULT_MODEL_ATTR)}, %$opts);
    foreach my $dk (keys %dma) {
        $attrs{$dk} //= $dma{$dk}
    }

    # No attributes
    my $timeout = exists($attrs{timeout}) ? delete($attrs{timeout}) : undef;
    my ($dsn, $file, $database);
    my $username = $uri->username // '';
    my $password = $uri->password // '';

    # Set DSN
    my @params = ();
    if ($driver eq 'sqlite' or $driver eq 'file') {
        $driver = 'sqlite';
        $file = $uri->path->leading_slash(1)->trailing_slash(0)->to_string;
        $dsn = sprintf('DBI:SQLite:dbname=%s', $file);
    } elsif ($driver eq 'mysql' or $driver eq 'maria' or $driver eq 'mariadb') {
        $driver = 'mysql';
        $database = $uri->path->leading_slash(0)->trailing_slash(0)->to_string // '';
        push @params, sprintf("%s=%s", "database", $database) if length $database;
        push @params, sprintf("%s=%s", "host", $host);
        push @params, sprintf("%s=%s", "port", $port) if $port;
        $dsn = sprintf('DBI:mysql:%s', join(";", @params) || '');
    } elsif ($driver eq 'pg' or $driver eq 'pgsql' or $driver eq 'postgres' or $driver eq 'postgresql') {
        $driver = 'pg';
        $database = $uri->path->leading_slash(0)->trailing_slash(0)->to_string // '';
        push @params, sprintf("%s=%s", "dbname", $database) if length $database;
        push @params, sprintf("%s=%s", "host", $host);
        push @params, sprintf("%s=%s", "port", $port) if $port;
        $dsn = sprintf('DBI:Pg:%s', join(";", @params) || '');
    } elsif ($driver eq 'oracle') {
        $database = $uri->path->leading_slash(0)->trailing_slash(0)->to_string // '';
        push @params, sprintf("%s=%s", "host", $host);
        push @params, sprintf("%s=%s", "sid", $database) if length $database;
        push @params, sprintf("%s=%s", "port", $port) if $port;
        $dsn = sprintf('DBI:Oracle:%s', join(";", @params) || '');
    } else {
        $dsn = DEFAULT_MODEL_DSN;
    }

    # DB
    my $db = CTK::DBI->new(
        -dsn        => $dsn,
        -debug      => $DEBUG ? 1 : 0,
        -username   => $username,
        -password   => $password,
        -attr       => {%attrs},
        $timeout ? (
            -timeout_connect => $timeout,
            -timeout_request => $timeout,
        ) : (),
    );

    # Create
    my $self = bless {
            origin_uri  => $model_uri,
            driver      => $driver,
            host        => $host,
            port        => $port,
            timeout     => $timeout,
            file        => $file,
            dsn         => $dsn,
            attributes  => {%attrs},
            database    => $database,
            username    => $username,
            password    => $password,
            dbi         => $db,
            pid         => $$,
            is_inited   => 0,
            status      => 0,
            error       => qq{E2000: The database "$dsn" is not initialized},
        }, $class;

    return $self->init;
}
sub init {
    my $self = shift;
    my $db = $self->{dbi};
    return $self unless $db;
    return $self if $self->{is_inited};
    my $dbh = $db->connect;

    # SQLite
    my $is_new = 0;
    if ($self->{driver} eq 'sqlite') {
        my $file = $dbh->sqlite_db_filename();
        unless ($file && (-e $file) && !(-z $file)) {
            path($file)->touch->chmod(0666); # rw-rw-rw-
            $is_new = 1;
        }
    }

    # Defaults
    my $status = 1; # Ok
    my $error = "";
    if (!$dbh) {
        $error = sprintf("E2001: Can't connect to database \"%s\": %s", $self->{dsn}, $DBI::errstr || "unknown error");
        $status = 0;
    } elsif ($is_new) {
        foreach my $sql (DDL_CREATE_USERS, DDL_CREATE_GROUPS, DDL_CREATE_REALMS, DDL_CREATE_ROUTES,
            DDL_CREATE_REQUIREMENTS, DDL_CREATE_GRPSUSRS, DDL_CREATE_META, DDL_CREATE_STATS, DDL_CREATE_TOKENS) {
            $db->execute($sql);
            last if $dbh->err;
        }
        $error = $dbh->errstr();
        $status = 0 if $dbh->err;
    }
    unless ($error) { # No errors
        unless ($dbh->ping) {
            $error = sprintf("E2002: Can't init database \"%s\". Ping failed: %s",
                $self->{dsn}, $dbh->errstr() || "unknown error");
            $status = 0;
        }
    }

    $self->{status} = $status;
    $self->{error} = $error;
    $self->{is_inited} = 1 if $status;
    return $self;
}
sub status {
    my $self = shift;
    my $value = shift;
    return $self->{status} || 0 unless defined($value);
    $self->{status} = $value ? 1 : 0;
    return $self->{status};
}
sub error {
    my $self = shift;
    my $value = shift;
    return $self->{error} // '' unless defined($value);
    $self->{error} = $value;
    $self->status($value ne "" ? 0 : 1);
    return $value;
}
sub ping {
    my $self = shift;
    return 0 unless $self->{dsn};
    my $dbi = $self->{dbi};
    return 0 unless $dbi;
    my $dbh = $dbi->{dbh};
    return 0 unless $dbh;
    return 0 unless $dbh->can('ping');
    return $dbh->ping();
}
sub reconnect {
    my $self = shift;
    delete $self->{dbi};
    my $dsn = $self->{dsn};

    # DB
    my $attrs = $self->{attributes} || {};
    $self->{dbi} = CTK::DBI->new(
        -dsn        => $dsn,
        -debug      => $DEBUG ? 1 : 0,
        -username   => $self->{username},
        -password   => $self->{password},
        -attr       => { %$attrs },
        $self->{timeout} ? (
            -timeout_connect => $self->{timeout},
            -timeout_request => $self->{timeout},
        ) : (),
    );

    # Check connect result
    my $dbh = $self->{dbi}->connect;
    unless ($dbh) {
        $self->error(sprintf("E2003: Can't reconnect to database \"%s\": %s", $dsn, $DBI::errstr || "unknown error"));
        return $self;
    }

    # Ping
    unless ($self->ping) {
        $self->error(sprintf("E2004: Can't reinit database \"%s\". Ping failed: %s", $dsn, $dbh->errstr || "unknown error"));
        return $self;
    }

    # Ok
    return $self;
}
sub dbi {
    my $self = shift;
    my $pid = $self->{pid};
    $self->error(""); # reset error string

    # Fork-safety
    if ($pid && "$pid" ne "$$") {
        delete $self->{pid};
        $self->reconnect;
    }
    $self->{pid} //= $$;

    # Return dbi object (CTK::DBI instance) or undef
    return $self->ping ? $self->{dbi} : undef;
}
sub dsn {
    my $self = shift;
    return $self->{dsn};
}
sub is_sqlite {
    my $self = shift;
    return $self->{driver} eq 'sqlite' ? 1 : 0;
}
sub is_mysql {
    my $self = shift;
    return $self->{driver} eq 'mysql' ? 1 : 0;
}
sub is_pg {
    my $self = shift;
    return $self->{driver} eq 'pg' ? 1 : 0;
}
sub is_oracle {
    my $self = shift;
    return $self->{driver} eq 'oracle' ? 1 : 0;
}

# CRUD Methods

sub user_add {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;

    #encode("UTF-8", $data{name} // '')
    #encode("UTF-8", $data{role} // '')
    #encode("UTF-8", $data{comment} // ''),

    # Add
    $dbi->execute(DML_USER_ADD,
        $data{username}, $data{name}, $data{email}, $data{password},
        uc($data{algorithm} || DEFAULT_ALGORITHM), $data{role}, $data{flags},
        $data{created} || time(), $data{not_before} || time(), $data{not_after},
        $data{public_key}, $data{private_key}, $data{attributes},
        $data{comment},
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("E2010: Can't insert new record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}
sub user_get {
    my $self = shift;
    my $username = shift // '';
    my $dbi = $self->dbi or return ();
    unless (length $username) {
        $self->error("E2011: No username specified");
        return ();
    }

    my %rec = $dbi->recordh(DML_USER_GET, $username);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2012: Can't get record: %s", $dbi->connect->errstr // ''));
        return ();
    }
    return () unless $rec{id};

    # Decode fields
    #$rec{name} = decode("UTF-8", $rec{name});
    #$rec{role} = decode("UTF-8", $rec{role});
    #$rec{comment} = decode("UTF-8", $rec{comment});
    return %rec;
}
sub user_set {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;
    unless (length($data{username} // '')) {
        $self->error("E2013: No username specified");
        return 0;
    }

    # Set
    $dbi->execute(DML_USER_SET,
        $data{name}, $data{email}, $data{password},
        uc($data{algorithm} || DEFAULT_ALGORITHM), $data{role}, $data{flags},
        $data{not_before} || time(), $data{not_after},
        $data{public_key}, $data{private_key}, $data{attributes},
        $data{comment},
        $data{username},
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("E2014: Can't update record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}
sub user_passwd {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;
    unless (length($data{username} // '')) {
        $self->error("E2015: No username specified");
        return 0;
    }

    # Passwd
    $dbi->execute(DML_PASSWD, $data{password}, $data{username});
    if ($dbi->connect->err) {
        $self->error(sprintf("E2016: Can't update record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}
sub user_del {
    my $self = shift;
    my $username = shift // '';
    my $dbi = $self->dbi or return 0;
    unless (length($username)) {
        $self->error("E2017: No username specified");
        return 0;
    }

    $dbi->execute(DML_USER_DEL, $username);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2018: Can't delete record: %s", $dbi->connect->errstr // ''));
    }
    return $self->status;
}
sub user_getall {
    my $self = shift;
    my $dbi = $self->dbi or return ();

    my @tbl = $dbi->table(DML_USER_GETALL);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2019: Can't get records: %s", $dbi->connect->errstr // ''));
        return ();
    }

    my @ret;
    foreach my $arr (@tbl) {
        push @ret, {
            id              => $arr->[0],
            username        => $arr->[1],
            name            => $arr->[2],
            email           => $arr->[3],
            password        => $arr->[4],
            algorithm       => $arr->[5],
            role            => $arr->[6],
            flags           => $arr->[7],
            created         => $arr->[8],
            not_before      => $arr->[9],
            not_after       => $arr->[10],
            public_key      => $arr->[11],
            private_key     => $arr->[12],
            attributes      => $arr->[13],
            comment         => $arr->[14],
        };
    }
    return @ret;
}
sub user_search {
    my $self = shift;
    my $_search = shift // '';
    my $dbi = $self->dbi or return ();
    my $search = $dbi->connect->quote(sprintf("%%%s%%", $_search));
    my @where;
    push @where, "AND UPPER(`username`) LIKE UPPER($search)" if $_search;
    my @tbl = $dbi->table(sprintf(DML_USER_SEARCH, join("\n", @where)));
    if ($dbi->connect->err) {
        $self->error(sprintf("E2020: Can't get records: %s", $dbi->connect->errstr // ''));
        return ();
    }

    my @ret;
    foreach my $arr (@tbl) {
        push @ret, {
            id              => $arr->[0],
            username        => $arr->[1],
            name            => $arr->[2],
            role            => $arr->[3],
        };
    }
    return @ret;
}
sub user_groups {
    my $self = shift;
    my $username = shift // '';
    my $dbi = $self->dbi or return ();
    unless (length $username) {
        $self->error("E2021: No username specified");
        return ();
    }

    my @tbl = $dbi->table(DML_USER_GROUPS, $username);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2022: Can't get records: %s", $dbi->connect->errstr // ''));
        return ();
    }

    my @ret;
    foreach my $arr (@tbl) {
        push @ret, {
            id          => $arr->[0],
            groupname   => $arr->[1],
            description => $arr->[2],
        } if $arr->[0];
    }
    return @ret;
}
sub user_edit {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;
    unless ($data{id}) {
        $self->error("E2023: No id of user specified");
        return 0;
    }

    # Set
    $dbi->execute(DML_USER_EDIT,
        $data{name}, $data{email}, $data{role}, $data{comment},
        $data{id},
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("E2024: Can't update record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}
sub user_setkeys {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;
    unless ($data{id}) {
        $self->error("E2025: No id of user specified");
        return 0;
    }

    # Set
    $dbi->execute(DML_USER_SETKEYS, $data{public_key}, $data{private_key}, $data{id});
    if ($dbi->connect->err) {
        $self->error(sprintf("E2026: Can't update record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}
sub user_tokens {
    my $self = shift;
    my $username = shift // '';
    my $dbi = $self->dbi or return ();
    unless (length $username) {
        $self->error("E2027: No username specified");
        return ();
    }
    my @tbl = $dbi->table(DML_TOKEN_GET_BY_USERNAME, $username);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2028: Can't get records: %s", $dbi->connect->errstr // ''));
        return ();
    }

    my @ret;
    foreach my $arr (@tbl) {
        push @ret, {
            id          => $arr->[0],
            jti         => $arr->[1],
            username    => $arr->[2],
            type        => $arr->[3],
            clientid    => $arr->[4],
            iat         => $arr->[5],
            exp         => $arr->[6],
            address     => $arr->[7],
        };
    }

    return @ret;
}


sub group_add {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;

    # Add
    $dbi->execute(DML_GROUP_ADD, $data{groupname}, $data{description});
    if ($dbi->connect->err) {
        $self->error(sprintf("E2030: Can't insert new record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}
sub group_get {
    my $self = shift;
    my $groupname = shift // '';
    my $dbi = $self->dbi or return ();
    unless (length $groupname) {
        $self->error("E2031: No groupname specified");
        return ();
    }

    my %rec = $dbi->recordh(DML_GROUP_GET, $groupname);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2032: Can't get record: %s", $dbi->connect->errstr // ''));
        return ();
    }
    return () unless $rec{id};

    return %rec;
}
sub group_set {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;
    unless (length($data{groupname} // '')) {
        $self->error("E2033: No groupname specified");
        return 0;
    }

    # Set
    $dbi->execute(DML_GROUP_SET,
        $data{description},
        $data{groupname}
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("E2034: Can't update record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}
sub group_del {
    my $self = shift;
    my $groupname = shift // '';
    my $dbi = $self->dbi or return 0;
    unless (length($groupname)) {
        $self->error("E2035: No groupname specified");
        return 0;
    }

    $dbi->execute(DML_GROUP_DEL, $groupname);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2036: Can't delete record: %s", $dbi->connect->errstr // ''));
    }
    return $self->status;
}
sub group_getall {
    my $self = shift;
    my $dbi = $self->dbi or return ();
    my @tbl = $dbi->table(DML_GROUP_GETALL);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2037: Can't get records: %s", $dbi->connect->errstr // ''));
        return ();
    }

    my @ret;
    foreach my $arr (@tbl) {
        push @ret, {
            id              => $arr->[0],
            groupname       => $arr->[1],
            description     => $arr->[2],
        };
    }
    return @ret;
}
sub group_members {
    my $self = shift;
    my $groupname = shift // '';
    my $dbi = $self->dbi or return ();
    unless (length $groupname) {
        $self->error("E2038: No groupname specified");
        return ();
    }

    my @tbl = $dbi->table(DML_GROUP_MEMBERS, $groupname);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2039: Can't get records: %s", $dbi->connect->errstr // ''));
        return ();
    }

    my @ret;
    foreach my $arr (@tbl) {
        push @ret, {
            id          => $arr->[0],
            username    => $arr->[1],
            name        => $arr->[2],
            role        => $arr->[3],
        } if $arr->[0];
    }
    return @ret;
}


sub realm_add {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;

    # Add
    $dbi->execute(DML_REALM_ADD,
        $data{realmname}, $data{realm}, $data{satisfy}, $data{description}
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("E2040: Can't insert new record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}
sub realm_get {
    my $self = shift;
    my $realmname = shift // '';
    my $dbi = $self->dbi or return ();
    unless (length $realmname) {
        $self->error("E2041: No realmname specified");
        return ();
    }

    my %rec = $dbi->recordh(DML_REALM_GET, $realmname);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2042: Can't get record: %s", $dbi->connect->errstr // ''));
        return ();
    }
    return () unless $rec{id};

    return %rec;
}
sub realm_set {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;
    unless (length($data{realmname} // '')) {
        $self->error("E2043: No realmname specified");
        return 0;
    }

    # Set
    $dbi->execute(DML_REALM_SET,
        $data{realm}, $data{satisfy}, $data{description}, $data{realmname}
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("E2044: Can't update record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}
sub realm_del {
    my $self = shift;
    my $realmname = shift // '';
    my $dbi = $self->dbi or return 0;
    unless (length($realmname)) {
        $self->error("E2045: No realmname specified");
        return 0;
    }

    $dbi->execute(DML_REALM_DEL, $realmname);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2046: Can't delete record: %s", $dbi->connect->errstr // ''));
    }
    return $self->status;
}
sub realm_getall {
    my $self = shift;
    my $dbi = $self->dbi or return ();
    my @tbl = $dbi->table(DML_REALM_GETALL);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2047: Can't get records: %s", $dbi->connect->errstr // ''));
        return ();
    }

    my @ret;
    foreach my $arr (@tbl) {
        push @ret, {
            id          => $arr->[0],
            realmname   => $arr->[1],
            realm       => $arr->[2],
            satisfy     => $arr->[3],
            description => $arr->[4],
        };
    }

    return @ret;
}
sub realm_requirements {
    my $self = shift;
    my $realmname = shift;
    my $dbi = $self->dbi or return ();
    unless ($realmname) {
        $self->error("E2048: No realmname specified");
        return ();
    }
    my @tbl = $dbi->table(DML_REQUIREMENT_GET_BY_REALM, $realmname);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2049: Can't get record(s): %s", $dbi->connect->errstr // ''));
        return ();
    }

    my @ret;
    foreach my $arr (@tbl) {
        push @ret, {
            id          => $arr->[0],
            realmname   => $arr->[1],
            provider    => $arr->[2],
            entity      => $arr->[3],
            op          => $arr->[4],
            value       => $arr->[5],
        };
    }

    return @ret;
}
sub realm_requirement_del {
    my $self = shift;
    my $realmname = shift // '';
    my $dbi = $self->dbi or return 0;
    unless (length($realmname)) {
        $self->error("E2050: No realmname specified");
        return 0;
    }
    $dbi->execute(DML_REQUIREMENT_DEL_BY_REALM, $realmname);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2051: Can't delete record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}
sub realm_requirement_add {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;

    # Add
    $dbi->execute(DML_REQUIREMENT_ADD,
        $data{realmname}, $data{provider}, $data{entity}, $data{op}, $data{value}
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("E2052: Can't insert new record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}
sub realm_routes {
    my $self = shift;
    my $realmname = shift;
    my $dbi = $self->dbi or return ();
    unless ($realmname) {
        $self->error("E2053: No realmname specified");
        return ();
    }
    my @tbl = $dbi->table(DML_ROUTE_GET_BY_REALM, $realmname);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2054: Can't get record(s): %s", $dbi->connect->errstr // ''));
        return ();
    }

    my @ret;
    foreach my $arr (@tbl) {
        push @ret, {
            id          => $arr->[0],
            realmname   => $arr->[1],
            routename   => $arr->[2],
            method      => $arr->[3],
            url         => $arr->[4],
            base        => $arr->[5],
            path        => $arr->[6],
        };
    }

    return @ret;
}

sub route_add {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;

    # Add
    $dbi->execute(DML_ROUTE_ADD,
        $data{realmname}, $data{routename}, $data{method},
        $data{url}, $data{base}, $data{path}
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("E2060: Can't insert new record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}
sub route_get {
    my $self = shift;
    my $routename = shift // '';
    my $dbi = $self->dbi or return ();
    unless ($routename) {
        $self->error("E2061: No routename specified");
        return ();
    }

    my %rec = $dbi->recordh(DML_ROUTE_GET_BY_ROUTE, $routename);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2062: Can't get record(s): %s", $dbi->connect->errstr // ''));
        return ();
    }
    return () unless $rec{id};

    return %rec;
}
sub route_set {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;
    unless ($data{id}) {
        $self->error("E2063: No id specified");
        return 0;
    }

    # Set
    $dbi->execute(DML_ROUTE_SET,
        $data{realmname}, $data{method},
        $data{url}, $data{base}, $data{path},
        $data{routename}
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("E2064: Can't update record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}
sub route_del {
    my $self = shift;
    my $routename = shift // '';
    my $dbi = $self->dbi or return 0;
    unless (length($routename)) {
        $self->error("E2065: No routename specified");
        return 0;
    }

    $dbi->execute(DML_ROUTE_DEL_BY_ROUTE, $routename);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2066: Can't delete record: %s", $dbi->connect->errstr // ''));
    }
    return $self->status;
}
sub route_getall {
    my $self = shift;
    my $dbi = $self->dbi or return ();

    # Get table
    my @tbl = $dbi->table(DML_ROUTE_GETALL);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2067: Can't get records: %s", $dbi->connect->errstr // ''));
        return ();
    }

    my @ret;
    foreach my $arr (@tbl) {
        push @ret, {
            id          => $arr->[0],
            realmname   => $arr->[1],
            routename   => $arr->[2],
            method      => $arr->[3],
            url         => $arr->[4],
            base        => $arr->[5],
            path        => $arr->[6],
        };
    }

    return @ret;
}
sub route_search {
    my $self = shift;
    my $_search = shift // '';
    my $dbi = $self->dbi or return ();
    my $search = $dbi->connect->quote(sprintf("%%%s%%", $_search));
    my @where;
    push @where, "AND UPPER(`routename`) LIKE UPPER($search)" if $_search;
    my @tbl = $dbi->table(sprintf(DML_ROUTE_SEARCH, join("\n", @where)));
    if ($dbi->connect->err) {
        $self->error(sprintf("E2068: Can't get records: %s", $dbi->connect->errstr // ''));
        return ();
    }

    my @ret;
    foreach my $arr (@tbl) {
        push @ret, {
            id          => $arr->[0],
            realmname   => $arr->[1],
            routename   => $arr->[2],
            method      => $arr->[3],
            url         => $arr->[4],
            base        => $arr->[5],
            path        => $arr->[6],
        };
    }
    return @ret;
}
sub route_release {
    my $self = shift;
    my $realmname = shift // '';
    my $dbi = $self->dbi or return 0;
    unless (length($realmname)) {
        $self->error("E2069: No realmname specified");
        return 0;
    }

    $dbi->execute(DML_ROUTE_RELEASE_BY_REALM, $realmname);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2070: Can't update record: %s", $dbi->connect->errstr // ''));
    }
    return $self->status;
}
sub route_assign {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;
    unless (defined($data{realmname}) && length($data{realmname})) {
        $self->error("E2071: No realmname specified");
        return 0;
    }
    unless (defined($data{routename}) && length($data{routename})) {
        $self->error("E2072: No routename specified");
        return 0;
    }

    # Set
    $dbi->execute(DML_ROUTE_ASSIGN_BY_ROUTE, $data{realmname}, $data{routename});
    if ($dbi->connect->err) {
        $self->error(sprintf("E2073: Can't update record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}


sub grpusr_add {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;

    # Add
    $dbi->execute(DML_GRPUSR_ADD, $data{groupname}, $data{username});
    if ($dbi->connect->err) {
        $self->error(sprintf("E2080: Can't insert new record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}
sub grpusr_get {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return ();

    my @ret;
    if ($data{id} && is_int($data{id})) { # By ID
        @ret = $dbi->recordh(DML_GRPUSR_GET_BY_ID, $data{id});
    } elsif ($data{groupname} and $data{username}) { # By Group and User
        @ret = $dbi->recordh(DML_GRPUSR_GET_BY_GROUP_USER, $data{groupname}, $data{username});
    } elsif ($data{groupname}) { # By Group
        @ret = $dbi->table(DML_GRPUSR_GET_BY_GROUP, $data{groupname});
    } elsif ($data{username}) { # By User
        @ret = $dbi->table(DML_GRPUSR_GET_BY_USER, $data{username});
    } else {
        $self->error("E2081: No any conditions specified");
        return ();
    }

    if ($dbi->connect->err) {
        $self->error(sprintf("E2082: Can't get record(s): %s", $dbi->connect->errstr // ''));
    }

    return @ret;
}
sub grpusr_del {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;

    if ($data{id} && is_int($data{id})) { # By ID
        $dbi->execute(DML_GRPUSR_DEL_BY_ID, $data{id});
    } elsif ($data{groupname}) { # By Group
        $dbi->execute(DML_GRPUSR_DEL_BY_GROUP, $data{groupname});
    } elsif ($data{username}) { # By User
        $dbi->execute(DML_GRPUSR_DEL_BY_USER, $data{username});
    } else {
        $self->error("E2083: No any conditions specified");
        return 0;
    }
    if ($dbi->connect->err) {
        $self->error(sprintf("E2084: Can't delete record: %s", $dbi->connect->errstr // ''));
    }
    return $self->status;
}


sub meta_set {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;
    unless ($data{key}) {
        $self->error("E2090: No key specified");
        return 0;
    }

    # Get existed data
    my %pair = $self->meta_get($data{key});
    return 0 if $self->error;

    # Add
    if ($pair{key}) {
        # Set (update)
        $dbi->execute(DML_META_SET, $data{value}, $data{key});
    } else {
        # Add (insert)
        $dbi->execute(DML_META_ADD, $data{key}, $data{value});
    }
    if ($dbi->connect->err) {
        $self->error(sprintf("E2091: Can't insert or update record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}
sub meta_get {
    my $self = shift;
    my $key = shift // '';
    my $dbi = $self->dbi or return ();
    if (length $key) {
        my %rec = $dbi->recordh(DML_META_GET, $key);
        if ($dbi->connect->err) {
            $self->error(sprintf("E2092: Can't get record: %s", $dbi->connect->errstr // ''));
            return ();
        }
        return %rec;
    } else {
        my @tbl = $dbi->table(DML_META_GETALL);
        if ($dbi->connect->err) {
            $self->error(sprintf("E2093: Can't get table: %s", $dbi->connect->errstr // ''));
            return ();
        }
        my @ret;
        foreach my $arr (@tbl) {
            push @ret, {
                key     => $arr->[0],
                value   => $arr->[1],
            };
        }
        return @ret;
    }
}
sub meta_del {
    my $self = shift;
    my $key = shift // '';
    my $dbi = $self->dbi or return 0;
    unless (length($key)) {
        $self->error("E2094: No key specified");
        return 0;
    }

    $dbi->execute(DML_META_DEL, $key);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2095: Can't delete record: %s", $dbi->connect->errstr // ''));
    }
    return $self->status;
}


sub token_get {
    my $self = shift;
    my $id = shift // 0;
    my $dbi = $self->dbi or return ();
    unless ($id) {
        $self->error("E2100: No token's id specified");
        return ();
    }

    my %rec = $dbi->recordh(DML_TOKEN_GET, $id);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2101: Can't get record: %s", $dbi->connect->errstr // ''));
        return ();
    }
    return () unless $rec{id};

    return %rec;
}
sub token_get_cond {
    my $self = shift;
    my $cond = shift // '';
    my %data = @_;
    my $dbi = $self->dbi or return ();
    my %rec;

    # Username and ClientID
    if ($cond eq 'session') { # username and clinetid
        %rec = $dbi->recordh(DML_TOKEN_GET_BY_USERNAME_AND_CLIENTID, $data{username}, $data{clientid});
    } elsif ($cond eq 'api') { # username and jti
        %rec = $dbi->recordh(DML_TOKEN_GET_BY_USERNAME_AND_JTI, $data{username}, $data{jti});
    } else {
        $self->error("E2102: No any conditions specified");
        return ();
    }

    if ($dbi->connect->err) {
        $self->error(sprintf("E2103: Can't get record: %s", $dbi->connect->errstr // ''));
        return ();
    }
    return () unless $rec{id};

    return %rec;
}
sub token_getall {
    my $self = shift;
    my $dbi = $self->dbi or return ();

    # Get table
    my @tbl = $dbi->table(DML_TOKEN_GET_ALL);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2104: Can't get records: %s", $dbi->connect->errstr // ''));
        return ();
    }

    my @ret;
    foreach my $arr (@tbl) {
        push @ret, {
            id          => $arr->[0],
            jti         => $arr->[1],
            username    => $arr->[2],
            type        => $arr->[3],
            clientid    => $arr->[4],
            iat         => $arr->[5],
            exp         => $arr->[6],
            address     => $arr->[7],
        };
    }

    return @ret;
}
sub token_add {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;

    # Add
    $dbi->execute(DML_TOKEN_ADD,
        $data{jti}, $data{username}, $data{type}, $data{clientid},
        $data{iat}, $data{exp}, $data{address}
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("E2105: Can't insert new record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}
sub token_set {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;
    unless ($data{id}) {
        $self->error("E2106: No token's id specified");
        return 0;
    }

    # Set
    $dbi->execute(DML_TOKEN_SET,
        $data{jti}, $data{username}, $data{type}, $data{clientid},
        $data{iat}, $data{exp}, $data{address},
        $data{id}
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("E2107: Can't update record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}
sub token_del {
    my $self = shift;
    my $id = shift || 0;
    my $dbi = $self->dbi or return 0;

    # Delete all expired tokens
    unless ($id) {
        $dbi->execute(DML_TOKEN_DEL_EXPIRED, time);
        if ($dbi->connect->err) {
            $self->error(sprintf("E2108: Can't delete expired tokens: %s", $dbi->connect->errstr // ''));
        }
        return $self->status;
    }

    # Delete by ID
    $dbi->execute(DML_TOKEN_DEL, $id);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2109: Can't delete record: %s", $dbi->connect->errstr // ''));
    }
    return $self->status;
}


sub stat_get {
    my $self = shift;
    my $address = shift // '';
    my $username = shift // '';
    my $dbi = $self->dbi or return ();
    unless (length($address)) {
        $self->error("E2110: No address specified");
        return ();
    }
    unless (length($username)) {
        $self->error("E2111: No username specified");
        return ();
    }

    # Get data
    my %rec = $dbi->recordh(DML_STAT_GET, $address, $username);
    if ($dbi->connect->err) {
        $self->error(sprintf("E2112: Can't get record: %s", $dbi->connect->errstr // ''));
        return ();
    }

    return %rec;
}
sub stat_set {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->dbi or return 0;
    unless (defined($data{address}) && length($data{address})) {
        $self->error("E2113: No address specified");
        return 0;
    }
    unless (defined($data{username}) && length($data{username})) {
        $self->error("E2114: No username specified");
        return 0;
    }

    # Get data
    my %cur = $dbi->recordh(DML_STAT_GET, $data{address}, $data{username});
    if ($cur{id}) { # Update
        $dbi->execute(DML_STAT_SET,
            $data{address}, $data{username}, $data{dismiss} || 0, $data{updated} || time,
            $cur{id}
        );
    } else { # Insert
        $dbi->execute(DML_STAT_ADD,
            $data{address}, $data{username}, $data{dismiss} || 0, $data{updated} || time
        );
    }

    if ($dbi->connect->err) {
        $self->error(sprintf("E2115: Can't insert or update record: %s", $dbi->connect->errstr // ''));
    }

    return $self->status;
}


1;

__END__
