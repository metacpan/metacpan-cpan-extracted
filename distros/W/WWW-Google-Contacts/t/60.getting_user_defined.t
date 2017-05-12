#!/usr/bin/env perl
use strict;
use warnings;

## NOTE -- This test relies on you having a couple of very specific users in your google account
# One user, name "Test user with 1 user def field", having 1 user defined field
# One user, name "Test user with 3 user def fields", having 3 user defined fields

use WWW::Google::Contacts;
use Test::More;
use Data::Dumper;

my $username = $ENV{TEST_GOOGLE_USERNAME};
my $password = $ENV{TEST_GOOGLE_PASSWORD};

plan skip_all =>
  'no TEST_GOOGLE_USERNAME or TEST_GOOGLE_PASSWORD set in the environment'
  unless $username and $password;

my $google = WWW::Google::Contacts->new(
    username => $username,
    password => $password,
    protocol => "https"
);
isa_ok( $google, 'WWW::Google::Contacts' );
my @contacts = ();

@contacts = $google->contacts->search(
    { full_name => "Test user with 1 user def field" } );
foreach my $c (@contacts) {
    is( scalar @{ $c->user_defined }, 1, "Got one user defined value" );
    my $user_def = shift @{ $c->user_defined };
    is( defined $user_def->key,   1, "..got key defined" );
    is( defined $user_def->value, 1, "..got value defined" );
}

@contacts = $google->contacts->search(
    { full_name => "Test user with 3 user def fields" } );
foreach my $c (@contacts) {
    is( scalar @{ $c->user_defined }, 3, "Got one three defined values" );
    foreach my $def_num ( 0, 1, 2 ) {
        my $user_def = $c->user_defined->[$def_num];
        is( defined $user_def->key,
            1, "User defined field [$def_num] got key defined" );
        is( defined $user_def->value, 1, "..and got value defined" );
    }
}

done_testing;
