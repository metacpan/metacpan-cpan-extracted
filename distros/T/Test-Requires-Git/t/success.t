use strict;
use warnings;
use Test::More;

use lib 't/lib';
use FakeGit '1.2.3';

use Test::Requires::Git; # the check always passes, because of t::FakeGit

plan tests => 9;

# any skip will 'skip all',
# this line ensures there will be a 'bad plan' failure in that case
pass('initial pass');

# force run-time evaluation
eval "use Test::Requires::Git version_gt => '1.0.0';";
pass("passed the compile-time check version_gt => '1.0.0'");

test_requires_git version => '1.2.3';
pass("passed the run-time check version => '1.2.3'");

test_requires_git
  version_eq => '1.2.3',
  version_ne => '1.2.4';
pass("passed the run-time check version_eq => '1.2.3', version_ne => '1.2.4'");

test_requires_git version_lt => '1.3.3';
pass("passed the run-time check version_lt => '1.3.3'");

test_requires_git version_gt => '1.0.0a';
pass("passed the run-time check version_gt => '1.0.0a'");

test_requires_git version_le => '1.2.3';
pass("passed the run-time check version_le => '1.2.3'");

test_requires_git version_ge => '1.2.3';
pass("passed the run-time check version_ge => '1.2.3'");

pass('all passed');
