use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
    use_ok q{Try::ALRM};
}

# starts as default, $Try::ALRM::TIMEOUT;
is timeout, $Try::ALRM::TIMEOUT, sprintf( qq{default timeout is %d seconds}, timeout );

# set timeout (persists)
ok timeout(5), q{'timeout' method called as "setter" without issue};
is 5, $Try::ALRM::TIMEOUT, sprintf( qq{default timeout is %d seconds}, timeout );

my $alarm_triggered;

# try/ALRM
try {
    local $| = 1;

    # timeout is set to 1 due to trailing value after ALRM block
    is 1, $Try::ALRM::TIMEOUT, sprintf( qq{default timeout is %d seconds}, timeout );

    sleep 6;
}
ALRM {
    note qq{Alarm Clock!!};
    ++$alarm_triggered;
}
1;    # <~ temporarily overrides $Try::ALRM::TIMEOUg

is 1, $alarm_triggered,    q{custom $SIG{ALRM} handler triggered, as expected.};
is 5, $Try::ALRM::TIMEOUT, sprintf( qq{default timeout is %d seconds}, timeout );

$alarm_triggered = undef;

# try/ALRM
try {
    local $| = 1;

    # timeout is set to 1 due to trailing value after ALRM block
    is 5, $Try::ALRM::TIMEOUT, sprintf( qq{default timeout is %d seconds}, timeout );

    sleep 6;
}
ALRM {
    note qq{Alarm Clock!!};
    ++$alarm_triggered;
};    # <~ temporarily overrides $Try::ALRM::TIMEOUg

is 1, $alarm_triggered,    q{custom $SIG{ALRM} handler triggered, as expected.};
is 5, $Try::ALRM::TIMEOUT, sprintf( qq{default timeout is %d seconds}, timeout );
