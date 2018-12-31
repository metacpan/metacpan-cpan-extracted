use strict;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/..";
require "t/lb.pl";

BEGIN { plan tests => 15 }

foreach my $len (qw(2 76 998)) {
    foreach my $lang (qw(ja-a amitagyong ecclesiazusae ko-decomp)) {
	dotest_partial($lang, $lang, $len);
    }
    my $sea = Unicode::LineBreak::SouthEastAsian::supported();
    if ($sea) {
	$sea =~ m{libthai/(\d+)\.(\d+)\.(\d+)};
	if (0.001009 <= $1 + $2 * 0.001 + $3 * 0.000001) {
	    dotest_partial('th', 'th', $len);
	    next;
	}
    }
    dotest_partial('th', 'th.al', $len);
}
