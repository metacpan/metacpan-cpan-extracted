use strict;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/..";
require "t/lb.pl";

BEGIN {
    require Unicode::LineBreak;
    my $sea = Unicode::LineBreak::SouthEastAsian::supported();
    if ($sea) {
	diag "SA word segmentation supported. $sea";
	$sea =~ m{libthai/(\d+)\.(\d+)\.(\d+)};
	if (0.001009 <= $1 + $2 * 0.001 + $3 * 0.000001) {
	    plan tests => 1;
	} else {
	    plan skip_all => "Your libthai is too old (cf. CPAN RT #61922).";
	}
    } else {
	plan skip_all => "SA word segmentation not supported.";
    }
}

dotest('th', 'th', ComplexBreaking => "YES");

1;

