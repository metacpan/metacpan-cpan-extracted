use strict;
use Test;

BEGIN {plan tests => 6};

package TestCaseWithError::Error;

use base qw(Error);

package TestCaseWithError;

use base qw(Test::Unit::TestCase);

sub test_addition {
    my ($self) = @_;

    TestCaseWithError::Error->throw(-text => "Addition not implemented");
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
$suite->add_test(qw(TestCaseWithError));
my $runner = Test::Unit::Runner::XML->new(".");
$runner->start($suite);

ok(-e 'TEST-TestCaseWithError.xml');
ok(!$runner->all_tests_passed());

my $xp = XML::XPath->new(filename => 'TEST-TestCaseWithError.xml');

ok($xp->findvalue('/testsuite/@errors')->value(), 1);
ok($xp->findvalue('/testsuite/@failures')->value(), 0);
ok($xp->findvalue('/testsuite/@tests')->value(), 2);

ok($xp->findvalue('/testsuite/testcase/error/@message')->value(),
   'Addition not implemented');

unlink('TEST-TestCaseWithError.xml');


