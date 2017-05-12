use strict;
use warnings;
use utf8;
use Test::More;

use Text::Shinobi qw/shinobi/;

is(shinobi('しのび') => q{𨊂浾⽕紫゙});
is(shinobi('シノビ') => q{𨊂浾⽕紫゙});
is(shinobi('シノbee') => q{𨊂浾bee});

is(shinobi("しのびなれども...\nParty Night!") => qq{𨊂浾⽕紫゙⾝⻩墴⾝⾊゙⼟紫...\nParty Night!});

done_testing();
