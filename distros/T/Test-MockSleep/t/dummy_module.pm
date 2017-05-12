package dummy_module;
use strict;
use warnings;
use Time::HiRes;

sub sleep_core {
    sleep(shift);
}
sub sleep_time_hires {
    Time::HiRes::sleep(shift);
}

package dummy_module_thr;
use Time::HiRes qw(sleep);

sub thr_sleep {
    sleep(shift);
}

1;
