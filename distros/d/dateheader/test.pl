# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use dateheader;
ok(1); # If we made it this far, we're ok.

my $D = $dateheader;

print "$D\n";

ok($D =~ /^Date: (Sun|Mon|Tue|Wed|Thu|Fri|Sat), \d+ (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d\d\d\d \d\d:\d\d:\d\d [\+\-]\d\d\d\d$/ );


