use strict;
use Test;

BEGIN {plan tests => 4};

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
Test::Unit::Runner::XML->new(".")->start($suite);

ok(-e 'TEST-PassingTestCase.xml');

my $xp = XML::XPath->new(filename => 'TEST-PassingTestCase.xml');

ok($xp->findvalue('/testsuite/@time')->value() > 0);
foreach my $node ($xp->findnodes('/testsuite/testcase/@time')) {
    ok($node->getNodeValue() > 0);
}

unlink('TEST-PassingTestCase.xml');
