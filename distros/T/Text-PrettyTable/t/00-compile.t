# 00-compile.t
# Before 'make install' is performed this script should be runnable
# with 'make test' or 'perl -Ilib t/00-compile.t' and
# After 'make install' it should work as 'perl 00-compile.t'

#########################

use strict;
use warnings;

use Test::More tests => 1;
BEGIN { use_ok('Text::PrettyTable') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
