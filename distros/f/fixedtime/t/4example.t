#! perl
use warnings;
use strict;

# From the docs
use Test::More 'no_plan';

use constant EPOCH_OFFSET => 1204286400; # 29 Feb 2008 12:00:00 GMT

{
    use fixedtime epoch_offset => EPOCH_OFFSET;

    my $fixstamp = time;
    is $fixstamp, EPOCH_OFFSET, "Fixed point in time ($fixstamp)";
    is scalar gmtime, "Fri Feb 29 12:00:00 2008",
       "@{[ scalar gmtime ]}";

    no fixedtime;
    isnt time, EPOCH_OFFSET, "time() is back to normal";
}

isnt time, EPOCH_OFFSET, "time() is back to normal";
