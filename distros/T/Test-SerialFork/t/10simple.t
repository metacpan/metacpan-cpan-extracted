# $Id: 10simple.t,v 1.1 2005/07/27 15:09:06 pmh Exp $

# This test is really just checking that the right number of tests run

use Test::More tests => 10;
use Test::SerialFork;
use strict;

ok(1,'before fork');

my $label=serial_fork 'abc','def';

like($label,qr/\A(?:abc|def)\z/,'expected label');
