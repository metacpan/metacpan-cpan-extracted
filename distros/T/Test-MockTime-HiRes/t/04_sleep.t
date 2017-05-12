use strict;
use warnings;

use Test::More tests => 2;
use Test::MockTime::HiRes;

my @warnings;
$SIG{__WARN__} = sub {push @warnings, @_};

my $success = eval {
    sleep 0;
    1;
};

is $success, 1, 'sleep does not die';
is 0+@warnings, 0, 'no warnings';

done_testing;
