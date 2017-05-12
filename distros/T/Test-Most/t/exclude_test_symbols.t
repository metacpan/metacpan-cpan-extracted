#!/usr/bin/perl

use lib 'lib', 't/lib';

BEGIN {
    package t::Fake;
    use Exporter 'import';
    our @EXPORT = 'any';
    our @EXPORT_OK = 'any';
    $INC{'t/Fake.pm'} => 1;
    # Test::Deep's any() returns a Test::Deep::Any object
    sub any { 1; }
}

use Test::Most tests => 5, '!any';
use OurTester qw($DIED dies);
t::Fake->import;

ok 1, 'Normal calls to ok() should succeed';
is 2, 2, '... as should all passing tests';
cmp_deeply [ 3, 4 ], [ 3, 4 ], '... and Test::Deep tests';
ok !ref(any('foo')), "... but any() calls our version, not Test::Deep's";

ok !(grep { $_ eq 'any' } @Test::Most::EXPORT), 'and "any" is not in our @EXPORT';

