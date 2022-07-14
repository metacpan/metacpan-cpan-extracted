use strict;
use warnings;

use Try::ALRM qw/ALRM timeout/; # <~ NB!
use Try::Tiny;

# starts as default, $Try::ALRM::TIMEOUT;
printf qq{default timeout is %d seconds\n}, timeout;

# set timeout (persists)
timeout 5;
printf qq{timeout is set globally to %d seconds\n}, timeout;

# try/ALRM
Try::ALRM::try {   # <~ NB!
    local $| = 1;

    try {
      die qq{foo\n};
    }
    catch {
      print qq{$_\n};
    };

    # timeout is set to 1 due to trailing value after ALRM block
    printf qq{timeout is now set locally to %d seconds\n}, timeout;
    sleep 6;
}
ALRM {
    print qq{Alarm Clock!!\n};
} 1; # <~ temporarily overrides $Try::ALRM::TIMEOUT

printf qq{timeout is set globally to %d seconds\n}, timeout;
