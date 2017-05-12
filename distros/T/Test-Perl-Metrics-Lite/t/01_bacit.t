use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 't', 'lib');

use Test::Perl::Metrics::Lite;

#use Test::Perl::Metrics::Lite (
#    -except_file => ['lib/Test/Perl/Metrics/Lite.pm']
#);

#use Test::Perl::Metrics::Lite (-mccabe_complexity => 6, -loc => 5);

BEGIN {
    all_metrics_ok();
}
