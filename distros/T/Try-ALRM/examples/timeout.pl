use strict;
use warnings;

use Try::ALRM;

# starts as default, $Try::ALRM::TIMEOUT;
printf qq{default timeout is %d seconds\n}, timeout;

# set timeout (persists)
timeout 5;
printf qq{timeout is set globally to %d seconds\n}, timeout;

# try/ALRM
try {
    local $| = 1;

    # timeout is set to 1 due to trailing value after ALRM block
    printf qq{timeout is now set locally to %d seconds\n}, timeout;
    sleep 6;
}
ALRM {
    print qq{Alarm Clock!!\n};
} 1; # <~ temporarily overrides $Try::ALRM::TIMEOUT

printf qq{timeout is set globally to %d seconds\n}, timeout;
