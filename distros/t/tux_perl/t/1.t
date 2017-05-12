# This code is a part of tux_perl, and is released under the GPL.
# Copyright 2002 by Yale Huang<mailto:yale@sdf-eu.org>.
# See README and COPYING for more information, or see
#   http://tux-perl.sourceforge.net/.
#
# $Id: 1.t,v 1.2 2002/11/11 11:21:06 yaleh Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Tux::Constants') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

