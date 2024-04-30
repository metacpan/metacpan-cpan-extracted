use strict;
use warnings;
use Test::More;
use MyNote;
use File::Temp;

use vars qw($tmpdir $dat $sem);

BEGIN {
    $tmpdir = File::Temp->newdir(
        TEMPLATE => 'asserttestXXXXXXXX', CLEANUP => 0,
    );
    $dat = File::Temp::tempnam($tmpdir, 'asserttest');
    $sem = File::Temp::tempnam($tmpdir, 'asserttest');
    pass 'began';
}

use UUID 'uuid4';

uuid4;

my $kid = fork;

if (!defined($kid)) {
    fail 'fork';
}
else {
    if (!$kid) {
        open my $fh, '>', $dat or die "open: $dat: $!";
        print $fh uuid4()."\n"
            for 1 .. 10;
        open $fh, '>', $sem or die "open: $sem: $!";
        exit 0;
    }

    pass 'fork';

    my $timer = 200;
    while (!-e $sem) {
        select undef, undef, undef, 0.1;
        last unless --$timer > 0;
    }
    cmp_ok $timer, '>', 0, 'timer';

    if ($timer > 0) {
        my %seen;
        open my $fh, '<', $dat or die "open: $dat: $!";
        $seen{$_}=1 for map{chomp;$_} <$fh>;

        ok !exists($seen{uuid4()}), "unique $_"
            for 1 .. 10;
    }

    waitpid $kid, 0;
}

unlink $dat;
unlink $sem;
rmdir  $tmpdir;

done_testing;
