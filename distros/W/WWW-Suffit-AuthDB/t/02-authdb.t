#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use Test::More;
use Cwd;
use File::Spec;

our $AUTHDB_WORKDIR = $ENV{AUTHDB_WORKDIR} || getcwd();

# Load module
use WWW::Suffit::AuthDB;

# Create instance
my $file = File::Spec->catfile($AUTHDB_WORKDIR, 'testauth.db');
my $file_out = File::Spec->catfile($AUTHDB_WORKDIR, 'testauth.json');
my $authdb = WWW::Suffit::AuthDB->with_roles('+CRUD')->new(
    ds          => qq{sqlite://$file?RaiseError=0&PrintError=0&sqlite_unicode=1},
    sourcefile  => "t/authdb-test.json",
    initialized => 1, # This is fake marker
);
#note explain $authdb;

# Delete existed test DB file first
unlink $file if -e $file;

# Dump data pool
is($authdb->dump, 'null', "Data pool is `null`") or diag explain $authdb->dump;

# Load source file to data pool
if (-e $authdb->sourcefile) {
    $authdb->load;
    ok(!$authdb->error, "Load test AuthDB source file") or diag $authdb->error;
    ok(ref($authdb->data) eq 'HASH', "Loaded data is hash");
    #note explain $authdb->data;
} else {
    note "Skipped loading test AuthDB source file: file not found";
}

# Save data pool to temp file
$authdb->save(File::Spec->catfile(getcwd(), 'testauth.json'));
ok(!$authdb->error, "Save test data to external file") or diag $authdb->error;

# Connect to database
$authdb->connect;
ok(!$authdb->error, "Connect to database") or diag $authdb->error;
#goto DONE;

# Forsed Initialize schema
$authdb->model->initialize;
ok(!$authdb->model->error, "Initialize schema") or diag $authdb->model->error;
ok($authdb->model->is_initialized, "Schema is initialized");

# Skip if no connect
unless ($authdb->model->ping) {
    fail sprintf(qq{Can't connect to database "%s"}, $authdb->model->dsn);
    diag $authdb->model->error;
    goto DONE;
}

# Checksum
subtest 'Checksum' => sub {
    my $test = 'The quick brown fox jumps over the lazy dog'; # Test pangram
    is $authdb->checksum($test => 'md5'), "9e107d9d372bb6826bd81d3542a419d6", "MD5";
    is $authdb->checksum($test => 'sha1'), "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12", "SHA1";
    is $authdb->checksum($test => 'sha224'), "730e109bd7a8a32b1cb9d9a09aa2325d2430587ddbc0c38bad911525", "SHA224";
    is $authdb->checksum($test => 'sha256'), "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592", "SHA256";
    is $authdb->checksum($test => 'sha384'), "ca737f1014a48f4c0b6dd43cb177b0afd9e5169367544c494011e3317dbf9a509cb1e5dc1e85a941bbee3d7f2afbc9b1", "SHA384";
    is $authdb->checksum($test => 'sha512'), "07e547d9586f6a73f73fbac0435ed76951218fb7d0c8d788a309d785436bbb642e93a252a954f23912547d1e8a3b5ed6e1bfd7097821233fa0538f3db854fee6", "SHA512";
};

# Meta test
subtest 'Meta CRUD' => sub {
    my $now = time;
    ok $authdb->meta("test.time" => $now), "The test key was created" or diag $authdb->error;
    is $authdb->meta("test.time"), $now, "The test value was readed" or diag $authdb->error;
    ok $authdb->meta("test.time" => undef), "The test key was deleted" or diag $authdb->error;
    is $authdb->meta("test.time"), undef, "The test value value is unset" or diag $authdb->error;
};

# User CRUD
subtest 'User CRUD' => sub {

    # Add new user
    ok($authdb->user_set(
        username    => "foo",
        name        => "Foo",
        email       => 'foo@localhost',
        password    => "test",
        algorithm   => "MD5",
        role        => "Test foo user",
        flags       => 0,
        public_key  => "",
        private_key => "",
        attributes  => qq/{"disabled": 0}/,
        comment     => "User for test only",
    ), "Add new user") or diag $authdb->error;

    # Edit the user data directly, without preprocessing
    ok($authdb->user_pset(
        username    => "foo",
        name        => "Foo",
        email       => 'foo@localhost',
        password    => "098f6bcd4621d373cade4e832627b4f6",
        algorithm   => "MD5",
        role        => "Test foo user",
        flags       => 0,
        public_key  => "",
        private_key => "",
        attributes  => qq/{"disabled": 0}/,
        comment     => "User for test only (edited)",
    ), "Edit the user data directly") or diag $authdb->error;

    # Change password
    ok($authdb->user_passwd(
        username => "foo",
        password => "password",
    ), "Change password") or diag $authdb->error;

    # Set keys pair
    ok($authdb->user_setkeys(
        username => "foo",
        public_key => 'public_key',
        private_key => 'private_key',
    ), "Set keys pair") or diag $authdb->error;

    # Get data
    my %data = $authdb->user_get("foo");
    ok(!$authdb->error, "Get user data") or diag $authdb->error;
    #note explain \%data;

    # Delete user
    ok($authdb->user_del( "foo" ), "Delete foo user") or diag $authdb->error;

};

# Group CRUD
subtest 'Group CRUD' => sub {

    # Add new group
    ok($authdb->group_set(
        groupname => "wheel",
        description => "Admin group",
    ), "Add new group") or diag $authdb->error;

    # Get data
    my %data = $authdb->group_get( "wheel" );
    ok(!$authdb->error, "Get group data") or diag $authdb->error;
    #note explain \%data;

    # Get members list
    my @members = $authdb->group_members( "wheel" );
    ok(!$authdb->error, "Get members list") or diag $authdb->error;

    # Delete group
    ok($authdb->group_del( "wheel" ), "Delete wheel group") or diag $authdb->error;

};

# Realm CRUD
subtest 'Realm CRUD' => sub {

    # Add new realm
    ok($authdb->realm_set(
        realmname => "default",
        realm => "Strict Zone",
        description => "Default realm",
    ), "Add new realm") or diag $authdb->error;

    # Get data
    my %data = $authdb->realm_get( "default" );
    ok(!$authdb->error, "Get realm data") or diag $authdb->error;
    #note explain \%data;

    # Delete default realm
    ok($authdb->realm_del( "default" ), "Delete default realm") or diag $authdb->error;

};

# Route CRUD
subtest 'Route CRUD' => sub {

    # Add new route
    ok($authdb->route_set(
        realmname   => "default",
        routename   => "root",
        method      => "GET",
        url         => "https://localhost:8695/",
        base        => "https://localhost:8695/",
        path        => "/",
    ), "Add new route") or diag $authdb->error;

    # Get data
    my %data = $authdb->route_get( "root" );
    ok(!$authdb->error, "Get route data") or diag $authdb->error;
    #note explain \%data;

    # Delete root route
    ok($authdb->route_del( "root" ), "Delete root route") or diag $authdb->error;

};

# Token CRUD
subtest 'Token CRUD' => sub {

    # Add new token
    ok($authdb->token_set(
        type        => 'api',
        jti         => 'none',
        username    => 'foo',
        clientid    => 'qwertyuiqwertyui',
        iat         => time,
        exp         => time + 3600,
        address     => '127.0.0.1',
    ), "Add new token") or diag $authdb->error;

    # Get tokens
    my @tokens = $authdb->token_get();
    ok(!$authdb->error, "Get tokens") or diag $authdb->error;
    #note explain \@tokens;

    # Delete token
    ok($authdb->token_del("foo", "none"), "Delete token") or diag $authdb->error;

};

# Import data from JSON file
ok $authdb->import_data, "Import data from JSON file" or diag $authdb->error;

# Export data to JSON file
ok $authdb->export_data($file_out), "Export data to JSON file" or diag $authdb->error;

# User
subtest 'User' => sub {

    # Alice
    my $alice = $authdb->user("alice", 'd1b919$c1');
    ok $alice->is_valid, "User is valid";
    is $alice->username, 'alice', "Username";
    #note explain $alice;

    # Unknown
    my $unknown = $authdb->user("unknown");
    ok !$unknown->is_valid, "Unknown user is invalid";

};

# Group
subtest 'Group' => sub {

    # Manager
    my $manager = $authdb->group("manager");
    ok $manager->is_valid, "Group is valid";
    is $manager->groupname, 'manager', "Groupname";
    #note explain $manager;

};

# Realm
subtest 'Realm' => sub {

    # Default realm
    my $default = $authdb->realm("Default");
    ok $default->is_valid, "Realm is valid";
    is $default->realmname, 'Default', "Realmname";
    #note explain $default;

};

# Routes
subtest 'Routes' => sub {

    # Routes
    my $routes = $authdb->routes("http://localhost");
    ok !$authdb->error, "Get routes";
    #note explain $routes;

};

# Cached user
subtest 'Cached user' => sub {

    # Alice
    my $alice = $authdb->user("alice", 'd1b919$c1');
    ok $alice->is_cached, "User is cached";
    #note explain $alice;

};

DONE: done_testing;

$authdb->model->disconnect;

__END__

AUTHDB_WORKDIR=/tmp prove -lv t/02-authdb.t
