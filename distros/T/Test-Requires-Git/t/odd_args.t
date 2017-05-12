use strict;
use warnings;
use Test::More;

use lib 't/lib';
use FakeGit '1.2.3';

use Test::Requires::Git; # the check always passes, because of t::FakeGit

plan tests => 6;

# any skip will 'skip all',
# this line ensures there will be a 'bad plan' failure in that case
pass('initial pass');

test_requires_git '1.2.3';
pass("passed the run-time check '1.2.3'");

test_requires_git '1.2.0';
pass("passed the run-time check '1.2.0'");

SKIP: {
    test_requires_git '1.6.0', skip => 1;
    fail('cannot happen');
}

SKIP: {
    test_requires_git skip => 1, '1.6.0';
    fail('cannot happen');
}

pass('all passed');
