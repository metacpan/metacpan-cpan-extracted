my $I = 4;   # number for forks
my $N = 100; # number of uuids / fork

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

my $seen = {};

# Comment this to simulate a prefork process that
# doesnt actually use UUID in the parent.
++$seen->{uuid4()} for 1 .. $N;

for my $i ( 1 .. $I ) {
    my $kid = fork;

    if (!defined($kid)) {
        fail "fork$i";
    }
    else {
        if (!$kid) {
            open my $fh, '>', $dat or die "open: $dat: $!";
            print $fh uuid4()."\n"
                for 1 .. $N;
            open $fh, '>', $sem or die "open: $sem: $!";
            exit 0;
        }

        pass "fork$i";

        my $timer = 200;
        while (!-e $sem) {
            select undef, undef, undef, 0.1;
            last unless --$timer > 0;
        }
        cmp_ok $timer, '>', 0, "timer$i";

        if ($timer > 0) {
            open my $fh, '<', $dat or die "open: $dat: $!";
            ++$seen->{$_} for map{chomp;$_} <$fh>;

            #ok !exists($seen->{uuid4()}), "unique$i $_"
            #    for 1 .. $N;
        }

        waitpid $kid, 0;
        unlink $sem;
    }
}

#use Data::Dumper;
#note "$_\n" for split /\n/, Dumper($seen);
is scalar(keys %$seen), ($I+1)*$N, 'seen';

unlink $dat;
unlink $sem;
rmdir  $tmpdir;

done_testing;
