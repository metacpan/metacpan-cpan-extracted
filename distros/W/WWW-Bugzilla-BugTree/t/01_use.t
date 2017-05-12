use strict;
use warnings;
use 5.012;
use Test::More tests => 3;
use Test::Script;

use_ok 'WWW::Bugzilla::BugTree';
use_ok 'WWW::Bugzilla::BugTree::Bug';
script_compiles 'bin/bug_tree';
