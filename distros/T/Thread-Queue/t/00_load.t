use strict;
use warnings;

use Test::More 'tests' => 1;

use_ok('Thread::Queue');
if ($Thread::Queue::VERSION) {
    diag('Testing Thread::Queue ' . $Thread::Queue::VERSION);
}

exit(0);

# EOF
