use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, 'lib' );

use Test::Perl::Metrics::Lite (-mccabe_complexity => 300, -loc => 300);

BEGIN {
    all_metrics_ok( ('t/lib') );
}
