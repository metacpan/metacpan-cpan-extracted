package WWW::Suffit::AuthDB::Model;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::AuthDB::Model - WWW::Suffit::AuthDB model class

=head1 SYNOPSIS

    use WWW::Suffit::AuthDB::Model;

    # SQLite
    my $model = WWW::Suffit::AuthDB::Model->new(
        "sqlite:///tmp/test.db?RaiseError=0&PrintError=0&sqlite_unicode=1"
    );

    # MySQL
    my $model = WWW::Suffit::AuthDB::Model->new(
        "mysql://user:pass@host/authdb?mysql_auto_reconnect=1&mysql_enable_utf8=1"
    );

    die($model->error) if $model->error;

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
        "address"       CAHR(40) DEFAULT NULL, -- IPv4/IPv6 client address
        "description"   TEXT DEFAULT NULL -- Description
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
        `description`   TEXT DEFAULT NULL, -- Description
        PRIMARY KEY (`id`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

=head1 METHODS

This class inherits all methods from L<Acrux::DBI> and implements the following new ones

=head2 new

    my $model = WWW::Suffit::AuthDB::Model->new(
        "sqlite:///tmp/test.db?sqlite_unicode=1"
    );

Create DBI object. See also L<Acrux::DBI>

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

=head2 initialize

    $model = $model->initialize;

This method initializes DB schema before start using

=head2 is_initialized

    print "Database is inialized" if $model->is_initialized;

This method checks of the schema initialization status

=head2 is_mariadb

    print $model->is_mariadb ? "Is MariaDB" : "Is NOT MariaDB"

Returns true if type of current database is MariaDB

=head2 is_mysql

    print $model->is_mysql ? "Is MySQL" : "Is NOT MySQL"

Returns true if type of current database is MySQL or MariaDB

=head2 is_oracle

    print $model->is_oracle ? "Is Oracle" : "Is NOT Oracle"

Returns true if type of current database is Oracle

=head2 is_postgresql

    print $model->is_postgresql ? "Is PostgreSQL" : "Is NOT PostgreSQL"

Returns true if type of current database is PostgreSQL

=head2 is_sqlite

    print $model->is_sqlite ? "Is SQLite" : "Is NOT SQLite"

Returns true if type of current database is SQLite

=head2 meta_del

    $model->meta_del("key") or die($model->error);
    $model->meta_set(key => "foo") or die($model->error);

Delete record by key

=head2 meta_get

    my %data = $model->meta_get("key");

Returns pair - key and value

    my @table = $model->meta_get();

Returns all data from meta table

=head2 meta_set

    $model->meta_set(key => "foo", value => "test") or die($model->error);

Set pair - key and value

    $model->meta_set(key => "foo") or die($model->error);

Delete record by key

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

=head2 route_add

    $model->route_add(
        realmname   => "root",
        routename   => "root",
        method      => "GET",
        url         => "https://localhost:8695/foo/bar",
        base        => "https://localhost:8695/",
        path        => "/foo/bar",
    ) or die($model->error);

Add the new route to realm

=head2 route_assign

    $model->route_add(
        realmname   => "default",
        routename   => "index",
    ) or die($model->error);

Assignees the realm for route by routename

=head2 route_del

    $model->route_del(123) or die($model->error);

Delete record by id

    $model->route_del("root") or die($model->error);

Delete record by realmname

=head2 route_get

    my %data = $model->route_get(123);

Returns data from database by id

    my @table = $model->route_get("root");

Returns data from database by realmname

=head2 route_getall

    my @table = $model->route_getall();

Returns pure data from database

=head2 route_release

    $model->route_release("default") or die($model->error);

Releases the route (removes relation with realm) by realmname

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
        base        => "https://localhost:8695/",
        path        => "/foo/bar",
    ) or die($model->error);

Update record by id

=head2 stat_get

    my %st = $model->stat_get($address, $username);

Returns the user statistic information by address and username

=head2 stat_set

    $model->stat_set(
        address     => $address,
        username    => $username,
        dismiss     => 1,
        updated     => time,
    ) or die($model->error);

Sets the user statistic information by address and username

=head2 token_add

    $model->token_add(
        type        => 'api',
        jti         => $jti,
        username    => $username,
        clientid    => 'qwertyuiqwertyui',
        iat         => time,
        exp         => time + 3600,
        address     => '127.0.0.1',
        description => "My API token",
    ) or die($model->error);

Add new token for user

=head2 token_del

    $model->token_del( 123 ) or die($model->error);

Delete token by id

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
        description => "My API token",
    ) or die($model->error);

Update token by id

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

Returns pure data from database (array of hashes)

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

L<WWW::Suffit::AuthDB>, L<Acrux::DBI>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use parent 'Acrux::DBI';

use Acrux::Util qw/ touch /;
use Acrux::RefUtil qw/ is_integer is_array_ref is_hash_ref isnt_void /;

our $VERSION = '1.01';

our $DEBUG //= !!$ENV{WWW_SUFFIT_AUTHDB_MODEL_DEBUG};

use constant {
    DEFAULT_ALGORITHM   => 'SHA256',
    SCHEMA_NAME         => 'authdb',
    SCHEMA_SECTION_FORMAT => 'schema_%s',
    SCHEMA_PATCHES => {
            # version   => label
            '0.01'      => 'initial', # Initial version
            '1.00'      => 'v100',
            '1.01'      => 'v101',
        },
};

# Meta DMLs
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

# Stat DMLs
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

# User DMLs
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

# Group DMLs
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

# Group-User DMLs
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

# Realm DMLs
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

# Route DMLs
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

# Requirement DMLs
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

# Token DMLs
use constant DML_TOKEN_GET => <<'DML';
SELECT `id`,`jti`,`username`,`type`,`clientid`,`iat`,`exp`,`address`,`description`
FROM `tokens`
WHERE `id` =?
DML
use constant DML_TOKEN_GET_BY_USERNAME_AND_CLIENTID => <<'DML';
SELECT `id`,`jti`,`username`,`type`,`clientid`,`iat`,`exp`,`address`,`description`
FROM `tokens`
WHERE `username` = ? AND `clientid` = ? AND `type` = "session"
DML
use constant DML_TOKEN_GET_BY_USERNAME_AND_JTI => <<'DML';
SELECT `id`,`jti`,`username`,`type`,`clientid`,`iat`,`exp`,`address`,`description`
FROM `tokens`
WHERE `username` = ? AND `jti` = ?
DML
use constant DML_TOKEN_ADD => <<'DML';
INSERT INTO `tokens` (`jti`,`username`,`type`,`clientid`,`iat`,`exp`,`address`,`description`)
VALUES (?,?,?,?,?,?,?,?)
DML
use constant DML_TOKEN_SET => <<'DML';
UPDATE `tokens`
SET `jti` = ?, `username` =?, `type` = ?, `clientid` = ?, `iat` = ?, `exp` = ?, `address` = ?, `description` = ?
WHERE `id` = ?
DML
use constant DML_TOKEN_GET_BY_USERNAME => <<DML;
SELECT `id`,`jti`,`username`,`type`,`clientid`,`iat`,`exp`,`address`,`description`
FROM `tokens`
WHERE `username` = ?
ORDER BY `iat` DESC
DML
use constant DML_TOKEN_GET_ALL => <<'DML';
SELECT `id`,`jti`,`username`,`type`,`clientid`,`iat`,`exp`,`address`,`description`
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

sub initialize {
    my $self = shift; # shift->connect_cached;
    my $schema = shift // SCHEMA_NAME;
    my $is_inited = 0; # Not inited
    my $dbh = $self->dbh;
    my $name = 'unknown';

    # Check DB handler
    return $self->error(sprintf("Can't connect to database \"%s\": %s",
        $self->dsn, $self->errstr || "unknown error")) unless $dbh;

    # Check SQLite
    if ($self->is_sqlite) {
        my $file = $dbh->sqlite_db_filename();
        unless ($file && (-e $file) && !(-z $file)) {
            touch($file);
            chmod(0666, $file);
        }

        # Get table info
        if (my $sth = $dbh->table_info(undef, undef, undef, 'TABLE')) {
            $is_inited = isnt_void($sth->fetchall_arrayref) ? 1 : 0;
        }

        # Set name
        $name = sprintf(SCHEMA_SECTION_FORMAT, 'sqlite');
    }

    # Check MariaDB
    elsif ($self->is_mariadb) {
        # Get table info
        if (my $sth = $dbh->table_info('', $schema, '', 'TABLE')) {
            $is_inited = isnt_void($sth->fetchall_arrayref) ? 1 : 0;
        }

        # Set name
        $name = sprintf(SCHEMA_SECTION_FORMAT, 'mysql');
    }

    # Check MySQL
    elsif ($self->is_mysql) {
        # Get table info
        if (my $sth = $dbh->table_info('', $schema, '', 'TABLE')) {
            $is_inited = isnt_void($sth->fetchall_arrayref) ? 1 : 0;
        }

        # Set name
        $name = sprintf(SCHEMA_SECTION_FORMAT, 'mysql');
    }

    # Check PostgreSQL
    elsif ($self->is_postgresql) {
        # Get table info
        if (my $sth = $dbh->table_info('', $schema, undef, 'TABLE')) { # schema = 'public'
            $is_inited = isnt_void($sth->fetchall_arrayref) ? 1 : 0;
        }

        # Set name
        $name = sprintf(SCHEMA_SECTION_FORMAT, 'postgresql');
    }

    # Skip initialize otherwise
    else {
        return $self;
    }

    # Get dump instance
    my $dump = $self->dump(name => $name)->from_data(__PACKAGE__);

    # Import initial schema if is not inited
    unless ($is_inited) {
        $dump->poke(); # main section (default)
        return $self if $self->error;
    }

    # Check connect
    return $self->error(sprintf("Can't init database \"%s\". Ping failed: %s",
        $self->dsn, $self->errstr() || "unknown error")) unless $self->ping;

    # Import patches
    my %ver = $self->meta_get("schema.version");
    return $self if $self->error;
    my $patches = $self->_get_patches( $ver{value} || '0.00' ) || [];
    foreach my $p (@$patches) {
        #print "# $p\n";
        $dump->poke($p);
        return $self if $self->error;
    }

    return $self;
}
sub is_initialized {
    my $self = shift;
    my $ver = shift // $VERSION;
    my %vd = $self->meta_get("schema.version");
    return 0 if $self->error;
    my $v = $vd{value} || '0.00';
    return 1 if ($v * 1) >= ($ver * 1);
    return 0;
}

sub is_sqlite {
    my $self = shift;
    my $dr = $self->driver;
    return ($dr eq 'sqlite' or $dr eq 'file') ? 1 : 0;
}
sub is_mysql {
    my $self = shift;
    my $dr = $self->driver;
    return ($dr eq 'mysql' or $dr eq 'mariadb' or $dr eq 'maria') ? 1 : 0;
}
sub is_mariadb {
    my $self = shift;
    my $dr = $self->driver;
    return ($dr eq 'maria' or $dr eq 'mariadb') ? 1 : 0;
}
sub is_postgresql {
    my $self = shift;
    my $dr = $self->driver;
    return ($dr eq 'pg' or $dr eq 'pgsql' or $dr eq 'postgres' or $dr eq 'postgresql') ? 1 : 0;
}
sub is_oracle {
    my $self = shift;
    my $dr = $self->driver;
    return ($dr eq 'oracle') ? 1 : 0;
}

# Meta CRUDs
sub meta_set {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;
    unless ($data{key}) {
        $self->error("No key specified");
        return 0;
    }

    # Get existed data
    my %pair = $self->meta_get($data{key});
    return 0 if $self->error;

    # Add/Update/Delete
    if ($pair{key}) {
        if (exists $data{value}) {
            # Set (update)
            $self->query(DML_META_SET, $data{value}, $data{key}) or return 0;
        } else {
            # Delete
            $self->query(DML_META_DEL, $data{key}) or return 0;
        }
    } else {
        # Add (insert)
        $self->query(DML_META_ADD, $data{key}, $data{value}) or return 0;
    }

    # Ok
    return 1;
}
sub meta_get {
    my $self = shift;
    my $key = shift // '';
    return () unless $self->ping;

    if (length $key) {
        if (my $res = $self->query(DML_META_GET, $key)) {
            my $r = $res->hash;
            return (%$r) if is_hash_ref($r);
        }
    } else {
        if (my $res = $self->query(DML_META_GETALL)) {
            my $r = $res->hashes;
            return (@$r) if is_array_ref($r);
        }
    }

    return ();
}
sub meta_del { shift->meta_set(key => shift // '') }

# Stat CRUDs
sub stat_set {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;
    unless (defined($data{address}) && length($data{address})) {
        $self->error("No address specified");
        return 0;
    }
    unless (defined($data{username}) && length($data{username})) {
        $self->error("No username specified");
        return 0;
    }

    # Get existed data
    my %cur = $self->stat_get($data{address}, $data{username});
    return 0 if $self->error;

    # Add/Update
    if ($cur{id}) {
        # Set (update)
        $self->query(DML_STAT_SET, $data{address}, $data{username},
            $data{dismiss} || 0, $data{updated} || time, $cur{id}
        ) or return 0;
    } else {
        # Add (insert)
        $self->query(DML_STAT_ADD, $data{address}, $data{username},
            $data{dismiss} || 0, $data{updated} || time
        ) or return 0;
    }

    # Ok
    return 1;
}
sub stat_get {
    my $self = shift;
    my $address = shift // '';
    my $username = shift // '';
    return () unless $self->ping;

    unless (length($address)) {
        $self->error("No address specified");
        return ();
    }
    unless (length($username)) {
        $self->error("No username specified");
        return ();
    }

    # Get data
    if (my $res = $self->query(DML_STAT_GET, $address, $username)) {
        my $r = $res->hash;
        return (%$r) if is_hash_ref($r);
    }

    return ();
}

# User CRUDs
sub user_add {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;

    # Add
    $self->query(DML_USER_ADD,
        $data{username}, $data{name}, $data{email}, $data{password},
        uc($data{algorithm} || DEFAULT_ALGORITHM), $data{role}, $data{flags},
        $data{created} || time(), $data{not_before} || time(), $data{not_after},
        $data{public_key}, $data{private_key}, $data{attributes},
        $data{comment},
    ) or return 0;

    # Ok
    return 1;
}
sub user_set { # set by username
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;
    unless (length($data{username} // '')) {
        $self->error("No username specified");
        return 0;
    }

    # Set
    $self->query(DML_USER_SET,
        $data{name}, $data{email}, $data{password},
        uc($data{algorithm} || DEFAULT_ALGORITHM), $data{role}, $data{flags},
        $data{not_before} || time(), $data{not_after},
        $data{public_key}, $data{private_key}, $data{attributes},
        $data{comment},
        $data{username},
    ) or return 0;

    # Ok
    return 1;
}
sub user_edit { # set by id
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;
    unless ($data{id}) {
        $self->error("No id of user specified");
        return 0;
    }

    # Set
    $self->query(DML_USER_EDIT,
        $data{name}, $data{email}, $data{role}, $data{comment},
        $data{id},
    ) or return 0;

    # Ok
    return 1;
}
sub user_del {
    my $self = shift;
    my $username = shift // '';
    return 0 unless $self->ping;
    unless (length($username)) {
        $self->error("No username specified");
        return 0;
    }

    # Del
    $self->query(DML_USER_DEL, $username) or return 0;

    # Ok
    return 1;
}
sub user_get {
    my $self = shift;
    my $username = shift // '';
    return () unless $self->ping;
    unless (length $username) {
        $self->error("No username specified");
        return ();
    }

    # Get data
    if (my $res = $self->query(DML_USER_GET, $username)) {
        my $r = $res->hash;
        return (%$r) if is_hash_ref($r);
    }

    return ();
}
sub user_getall {
    my $self = shift;
    return () unless $self->ping;

    # Get data
    if (my $res = $self->query(DML_USER_GETALL)) {
        my $r = $res->hashes;
        return (@$r) if is_array_ref($r);
    }

    return ();
}
sub user_search {
    my $self = shift;
    my $_search = shift // '';
    return () unless $self->ping;

    # Safe search string
    my $search = $self->dbh->quote(sprintf("%%%s%%", $_search));
    my @where;
    push @where, "AND UPPER(`username`) LIKE UPPER($search)" if $_search;

    # Get data
    if (my $res = $self->query(sprintf(DML_USER_SEARCH, join("\n", @where)))) {
        my $r = $res->hashes;
        return (@$r) if is_array_ref($r);
    }

    return ();
}
sub user_groups {
    my $self = shift;
    my $username = shift // '';
    return () unless $self->ping;
    unless (length $username) {
        $self->error("No username specified");
        return ();
    }

    # Get data
    if (my $res = $self->query(DML_USER_GROUPS, $username)) {
        my $r = $res->hashes;
        return (@$r) if is_array_ref($r);
    }

    return ();
}
sub user_tokens {
    my $self = shift;
    my $username = shift // '';
    return () unless $self->ping;
    unless (length $username) {
        $self->error("No username specified");
        return ();
    }

    # Get data
    if (my $res = $self->query(DML_TOKEN_GET_BY_USERNAME, $username)) {
        my $r = $res->hashes;
        return (@$r) if is_array_ref($r);
    }

    return ();
}
sub user_passwd {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;
    unless (length($data{username} // '')) {
        $self->error("No username specified");
        return 0;
    }

    # Passwd
    $self->query(DML_PASSWD, $data{password}, $data{username}) or return 0;

    # Ok
    return 1;
}
sub user_setkeys {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;
    unless ($data{id}) {
        $self->error("No id of user specified");
        return 0;
    }

    # Set
    $self->query(DML_USER_SETKEYS, $data{public_key}, $data{private_key}, $data{id}) or return 0;

    # Ok
    return 1;
}

# Group CRUDs
sub group_add {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;

    # Add
    $self->query(DML_GROUP_ADD, $data{groupname}, $data{description}) or return 0;

    # Ok
    return 1;
}
sub group_set {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;
    unless (length($data{groupname} // '')) {
        $self->error("No groupname specified");
        return 0;
    }

    # Set
    $self->query(DML_GROUP_SET, $data{description}, $data{groupname}) or return 0;

    # Ok
    return 1;
}
sub group_del {
    my $self = shift;
    my $groupname = shift // '';
    return 0 unless $self->ping;
    unless (length($groupname)) {
        $self->error("No groupname specified");
        return 0;
    }

    # Del
    $self->query(DML_GROUP_DEL, $groupname) or return 0;

    # Ok
    return 1;
}
sub group_get {
    my $self = shift;
    my $groupname = shift // '';
    return () unless $self->ping;
    unless (length $groupname) {
        $self->error("No groupname specified");
        return ();
    }

    # Get data
    if (my $res = $self->query(DML_GROUP_GET, $groupname)) {
        my $r = $res->hash;
        return (%$r) if is_hash_ref($r);
    }

    return ();
}
sub group_getall {
    my $self = shift;
    return () unless $self->ping;

    # Get data
    if (my $res = $self->query(DML_GROUP_GETALL)) {
        my $r = $res->hashes;
        return (@$r) if is_array_ref($r);
    }

    return ();
}
sub group_members {
    my $self = shift;
    my $groupname = shift // '';
    return () unless $self->ping;
    unless (length $groupname) {
        $self->error("No groupname specified");
        return ();
    }

    # Get data
    if (my $res = $self->query(DML_GROUP_MEMBERS, $groupname)) {
        my $r = $res->hashes;
        return (@$r) if is_array_ref($r);
    }

    return ();
}

# GrpUsr CRUDs
sub grpusr_add {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;

    # Add
    $self->query(DML_GRPUSR_ADD, $data{groupname}, $data{username}) or return 0;

    # Ok
    return 1;
}
sub grpusr_del {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;

    # Del
    if ($data{id} && is_integer($data{id})) { # By ID
        $self->query(DML_GRPUSR_DEL_BY_ID, $data{id}) or return 0;
    } elsif ($data{groupname}) { # By Group
        $self->query(DML_GRPUSR_DEL_BY_GROUP, $data{groupname}) or return 0;
    } elsif ($data{username}) { # By User
        $self->query(DML_GRPUSR_DEL_BY_USER, $data{username}) or return 0;
    } else {
        $self->error("No any conditions specified");
        return 0;
    }

    # Ok
    return 1;
}
sub grpusr_get {
    my $self = shift;
    my %data = @_;
    return () unless $self->ping;

    # Get data
    if ($data{id} && is_integer($data{id})) { # By ID
        if (my $res = $self->query(DML_GRPUSR_GET_BY_ID, $data{id})) {
            my $r = $res->hash;
            return (%$r) if is_hash_ref($r);
        }
    } elsif ($data{groupname} and $data{username}) { # By Group and User
        if (my $res = $self->query(DML_GRPUSR_GET_BY_GROUP_USER, $data{groupname}, $data{username})) {
            my $r = $res->hash;
            return (%$r) if is_hash_ref($r);
        }
    } elsif ($data{groupname}) { # By Group
        if (my $res = $self->query(DML_GRPUSR_GET_BY_GROUP, $data{groupname})) {
            my $r = $res->hashes;
            return (@$r) if is_array_ref($r);
        }
    } elsif ($data{username}) { # By User
        if (my $res = $self->query(DML_GRPUSR_GET_BY_USER, $data{username})) {
            my $r = $res->hashes;
            return (@$r) if is_array_ref($r);
        }
    } else {
        $self->error("No any conditions specified");
    }

    return ();
}

# Realm CRUDs
sub realm_add {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;

    # Add
    $self->query(DML_REALM_ADD,
        $data{realmname}, $data{realm}, $data{satisfy}, $data{description}
    ) or return 0;

    # Ok
    return 1;
}
sub realm_set {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;
    unless (length($data{realmname} // '')) {
        $self->error("No realmname specified");
        return 0;
    }

    # Set
    $self->query(DML_REALM_SET,
        $data{realm}, $data{satisfy}, $data{description}, $data{realmname}
    ) or return 0;

    # Ok
    return 1;
}
sub realm_del {
    my $self = shift;
    my $realmname = shift // '';
    return 0 unless $self->ping;
    unless (length($realmname)) {
        $self->error("No realmname specified");
        return 0;
    }

    # Del
    $self->query(DML_REALM_DEL, $realmname) or return 0;

    # Ok
    return 1;
}
sub realm_get {
    my $self = shift;
    my $realmname = shift // '';
    return () unless $self->ping;
    unless (length $realmname) {
        $self->error("No realmname specified");
        return ();
    }

    # Get data
    if (my $res = $self->query(DML_REALM_GET, $realmname)) {
        my $r = $res->hash;
        return (%$r) if is_hash_ref($r);
    }

    return ();
}
sub realm_getall {
    my $self = shift;
    return () unless $self->ping;

    # Get data
    if (my $res = $self->query(DML_REALM_GETALL)) {
        my $r = $res->hashes;
        return (@$r) if is_array_ref($r);
    }

    return ();
}
sub realm_requirement_add {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;

    # Add
    $self->query(DML_REQUIREMENT_ADD,
        $data{realmname}, $data{provider}, $data{entity}, $data{op}, $data{value}
    ) or return 0;

    # Ok
    return 1;
}
sub realm_requirement_del {
    my $self = shift;
    my $realmname = shift // '';
    return 0 unless $self->ping;
    unless (length($realmname)) {
        $self->error("No realmname specified");
        return 0;
    }

    # Del
    $self->query(DML_REQUIREMENT_DEL_BY_REALM, $realmname) or return 0;

    # Ok
    return 1;
}
sub realm_requirements {
    my $self = shift;
    my $realmname = shift;
    return () unless $self->ping;
    unless ($realmname) {
        $self->error("No realmname specified");
        return ();
    }

    # Get data
    if (my $res = $self->query(DML_REQUIREMENT_GET_BY_REALM, $realmname)) {
        my $r = $res->hashes;
        return (@$r) if is_array_ref($r);
    }

    return ();
}
sub realm_routes {
    my $self = shift;
    my $realmname = shift;
    return () unless $self->ping;
    unless ($realmname) {
        $self->error("No realmname specified");
        return ();
    }

    # Get data
    if (my $res = $self->query(DML_ROUTE_GET_BY_REALM, $realmname)) {
        my $r = $res->hashes;
        return (@$r) if is_array_ref($r);
    }

    return ();
}

# Route CRUDs
sub route_add {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;

    # Add
    $self->query(DML_ROUTE_ADD,
        $data{realmname}, $data{routename}, $data{method},
        $data{url}, $data{base}, $data{path}
    ) or return 0;

    # Ok
    return 1;
}
sub route_set {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;
    unless ($data{id}) {
        $self->error("No route id specified");
        return 0;
    }

    # Set
    $self->query(DML_ROUTE_SET,
        $data{realmname}, $data{method},
        $data{url}, $data{base}, $data{path},
        $data{routename}
    ) or return 0;

    # Ok
    return 1;
}
sub route_del {
    my $self = shift;
    my $routename = shift // '';
    return 0 unless $self->ping;
    unless (length($routename)) {
        $self->error("No routename specified");
        return 0;
    }

    # Del
    $self->query(DML_ROUTE_DEL_BY_ROUTE, $routename) or return 0;

    # Ok
    return 1;
}
sub route_get {
    my $self = shift;
    my $routename = shift // '';
    return () unless $self->ping;
    unless ($routename) {
        $self->error("No routename specified");
        return ();
    }

    # Get data
    if (my $res = $self->query(DML_ROUTE_GET_BY_ROUTE, $routename)) {
        my $r = $res->hash;
        return (%$r) if is_hash_ref($r);
    }

    return ();
}
sub route_getall {
    my $self = shift;
    return () unless $self->ping;

    # Get data
    if (my $res = $self->query(DML_ROUTE_GETALL)) {
        my $r = $res->hashes;
        return (@$r) if is_array_ref($r);
    }

    return ();
}
sub route_search {
    my $self = shift;
    my $_search = shift // '';
    return () unless $self->ping;

    # Safe search string
    my $search = $self->dbh->quote(sprintf("%%%s%%", $_search));
    my @where;
    push @where, "AND UPPER(`routename`) LIKE UPPER($search)" if $_search;

    # Get data
    if (my $res = $self->query(sprintf(DML_ROUTE_SEARCH, join("\n", @where)))) {
        my $r = $res->hashes;
        return (@$r) if is_array_ref($r);
    }

    return ();
}
sub route_release {
    my $self = shift;
    my $realmname = shift // '';
    return 0 unless $self->ping;
    unless (length($realmname)) {
        $self->error("No realmname specified");
        return 0;
    }

    # Set
    $self->query(DML_ROUTE_RELEASE_BY_REALM, $realmname) or return 0;

    # Ok
    return 1;
}
sub route_assign {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;
    unless (defined($data{realmname}) && length($data{realmname})) {
        $self->error("No realmname specified");
        return 0;
    }
    unless (defined($data{routename}) && length($data{routename})) {
        $self->error("No routename specified");
        return 0;
    }

    # Set
    $self->query(DML_ROUTE_ASSIGN_BY_ROUTE, $data{realmname}, $data{routename}) or return 0;

    # Ok
    return 1;
}

# Token CRUDs
sub token_add {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;

    # Add
    $self->query(DML_TOKEN_ADD,
        $data{jti}, $data{username}, $data{type}, $data{clientid},
        $data{iat}, $data{exp}, $data{address}, $data{description}
    ) or return 0;

    # Ok
    return 1;
}
sub token_set {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;
    unless ($data{id}) {
        $self->error("No token id specified");
        return 0;
    }

    # Set
    $self->query(DML_TOKEN_SET,
        $data{jti}, $data{username}, $data{type}, $data{clientid},
        $data{iat}, $data{exp}, $data{address}, $data{description},
        $data{id}
    ) or return 0;

    # Ok
    return 1;
}
sub token_del {
    my $self = shift;
    my $id = shift || 0;
    return 0 unless $self->ping;

    # Del
    if ($id) {
        # Delete by ID
        $self->query(DML_TOKEN_DEL, $id) or return 0;
    } else {
        # Delete all expired tokens
        $self->query(DML_TOKEN_DEL_EXPIRED, time) or return 0;
    }

    # Ok
    return 1;
}
sub token_get {
    my $self = shift;
    my $id = shift // 0;
    return () unless $self->ping;
    unless ($id && is_integer($id)) {
        $self->error("No token id specified");
        return ();
    }

    # Get data
    if (my $res = $self->query(DML_TOKEN_GET, $id)) {
        my $r = $res->hash;
        return (%$r) if is_hash_ref($r);
    }

    return ();
}
sub token_getall {
    my $self = shift;
    return () unless $self->ping;

    # Get data
    if (my $res = $self->query(DML_TOKEN_GET_ALL)) {
        my $r = $res->hashes;
        return (@$r) if is_array_ref($r);
    }

    return ();
}
sub token_get_cond {
    my $self = shift;
    my $cond = shift // '';
    my %data = @_;
    return () unless $self->ping;

    my $res;

    # Username and ClientID
    if ($cond eq 'session') { # username and clinetid
        $res = $self->query(DML_TOKEN_GET_BY_USERNAME_AND_CLIENTID, $data{username}, $data{clientid});
    } elsif ($cond eq 'api') { # username and jti
        $res = $self->query(DML_TOKEN_GET_BY_USERNAME_AND_JTI, $data{username}, $data{jti});
    } else {
        $self->error("No any conditions specified");
        return ();
    }

    # Result
    if ($res) {
        my $r = $res->hash;
        return (%$r) if is_hash_ref($r);
    }

    return ();
}

sub _get_patches {
    my $self = shift;
    my $from = shift // $VERSION; # start from version
    my $patches = SCHEMA_PATCHES;
    my @labels = ();
    foreach my $v (sort keys %$patches) {
        push @labels, $patches->{$v} if ($v * 1) > ($from * 1);
    }
    return [@labels];
}

1;

# !! Not forget add any new patch label to SCHEMA_PATCHES !!

__DATA__

@@ schema_sqlite

-- # main
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
) ;
CREATE TABLE IF NOT EXISTS "groups" (
    "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    "groupname"     CHAR(64) NOT NULL UNIQUE, -- Group name
    "description"   TEXT DEFAULT NULL -- Description
) ;
CREATE TABLE IF NOT EXISTS "realms" (
    "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    "realmname"     CHAR(64) NOT NULL UNIQUE, -- Realm name
    "realm"         CHAR(255) DEFAULT NULL, -- Realm string
    "satisfy"       CHAR(16) DEFAULT NULL, -- The satisfy policy (All, Any)
    "description"   TEXT DEFAULT NULL -- Description
) ;
CREATE TABLE IF NOT EXISTS "requirements" (
    "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    "realmname"     CHAR(64) DEFAULT NULL, -- Realm name
    "provider"      CHAR(64) DEFAULT NULL, -- Provider name (user,group,ip and etc.)
    "entity"        CHAR(64) DEFAULT NULL, -- Entity (operand of expression)
    "op"            CHAR(2) DEFAULT NULL, -- Comparison Operator
    "value"         CHAR(255) DEFAULT NULL -- Test value
) ;
CREATE TABLE IF NOT EXISTS "routes" (
    "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    "realmname"     CHAR(64) DEFAULT NULL, -- Realm name
    "routename"     CHAR(64) DEFAULT NULL, -- Route name
    "method"        CHAR(16) DEFAULT NULL, -- HTTP method (ANY, GET, POST, ...)
    "url"           CHAR(255) DEFAULT NULL, -- URL
    "base"          CHAR(255) DEFAULT NULL, -- Base URL
    "path"          CHAR(255) DEFAULT NULL -- Path of URL (pattern)
) ;
CREATE TABLE IF NOT EXISTS "grpsusrs" (
    "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    "groupname"     CHAR(64) DEFAULT NULL, -- Group name
    "username"      CHAR(64) DEFAULT NULL -- User name
) ;
CREATE TABLE IF NOT EXISTS "stats" (
    "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    "address"       CHAR(40) DEFAULT NULL, -- IPv4/IPv6 client address
    "username"      CHAR(64) DEFAULT NULL, -- User name
    "dismiss"       INTEGER DEFAULT 0, -- Dismissal count
    "updated"       INTEGER DEFAULT NULL -- Update date
) ;
CREATE TABLE IF NOT EXISTS "tokens" (
    "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    "jti"           CHAR(32) DEFAULT NULL, -- Request ID
    "username"      CHAR(64) DEFAULT NULL, -- User name
    "type"          CHAR(20) DEFAULT NULL, -- Token type (session, refresh, api)
    "clientid"      CHAR(32) DEFAULT NULL, -- Clientid as md5 (User-Agent . Remote-Address)
    "iat"           INTEGER DEFAULT NULL, -- Issue time
    "exp"           INTEGER DEFAULT NULL, -- Expiration time
    "address"       CHAR(40) DEFAULT NULL -- IPv4/IPv6 client address
) ;
CREATE TABLE IF NOT EXISTS "meta" (
    "key"           CHAR(255) NOT NULL UNIQUE PRIMARY KEY,
    "value"         TEXT DEFAULT NULL
)

-- # initial
INSERT INTO `meta` (`key`,`value`) VALUES ("schema.version", "0.01")

-- # v101
ALTER TABLE "tokens" ADD COLUMN "description" TEXT DEFAULT NULL;
UPDATE `meta` SET `value` = "1.01" WHERE `key` = "schema.version"


@@ schema_mysql

-- # main
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
CREATE TABLE IF NOT EXISTS `meta` (
    `key`           VARCHAR(255) NOT NULL,
    `value`         TEXT DEFAULT NULL,
    PRIMARY KEY (`key`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

-- # initial
INSERT INTO `meta` (`key`,`value`) VALUES ("schema.version", "0.01")

-- # v101
ALTER TABLE `tokens` ADD COLUMN `description` TEXT DEFAULT NULL;
UPDATE `meta` SET `value` = "1.01" WHERE `key` = "schema.version"

@@ schema_postgresql

-- # main
CREATE TABLE IF NOT EXISTS users (
    id            INT NOT NULL GENERATED ALWAYS AS IDENTITY,
    username      VARCHAR(64) NOT NULL, -- User name
    name          VARCHAR(255) DEFAULT NULL, -- Full user name
    email         VARCHAR(255) DEFAULT NULL, -- Email address
    password      VARCHAR(255) NOT NULL, -- Password hash
    algorithm     VARCHAR(64) DEFAULT NULL, -- Password hash Algorithm (SHA256)
    role          VARCHAR(255) DEFAULT NULL, -- Role name
    flags         INT DEFAULT 0, -- Flags
    created       INT DEFAULT NULL, -- Created at
    not_before    INT DEFAULT NULL, -- Not Before
    not_after     INT DEFAULT NULL, -- Not After
    public_key    TEXT DEFAULT NULL, -- Public Key (RSA/X509)
    private_key   TEXT DEFAULT NULL, -- Private Key (RSA/X509)
    attributes    TEXT DEFAULT NULL, -- Attributes (JSON)
    comment       TEXT DEFAULT NULL, -- Comment
    PRIMARY KEY (id),
    CONSTRAINT username UNIQUE (username)
) ;
CREATE TABLE IF NOT EXISTS groups (
    id            INT NOT NULL GENERATED ALWAYS AS IDENTITY,
    groupname     VARCHAR(64) NOT NULL, -- Group name
    description   TEXT DEFAULT NULL, -- Description
    PRIMARY KEY (id),
    CONSTRAINT groupname UNIQUE (groupname)
) ;
CREATE TABLE IF NOT EXISTS realms (
    id            INT NOT NULL GENERATED ALWAYS AS IDENTITY,
    realmname     VARCHAR(64) NOT NULL, -- Realm name
    realm         VARCHAR(255) DEFAULT NULL, -- Realm string
    satisfy       VARCHAR(16) DEFAULT NULL, -- The satisfy policy (All, Any)
    description   TEXT DEFAULT NULL, -- Description
    PRIMARY KEY (id),
    CONSTRAINT realmname UNIQUE (realmname)
) ;
CREATE TABLE IF NOT EXISTS routes (
    id            INT NOT NULL GENERATED ALWAYS AS IDENTITY,
    realmname     VARCHAR(64) DEFAULT NULL, -- Realm name
    routename     VARCHAR(64) DEFAULT NULL, -- Route name
    method        VARCHAR(16) DEFAULT NULL, -- HTTP method (ANY, GET, POST, ...)
    url           VARCHAR(255) DEFAULT NULL, -- URL
    base          VARCHAR(255) DEFAULT NULL, -- Base URL
    path          VARCHAR(255) DEFAULT NULL, -- Path of URL (pattern)
    PRIMARY KEY (id)
) ;
CREATE TABLE IF NOT EXISTS requirements (
    id            INT NOT NULL GENERATED ALWAYS AS IDENTITY,
    realmname     VARCHAR(64) DEFAULT NULL, -- Realm name
    provider      VARCHAR(64) DEFAULT NULL, -- Provider name (user,group,ip and etc.)
    entity        VARCHAR(64) DEFAULT NULL, -- Entity (operand of expression)
    op            VARCHAR(2) DEFAULT NULL, -- Comparison Operator
    value         VARCHAR(255) DEFAULT NULL, -- Test value
    PRIMARY KEY (id)
) ;
CREATE TABLE IF NOT EXISTS grpsusrs (
    id            INT NOT NULL GENERATED ALWAYS AS IDENTITY,
    groupname     VARCHAR(64) DEFAULT NULL, -- Group name
    username      VARCHAR(64) DEFAULT NULL, -- User name
    PRIMARY KEY (id)
) ;
CREATE TABLE IF NOT EXISTS stats (
    id            INT NOT NULL GENERATED ALWAYS AS IDENTITY,
    address       VARCHAR(40) DEFAULT NULL, -- IPv4/IPv6 client address
    username      VARCHAR(64) DEFAULT NULL, -- User name
    dismiss       INT DEFAULT 0, -- Dismissal count
    updated       INT DEFAULT NULL, -- Update date
    PRIMARY KEY (id)
) ;
CREATE TABLE IF NOT EXISTS tokens (
    id            INT NOT NULL GENERATED ALWAYS AS IDENTITY,
    jti           VARCHAR(32) DEFAULT NULL, -- Request ID
    username      VARCHAR(64) DEFAULT NULL, -- User name
    type          VARCHAR(20) DEFAULT NULL, -- Token type (session, refresh, api)
    clientid      VARCHAR(32) DEFAULT NULL, -- Clientid as md5 (User-Agent . Remote-Address)
    iat           INT DEFAULT NULL, -- Issue time
    exp           INT DEFAULT NULL, -- Expiration time
    address       VARCHAR(40) DEFAULT NULL, -- IPv4/IPv6 client address
    description   TEXT DEFAULT NULL, -- Description
    PRIMARY KEY (id)
) ;
CREATE TABLE IF NOT EXISTS meta (
    key           VARCHAR(255) NOT NULL,
    value         TEXT DEFAULT NULL,
    PRIMARY KEY (key)
) ;

-- # initial
INSERT INTO meta (key,value) VALUES ("schema.version", "0.01")

-- # v101
UPDATE meta SET value = "1.01" WHERE key = "schema.version"
