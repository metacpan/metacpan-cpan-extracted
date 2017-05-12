use strict;
use warnings;

{ package TestRole::Role;   use Moose::Role;                                                  }
{ package TestRole::Role2;  use Moose::Role;                                                  }
{ package TestRole;         use Moose::Role; with 'TestRole::Role';                           }
{ package TestClass;        use Moose;       with 'TestRole::Role';                           }
{ package TestRole::Two;    use Moose::Role; with 'TestRole::Role';   with 'TestRole::Role2'; }
{ package TestClass::Two;   use Moose;       with 'TestRole::Role';   with 'TestRole::Role2'; }
{ package TestRole::Fail;   use Moose::Role;                                                  }
{ package TestClass::Fail;  use Moose;                                                        }
{ package TestRole::Fail2;  use Moose::Role; with 'TestRole::Role2';                          }
{ package TestClass::Fail2; use Moose;       with 'TestRole::Role2';                          }
{ package TestClass::NotMoosey;                                                               }

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;

use TAP::SimpleOutput 'counters';

my $ROLE  = 'TestRole::Role';
my @ROLES = qw{ TestRole::Role TestRole::Role2 };

note 'single role, default message - OK';
for my $thing (qw{ TestClass TestRole }) {
    my ($_ok, $_nok) = counters();
    test_out $_ok->("$thing does $ROLE");
    does_ok $thing, $ROLE;
    test_test "$thing is found to do $ROLE correctly";
}

note 'single role, custom message - OK';
for my $thing (qw{ TestClass TestRole }) {
    my ($_ok, $_nok) = counters();
    test_out $_ok->('wah-wah');
    does_ok $thing, $ROLE, 'wah-wah';
    test_test "$thing: custom messages work as expected";
}

note 'single role, "complex" custom message - OK';
for my $thing (qw{ TestClass TestRole }) {
    my ($_ok, $_nok) = counters();
    test_out $_ok->("wah-wah $ROLE");
    does_ok $thing, $ROLE, 'wah-wah %s';
    test_test "$thing: 'complex' custom messages work as expected";
}

note 'multiple roles, default message - OK';
for my $thing (qw{ TestClass::Two TestRole::Two }) {
    # role - OK
    my ($_ok, $_nok) = counters();
    test_out $_ok->("$thing does $_") for @ROLES;
    does_ok $thing, [ @ROLES ];
    test_test "$thing is found to do the roles correctly";
}

note 'multiple roles, custom message - OK';
for my $thing (qw{ TestClass::Two TestRole::Two }) {
    # role - OK
    my ($_ok, $_nok) = counters();
    my $msg = 'wah-wah';
    test_out $_ok->($msg) for @ROLES;
    does_ok $thing, [ @ROLES ], $msg;
    test_test "$thing: multiple roles, custom messages work as expected";
}

note 'multiple roles, "complex" custom message - OK';
for my $thing (qw{ TestClass::Two TestRole::Two }) {
    # role - OK
    my ($_ok, $_nok) = counters();
    my $msg = 'wah-wah';
    test_out $_ok->("$msg $_") for @ROLES;
    does_ok $thing, [ @ROLES ], "$msg %s";
    test_test "$thing: multiple roles, 'complex' custom messages work as expected";
}

note 'role - NOT OK';
for my $thing (qw{ TestClass::Fail TestRole::Fail }) {
    # role - NOT OK
    my ($_ok, $_nok) = counters();
    test_out $_nok->("$thing does $ROLE");
    test_fail 1;
    does_ok $thing, $ROLE;
    test_test "$thing is found to not do $ROLE correctly";
}

note 'multiple roles - NOT OK';
for my $thing (qw{ TestClass::Fail TestRole::Fail }) {
    # role - OK
    my ($_ok, $_nok) = counters();
    do { test_out $_nok->("$thing does $_"); test_fail 1 } for @ROLES;
    does_ok $thing, [ @ROLES ];
    test_test "$thing: multiple roles fail as expected";
}

note 'multiple roles - PARTIALLY OK';
for my $thing (qw{ TestClass::Fail2 TestRole::Fail2 }) {
    # role - OK
    my ($_ok, $_nok) = counters();
    do { test_out $_nok->("$thing does $_"); test_fail 2 } for $ROLES[0];
    do { test_out $_ok->("$thing does $_")               } for $ROLES[1];
    does_ok $thing, [ @ROLES ];
    test_test "$thing: multiple roles partially fail as expected";
}

note 'Class::MOP metaclass';
my $cmop_thing = 'TestClass::CMOP';
my $cmop_meta  = Class::MOP::Class->create($cmop_thing => (methods => { foo => sub { 1 } }));
{
    my ($_ok, $_nok) = counters();
    test_out $_nok->("$cmop_thing does $ROLE");
    test_fail 1;
    does_ok $cmop_thing => $ROLE;
    test_test q{Class::MOP metaclasses don't ever do roles};
}

done_testing;
