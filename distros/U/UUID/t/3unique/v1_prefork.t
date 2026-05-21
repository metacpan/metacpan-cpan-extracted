use strict;
use warnings;
use MyTest;
use File::Temp;

use vars qw($tmpdir @dat @sem $I $N);

BEGIN {
    $I = 4;    # number for forks
    $N = 1000; # number of uuids / fork
    $tmpdir  = File::Temp->newdir('UUID-test-XXXXXXXX', TMPDIR => 1, CLEANUP => 0);
    $dat[$_] = File::Temp::tempnam($tmpdir, 'UUID.dat.') for 0 .. $I-1;
    $sem[$_] = File::Temp::tempnam($tmpdir, 'UUID.sem.') for 0 .. $I-1;
    pass 'began';
}

use UUID 'uuid1';

my @kids = ();
my %seen = ();
my $count = 0;

# Comment this to simulate a prefork process that
# doesnt actually use UUID in the parent.
#++$seen{uuid1()} for 1 .. $N;
#$count += $N;

$SIG{CHLD} = 'IGNORE';

for my $i ( 0 .. $I-1 ) {
    my $kid;
    if (!defined($kid = fork)) {
        fail "fork$i";
    }
    elsif ($kid) {
        pass "fork$i";
        push @kids, $kid;
    }
    else {
        my $fh;
        open $fh, '>', $dat[$i] or err("open: $dat[$i]: $!");
        print $fh uuid1()."\n" for 1 .. $N;
        close $fh;
        open $fh, '>', $sem[$i] or err("open: $sem[$i]: $!");
        print $fh "\n";
        close $fh;
        exit 0;
    }
}

# wait for kids
my $timeout = 100;
{
    my $found = 0;
    select undef, undef, undef, 0.1;
    for (0 .. $I-1) { $found++ if -e $sem[$_] }
    last if $found == $I;
    redo if --$timeout;
    # will always fail, or is skipped
    is $found, $I, 'semfiles found';
}
ok $timeout > 0, 'no timeout';

for my $i (0 .. $I-1) {
    open my $fh, '<', $dat[$i] or err("open: $dat[$i]: $!");
    for (<$fh>) {
        chomp;
        ++$seen{$_};
        ++$count;
    }
}

#use Data::Dumper;
#note "$_\n" for split /\n/, Dumper(\%seen);
{
    my $expected = $I * $N;
    my $got = scalar keys %seen;
    is $count, $expected, 'count ok';
    is $got,   $expected, 'unique ok';

    # show the repeats, if any
    my $reps = scalar grep { $seen{$_} > 1 } keys %seen;
    next unless $reps;
    diag q(     repeats: '). $reps. q(');
}

cleanup();
done_testing;

sub err {
    my $error = shift;
    my (undef, $F, $L) = caller;
    cleanup();
    die "$error at $F line $L\n";
}

sub cleanup {
    for my $i (0 .. $I-1) {
        unlink $dat[$i] if -e $dat[$i];
        unlink $sem[$i] if -e $sem[$i];
    }
    rmdir $tmpdir if defined $tmpdir;
}
