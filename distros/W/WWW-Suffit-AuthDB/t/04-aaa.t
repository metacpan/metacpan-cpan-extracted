#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved
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
use Mojolicious::Controller;
use WWW::Suffit::AuthDB;

# Create instance
my $file = File::Spec->catfile($AUTHDB_WORKDIR, 'testauth.db');
my $authdb = WWW::Suffit::AuthDB->with_roles('+AAA')->new(
    ds => qq{sqlite://$file?RaiseError=0&PrintError=0&sqlite_unicode=1},
);
#note explain $authdb;

# Skip if no file
plan skip_all => "Please run previous tests in numeric order first" unless -e $file;

# Connect to database
$authdb->connect;
ok(!$authdb->error, "Connect to database") or diag $authdb->error;

# Skip if no connect
unless ($authdb->model->ping) {
    fail sprintf(qq{Can't connect to database "%s"}, $authdb->model->dsn);
    diag $authdb->model->error;
    goto DONE;
}

# Authentication
subtest 'Authentication' => sub {

    # Alice
    my $alice = $authdb->authn(u => "alice", p => "alice", a => "127.0.0.1");
    ok $alice, "Check password for alice (correct)" or diag $authdb->error;
    #note explain $alice;

    # Incorrect password
    ok !$authdb->authn(u => "test", p => "123"), "Incorrect password" and note $authdb->error;
    ok !$authdb->authn(u => "nobody", p => "alice"), "User not found" and note $authdb->error;

};

# Authorization
subtest 'Authentication' => sub {

    # Alice
    my $alice = $authdb->authz(u => "alice");
    ok $alice && $alice->is_authorized, "Authorized" or diag $authdb->error;

    # Anonymous (not authorized)
    my $user = $authdb->authz(u => "anon");
    ok !($user && $user->is_authorized), "Not authorized" and note $authdb->error;

};

# Access
subtest 'Access' => sub {

    # Access granted for Alice user
    ok($authdb->access(
        controller  => Mojolicious::Controller->new,
        username    => "alice",
        base        => "http://localhost",
        method      => "GET",
        url         => "http://localhost/foo/bar",
        path        => "/foo/bar",
        remote_ip   => "127.0.0.1",
        routename   => "root",
    ), "Access granted for Alice user") or diag $authdb->error;;

};

DONE: done_testing;

$authdb->model->disconnect;

__END__

AUTHDB_WORKDIR=/tmp prove -lv t/04-aaa.t
