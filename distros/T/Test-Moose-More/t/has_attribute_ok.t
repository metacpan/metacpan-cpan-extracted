use strict;
use warnings;

{ package TestRole;        use Moose::Role; has foo => (is => 'ro'); }
{ package TestClass;       use Moose;       has foo => (is => 'ro'); }
{ package TestRole::Fail;  use Moose::Role; with 'TestRole';         }
{ package TestClass::Fail; use Moose;       with 'TestRole';         }
{ package TestClass::NotMoosey;                                      }

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;
use Scalar::Util 'blessed';

use TAP::SimpleOutput 'counters';

my @THINGS = (TestClass->new(), qw{ TestClass TestRole });
my @FAILS  = (qw{ TestClass::Fail TestRole::Fail });

note 'default message - OK';
for my $thing (@THINGS) {
    my $att = 'foo';
    my $thing_name = blessed $thing || $thing;
    my ($_ok, $_nok) = counters();
    test_out $_ok->("$thing_name has an attribute named $att");
    has_attribute_ok $thing, $att;
    test_test "$thing is found to have attribute $att correctly";
}

note 'custom message - OK';
for my $thing (@THINGS) {
    my $att = 'foo';
    my $thing_name = blessed $thing || $thing;
    my ($_ok, $_nok) = counters();
    test_out $_ok->('whee!');
    has_attribute_ok $thing, $att, 'whee!';
    test_test "$thing is found to have attribute $att correctly";
}

note 'default message - NOK';
for my $thing (@FAILS) {
    my $att = 'bar';
    my $thing_name = blessed $thing || $thing;
    my ($_ok, $_nok) = counters();
    test_out $_nok->("$thing_name has an attribute named $att");
    test_fail 1;
    has_attribute_ok $thing, $att;
    test_test "$thing is found to not have attribute $att correctly";
}

note 'custom message - NOK';
for my $thing (@FAILS) {
    my $att = 'bar';
    my $thing_name = blessed $thing || $thing;
    my ($_ok, $_nok) = counters();
    test_out $_nok->('whee!');
    test_fail 1;
    has_attribute_ok $thing, $att, 'whee!';
    test_test "$thing is found to not have attribute $att correctly";
}

done_testing;
__END__
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

done_testing;
