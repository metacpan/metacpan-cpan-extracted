use Test::More 0.96;
use Test::Snapshot;

use strict;
use warnings;

$ENV{TEST_SNAPSHOT_UPDATE} = 0; # override to ensure known value

my $errdiag;

{
    no strict 'refs';
    no warnings 'redefine';
    *{"Test::More::diag"} = sub {
        $errdiag = shift;
    }
}

my $xcpt = 'blergo mymse throbbozongo';
$@ = $xcpt;

is_deeply_snapshot('foo bar', 'error');

unlike $errdiag, qr/$xcpt/, "exception not passed to diag()";

done_testing;
