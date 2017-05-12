#!/perl -I..

# Test some error cases

use strict;
use Test::More tests => 3;

BEGIN { $Time::Format::NOXS = 1 }
BEGIN { use_ok 'Time::Format', qw(:all) }
my $err = 'Invalid call to Time::Format internal function';
my $len = length $err;

eval '$time{foo} = 1';
is substr($@,0,$len), $err,  'Store';

eval '%strftime = ()';
is substr($@,0,$len), $err, 'Clear';

