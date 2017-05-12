use strict;
use warnings;

use Test::More 'tests' => 1;

use_ok('Thread::Semaphore');
if ($Thread::Semaphore::VERSION) {
    diag('Testing Thread::Semaphore ' . $Thread::Semaphore::VERSION);
}

exit(0);

# EOF
