# Copyright (C) 2007 by Peter Pentchev
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.8 or,
# at your option, any later version of Perl 5 you may have available.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Domain-Registry-Joker.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('WWW::Domain::Registry::Joker') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

