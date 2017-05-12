use strict;
use warnings;

use Test::More tests => 3;
use Twitter::Date;
use Error qw(:try);
use Twitter::NoDateError;

my $date1 = Twitter::Date->new('Thu Dec 09 19:50:41 +0000 2010');
my $date2 = Twitter::Date->new('Thu Dec 09 20:50:41 +0000 2010');
my $date3 = Twitter::Date->new('Thu Dec 09 19:00:00 +0000 2010');

my @date = ( $date1, $date2, $date3 );

my @sorted = sort {$a->cmp($b)} @date;

ok ( $sorted[0]->eq($date3));
ok ( $sorted[1]->eq($date1));
ok ( $sorted[2]->eq($date2));

