use Test::More tests => 1;
use FindBin;
use strict;
BEGIN {
	require "$FindBin::RealBin/Test.pm";
}
my $rss = XML::RSS::FromHTML::Test->new();
isa_ok($rss,'XML::RSS::FromHTML');