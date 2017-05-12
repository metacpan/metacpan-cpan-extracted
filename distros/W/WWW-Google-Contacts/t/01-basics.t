#!perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

use WWW::Google::Contacts;

my $google1 =
  WWW::Google::Contacts->new( username => 'foo', password => 'foo' );
my $google2 =
  WWW::Google::Contacts->new( username => 'bar', password => 'bar' );

my $contact1 = $google1->new_contact( { phone_number => '123456' } );
is( $contact1->server->username,
    'foo', 'Contact1 - Server username is correct' );
is( ref $contact1->phone_number,
    'ARRAY', 'Contact1 - phone_number is an array' );
is( scalar @{ $contact1->phone_number }, 1, '...with 1 entry' );
my $num = $contact1->phone_number->[0];
is( $num->value, '123456', '...with correct value' );

my $contact2 = $google2->new_contact( email => 'foo@bar.org' );
$contact2->full_name("Arne Weise");
$contact2->add_email('arne@weise.org');
is( $contact2->server->username,
    'bar', 'Contact2 - Server username is correct' );
is( $contact2->given_name,        'Arne',  'Contact2 - Given name is correct' );
is( ref $contact2->email,         'ARRAY', 'Contact2 - email is an array' );
is( scalar @{ $contact2->email }, 2,       '...with 2 entries' );
is( $contact2->email->[0]->value, 'foo@bar.org',    '...1 has correct value' );
is( $contact2->email->[1]->value, 'arne@weise.org', '...2 has correct value' );

my $contact3 = $google2->new_contact;
$contact3->full_name("Rutger Hauer");
is( $contact3->server->username,
    'bar', 'Contact3 - Server username is correct' );
is( $contact3->family_name, 'Hauer', 'Contact3 - Family name is correct' );

done_testing();
