use strict;
use warnings;

# this file is only parsable on 5.8+.

open my $stderr_copy, '>&', STDERR;
close STDERR;
open STDERR, '>', \my $stderr
    or die 'something went wrong when redirecting STDERR';

END {
    Test::More::note 'suppressed STDERR:', $stderr if $stderr;

    close STDERR;
    open STDERR, '>&', $stderr_copy
        or die 'something went wrong when restoring STDERR';
}
