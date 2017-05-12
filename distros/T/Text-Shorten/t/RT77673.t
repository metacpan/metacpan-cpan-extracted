use Text::Shorten 'shorten_hash';
use Test::More tests => 1;
use strict;
use warnings;


# see RT#77673 from Devel-DumpTrace distribution --
# evaluating a hash in list context will reset the
# hash's internal iterator and could cause an
# infinite loop

my $hash = { 76000 .. 76049 };

my $count = 0;
while (my ($k,$v) = each %$hash) {
    last if $count++ > 500;
    my $y = shorten_hash $hash, 100;
}
ok ( $count < 100, 
     "RT#77673 - shorten_hash inside each does not cause infinite loop" );

