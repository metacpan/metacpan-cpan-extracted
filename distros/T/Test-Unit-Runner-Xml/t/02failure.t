use strict;
use Test;

BEGIN {plan tests => 6};

package TestCaseWithFailure;

use base qw(Test::Unit::TestCase);

sub test_addition {
    my ($self) = @_;

    $self->assert_equals(3, 1 + 1);
}

sub test_subtraction {
    my ($self) = @_;

    $self->assert_equals(1, 2 - 1);
}

package main;

use XML::XPath;
use Test::Unit::TestSuite;
use Test::Unit::Runner::XML;

my $suite = Test::Unit::TestSuite->new();
$suite->add_test(qw(TestCaseWithFailure));
my $runner = Test::Unit::Runner::XML->new(".");
$runner->start($suite);

ok(-e 'TEST-TestCaseWithFailure.xml');
ok(!$runner->all_tests_passed());

my $xp = XML::XPath->new(filename => 'TEST-TestCaseWithFailure.xml');

ok($xp->findvalue('/testsuite/@errors')->value(), 0);
ok($xp->findvalue('/testsuite/@failures')->value(), 1);
ok($xp->findvalue('/testsuite/@tests')->value(), 2);

ok($xp->findvalue('/testsuite/testcase/failure/@message')->value(),
   'expected 3, got 2');

unlink('TEST-TestCaseWithFailure.xml');

