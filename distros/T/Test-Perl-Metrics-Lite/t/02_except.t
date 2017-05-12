use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, 'lib' );

use Test::Perl::Metrics::Lite ( -except_file => ['t/lib/Bad/BadClass.pm'] );

BEGIN {
    all_metrics_ok( ('t/lib') );
}
