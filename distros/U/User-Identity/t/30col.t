#!/usr/bin/perl
use warnings;
use strict;

# Test User::Identity::Collection

use lib qw/. ../;
use Test::More tests => 44;

BEGIN {
   use_ok('User::Identity::Collection::Locations');
   use_ok('User::Identity');
}

my $ui   = 'User::Identity';
my $uil  = 'User::Identity::Location';
my $uic  = 'User::Identity::Collection';
my $uicl = 'User::Identity::Collection::Locations';

sub same_obj($$$)
{  my ($l, $r, $msg) = @_;
   is("$l", "$r", $msg);
}

#
# We need a user to test with
#

my $user = $ui->new('markov'
 , firstname => 'Mark', surname => 'Overmeer'
 , titles => 'drs.',    initials => 'M.A.C.J.'
 , language => 'nl-NL', charset => 'iso-8859-15'
 );

ok(defined $user,                              "Created a user");

#
# Now an location
#

my $loc = $uil->new
 ( 'home'
 , street       => 'Pad 12'
 , postal_code  => '66341 XA'
 , city         => 'Arnhem'
 , country      => 'Nederland'
 , country_code => 'nl'
 , phone        => '+18-12-2344556'
 , fax          => '+11-11-2344556'
 );

ok(defined $loc,                              "Created a location");
ok(!defined $loc->user,                       "User-less location");

#
# Now a location collection
#

my $col = $uicl->new;
ok(defined $col,                              "Created a location collection");
isa_ok($col, $uic,                            "Is a collection");
isa_ok($col, $uicl,                           "Correct collection");

cmp_ok($col->roles, '==', 0,                  "No roles yet");
cmp_ok(scalar @$col, '==', 0,                 "No overloaded roles yet");

ok(! defined $loc->parent,                    "Role has no parent yet");
same_obj($loc, $col->addRole($loc),           "Add prepared role");
cmp_ok($col->roles, '==', 1,                  "First role in collection");
same_obj($loc->parent, $col,                  "Role's parent is collection");
cmp_ok(scalar @$col, '==', 1,                 "One overloaded role");
same_obj($col->[0], $loc,                     "The role is there");
is("$col", "locations: home");

ok(!defined $loc->user,                       "User-less location");
same_obj($user->addCollection($col), $col,    "Adding collection to a user");
same_obj($col->user, $user,                   "User of collection");
same_obj($col->[0]->user, $user,              "User of collection item");


#
# find collection in ui
#

my $l = $user->collection('locations');
ok(defined $l,                                "Find locations");
isa_ok($l, $uicl);

my $l2 = $user->collection('location');
ok(defined $l,                                "Find location");
same_obj($l, $l2,                             "location==locations");

my $e = $user->collection('email');
ok(! defined $e,                              "Not available email");

#
# Fast forward location
#

my $w = $user->add(location => [ work => street => 'at home' ]);
ok(defined $w,                                "Work location created");
isa_ok($w, $uil);
same_obj($w->user, $user,                     "Knows about user");
cmp_ok(scalar $col->roles, '==', 2,           "Found pre-defined collection");
cmp_ok(@$col, '==', 2,                        "Visible in overload as well");
is("$col", "locations: home, work",           "Stringification");

#
# Find
#

my $f = $user->find(location => 'work');
ok(defined $f,                                 "Found anything");
same_obj($w, $f,                               "Found work back");

$f = $user->find(location => 'unknown');
ok(! defined $f,                               "Unknown role");

$f = $user->find(unknown => 'work');
ok(! defined $f,                               "Unknown collection");

#
# Add a whole new group at once
#

ok(! $user->find(email => 'private'));

$w = $user->add(email => [ private => address => 'markov@cpan.org' ]);
ok(defined $w,                                  "Private email created");
$col = $user->collection('email');
ok(defined $col,                                "Email collection created");
isa_ok($col, $uic);
isa_ok($col, "${uic}::Emails");

$f = $user->find(email => 'private');
ok(defined $f,                                  "Found anything");
isa_ok($f, "${ui}::Item");
isa_ok($f, "Mail::Identity");
