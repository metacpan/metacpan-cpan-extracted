use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
    use_ok q{Try::ALRM};
}

# starts as default, $Try::ALRM::TIMEOUT;
is timeout, $Try::ALRM::TIMEOUT, sprintf( qq{default timeout is %d seconds}, timeout );

# set timeout (persists)
ok timeout(5), q{'timeout' method called as "setter" without issue};
is 5, $Try::ALRM::TIMEOUT, sprintf( qq{default timeout is %d seconds}, timeout );

# setting to nullify default ALRM handler
$SIG{ALRM} = sub { note q{Alarm Clock!!} };

# try/ALRM
try {
    local $| = 1;

    # timeout is set to 1 due to trailing value after ALRM block
    is 1, $Try::ALRM::TIMEOUT, sprintf( qq{default timeout is %d seconds}, timeout );
    sleep 6;
}
1;

is 5, $Try::ALRM::TIMEOUT, sprintf( qq{default timeout is %d seconds}, timeout );
