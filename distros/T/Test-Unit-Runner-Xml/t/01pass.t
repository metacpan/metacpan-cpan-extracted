use strict;
use Test;

BEGIN {plan tests => 9};

package PassingTestCase;

use base qw(Test::Unit::TestCase);

sub test_addition {
    my ($self) = @_;

    $self->assert_equals(2, 1 + 1);
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
$suite->add_test(qw(PassingTestCase));
my $runner = Test::Unit::Runner::XML->new(".");
$runner->start($suite);

ok(-e 'TEST-PassingTestCase.xml');
ok($runner->all_tests_passed());


my $xp = XML::XPath->new(filename => 'TEST-PassingTestCase.xml');

ok($xp->findvalue('/testsuite/@errors')->value(), 0);
ok($xp->findvalue('/testsuite/@failures')->value(), 0);
ok($xp->findvalue('/testsuite/@tests')->value(), 2);
ok($xp->findvalue('/testsuite/@name')->value(), 'PassingTestCase'); 

my @tests = sort map {$_->getNodeValue()}
  $xp->findnodes('/testsuite/testcase/@name');
ok(@tests, 2);
ok($tests[0], 'test_addition');
ok($tests[1], 'test_subtraction');

unlink('TEST-PassingTestCase.xml');


