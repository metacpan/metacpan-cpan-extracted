use warnings;
use strict;

use Test::More tests => 40;

BEGIN { use_ok('User::Identity') };

my $ui = 'User::Identity';

#
# Empty user
#

my $a = $ui->new();
ok(! defined $a,                             "No empty users");

#
# Test names
#

my $b = $ui->new('mark');
ok(defined $b,                               "Create b");
isa_ok($b, $ui);
is($b->name, 'mark',                         "Check b nick");
is($b->fullName, 'Mark',                     "Check b fullname");

my $c = $ui->new(name => 'mark');
ok(defined $c,                               "Create c");
isa_ok($c, $ui);
is($c->nickname, 'mark',                     "Check c nick");
is($c->fullName, 'Mark',                     "Check c fullname");
ok(!defined $c->gender);
ok(!$c->isMale);
ok(!$c->isFemale);

my $d = $ui->new('mark', firstname => 'Mark', surname => 'Overmeer',
   gender => 'male');
ok(defined $d,                               "Create d");
is($d->gender, 'male',                       "Check d gender");
ok($d->isMale);
ok(!$d->isFemale);
is($d->nickname, 'mark',                     "Check d nick");
is($d->firstname, 'Mark',                    "Check d first");
is($d->fullName, 'Mark Overmeer',            "Check d full");
is($d->formalName, 'Mr. M. Overmeer',        "Check d formal");
is($d->initials, 'M.',                       "Check d initials");

my $e = $ui->new('markov'
 , firstname => 'Mark', surname => 'Overmeer'
 , titles => 'drs.',    initials => 'M.A.C.J.'
 , language => 'nl-NL', charset => 'iso-8859-15'
 , gender => 'male',    birth => 'April 5, 1966'
 );

ok(defined $e,                               "Create e");
is($e->nickname, 'markov',                   "Check e nick");
is($e->firstname, 'Mark',                    "Check e first");
is($e->initials, 'M.A.C.J.',                 "Check e initials");
is($e->charset, 'iso-8859-15',               "Check e charset");
is($e->fullName, 'Mark Overmeer',            "Check e full");
is($e->formalName, 'De heer M.A.C.J. Overmeer drs.',  "Check e fullname");
is($e->dateOfBirth, 'April 5, 1966',         "check e birthday");

eval "require Date::Parse";
if($@) {ok(1);ok(1)}
else
{  is($e->birth, "19660405",                    "check e birth");
   cmp_ok($e->age, '>=', 36,                    "check e age");
}

my $f = $ui->new('am'
 , firstname => 'Anne-Marie Christina Theodora Pluk'
 , prefix => 'van', surname => 'Voorst tot Voorst'
 , gender => 'vrouw'
 );

ok(defined $e,                               "Create e");
is($f->initials, 'A-M.Chr.Th.P.');
is($f->gender, 'vrouw',                      "Check gender");
is($f->prefix, 'van',                        "Check prefix");
is($f->surname, 'Voorst tot Voorst',         "Check surname");
ok($f->isFemale);
ok(!$f->isMale);
is($f->formalName, "Madam A-M.Chr.Th.P. van Voorst tot Voorst");
