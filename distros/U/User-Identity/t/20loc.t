use warnings;
use strict;

# Test User::Identity::Location

use Test::More tests => 30;

BEGIN { use_ok('User::Identity::Location') };

my $ui  = 'User::Identity';
my $uil = 'User::Identity::Location';

#
# We need a user to test with
#

my $a   = $ui->new('markov'
 , firstname => 'Mark', surname => 'Overmeer'
 , titles => 'drs.',    initials => 'M.A.C.J.'
 , language => 'nl-NL', charset => 'iso-8859-15'
 , gender => 'male',    birth   => 'April 5, 1966'
 );

ok(defined $a,                               "Create a");

#
# Now an location
#

my $b = $uil->new
 ( 'home'
 , street       => 'Pad 12'
 , postal_code  => '66341 XA'
 , city         => 'Arnhem'
 , country      => 'Nederland'
 , country_code => 'nl'
 , phone        => '+18-12-2344556'
 , fax          => '+11-11-2344556'
 );

ok(defined $b);
isa_ok($b, $uil,                             "Create b");
is($b->street, 'Pad 12');
is($b->postalCode, '66341 XA');
is($b->city, 'Arnhem');
is($b->country, 'Nederland');
is($b->countryCode, 'nl');
is($b->phone, '+18-12-2344556');
is($b->fax, '+11-11-2344556');

ok(defined $b->parent($a),                   "Add location to user");
isa_ok($b->parent, $ui);
is($b->user->firstname, 'Mark');

is($b->fullAddress, <<'NL');
Pad 12
6341 XA  Arnhem
Nederland
NL

#
# more complex situations
#

my $c = $uil->new
 ( 'work'
 , organization => 'MARKOV Solutions'
 , pobox        => 'Postbus 12'
 , pobox_pc     => '3412YY'
 , city         => 'XYZ'
 , country_code => 'nl'
 , phone        => [ '1', '2' ]
 , fax          => [ '3', '4', '5', '6' ]
 );

ok(defined $c,                                  "Created c");
is($c->countryCode, 'nl');
is($c->organization, 'MARKOV Solutions');
is($c->pobox, 'Postbus 12');
is($c->poboxPostalCode, '3412YY');
is($c->city, 'XYZ');

is(scalar $c->phone, '1');
my @ct = $c->phone;
cmp_ok(scalar @ct, '==', 2);
is($ct[0], '1');
is($ct[1], '2');

is(scalar $c->fax, '3');
my @cf = $c->fax;
cmp_ok(scalar @cf, '==', 4);
is($cf[0], '3');
is($cf[3], '6');

eval 'require Geography::Countries';
my $country = $@ ? 'NL' : 'Netherlands';

is($c->fullAddress, <<NL);
MARKOV Solutions
Postbus 12
3412 YY  XYZ
$country
NL
