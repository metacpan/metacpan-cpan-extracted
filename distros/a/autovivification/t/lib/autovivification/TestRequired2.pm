package autovivification::TestRequired2;

no autovivification;

BEGIN {
 delete $INC{'autovivification/TestRequired1.pm'};
}

use lib 't/lib';
use autovivification::TestRequired1;

my $x = $main::blurp->{r2_main}->{vivify};

eval 'my $y = $main::blurp->{r2_eval}->{vivify}';

1;
