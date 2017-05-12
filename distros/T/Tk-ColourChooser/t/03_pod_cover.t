# $Id: 24_pod_cover.t 668 2006-10-02 16:09:19Z tinita $
use blib; # for development

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
plan tests => 1;
pod_coverage_ok( "Tk::ColourChooser", "TK::ColourChooser is covered");

