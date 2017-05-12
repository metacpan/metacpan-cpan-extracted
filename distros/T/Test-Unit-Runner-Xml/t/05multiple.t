use strict;
use Test;

BEGIN {plan tests => 2};

package FirstTestCase;

use base qw(Test::Unit::TestCase);

sub test_addition {
    my ($self) = @_;

    $self->assert_equals(2, 1 + 1);
}

package SecondTestCase;

use base qw(Test::Unit::TestCase);

sub test_subtraction {
    my ($self) = @_;

    $self->assert_equals(1, 2 - 1);
}

package main;

use Test::Unit::TestSuite;
use Test::Unit::Runner::XML;

my $suite = Test::Unit::TestSuite->new();
$suite->add_test(qw(FirstTestCase));
$suite->add_test(qw(SecondTestCase));
Test::Unit::Runner::XML->new(".")->start($suite);

ok(-e 'TEST-FirstTestCase.xml');
ok(-e 'TEST-SecondTestCase.xml');

unlink('TEST-FirstTestCase.xml');
unlink('TEST-SecondTestCase.xml');


