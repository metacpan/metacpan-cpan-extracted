use strict;
use warnings;
use Test::More tests => 2;
use ExtUtils::testlib;
BEGIN { use_ok('credsman')};

note("Open Credentian GUI");
pass(credsman::GuiCred( caption => 'Credsman GUI',
                        message => 'This is a test only, Close This Window' ));
done_testing;