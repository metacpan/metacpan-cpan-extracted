#!/usr/bin/env perl
use strict;
use warnings;

## NOTE -- This test relies on you having specific data in your google account
# One group called "Test group", with at least one member

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

my @groups = $google->groups->search( { title => "Test group" } );
my $member = $groups[0]->member->[0];
die "No members in group 'Test group'" unless $member;

$member->photo->from_file('t/data/photo.jpg');
$member->photo->create_or_update();

##

@groups = $google->groups->search( { title => "Test group" } );
$member = $groups[0]->member->[0];
ok( $member->photo->exists, "Photo exists" );

done_testing;
