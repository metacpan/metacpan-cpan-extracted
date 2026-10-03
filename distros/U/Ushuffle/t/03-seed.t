use strict;
use warnings;

use Config;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use UshuffleTest;

use Ushuffle qw(shuffle set_seed);

srand 3;
my $seq = random_sequence(200, 'ACGU');

# a fixed series of calls through both interfaces
sub draws {
    my ($seed) = @_;
    set_seed($seed);
    my $shuffler = Ushuffle::Shuffler->new($seq, 2);
    return join ' ', shuffle($seq, 2), shuffle($seq, 3), map { $shuffler->shuffle } 1 .. 3;
}

my $first = draws(42);
is draws(42),   $first, 'same seed, same shuffles';
isnt draws(43), $first, 'different seed, different shuffles';
is draws(42),   $first, 'seed can be set again';

is draws('42'),  $first, 'seed given as a string';
is draws(42.9),  $first, 'seed given as a fraction is truncated';
isnt draws(0),   $first, 'seed of zero';
is draws(0),     draws(0),          'seed of zero is reproducible';
is draws(2**32 - 1), draws(2**32 - 1), 'largest 32-bit seed is reproducible';

{
    my %distinct;
    $distinct{ draws($_) }++ for 1 .. 50;
    is scalar keys %distinct, 50, '50 seeds give 50 different series';
}

# seeding in the middle of a series restarts it
{
    set_seed(7);
    my @a = map { shuffle($seq, 2) } 1 .. 4;
    set_seed(7);
    my @b = map { shuffle($seq, 2) } 1 .. 2;
    set_seed(7);
    my @c = map { shuffle($seq, 2) } 1 .. 4;
    is "@b", "@a[0, 1]", 'a shorter series is a prefix of the longer one';
    is "@c", "@a",       'reseeding after a partial series';
    isnt $a[0], $a[1], 'successive shuffles after seeding differ';
}

# one shuffler across a reseed
{
    my $shuffler = Ushuffle::Shuffler->new($seq, 2);
    set_seed(11);
    my @a = map { $shuffler->shuffle } 1 .. 3;
    set_seed(11);
    my @b = map { $shuffler->shuffle } 1 .. 3;
    ok same_klets($seq, $_, 2), 'seeded shuffle is valid' for @a;
    is scalar(grep { !same_klets($seq, $_, 2) } @b), 0, 'shuffles after reseeding are valid';
}

# Perl's own generator is a separate one
{
    set_seed(5);
    srand 99;
    my $a = shuffle($seq, 2);
    set_seed(5);
    srand 1234;
    rand for 1 .. 10;
    my $b = shuffle($seq, 2);
    is $a, $b, 'srand and rand do not affect the shuffles';

    srand 77;
    my @before = map { rand } 1 .. 3;
    srand 77;
    shuffle($seq, 2);
    set_seed(1);
    my @after = map { rand } 1 .. 3;
    is "@after", "@before", 'shuffling and set_seed do not affect rand';
}

# a fresh interpreter that loads the module and prints one shuffle
sub in_new_process {
    my ($code) = @_;
    my @inc = map {"-I$_"} grep { !ref } @INC;
    open my $fh, '-|', $^X, @inc, '-MUshuffle', '-e', $code
        or die "cannot run $^X: $!";
    my $out = do { local $/; <$fh> };
    close $fh or die "child perl failed: $?";
    return $out;
}

my $unseeded = qq{print Ushuffle::shuffle("$seq", 2)};
my $seeded   = qq{Ushuffle::set_seed(7); print Ushuffle::shuffle("$seq", 2)};

my %unseeded;
$unseeded{ in_new_process($unseeded) }++ for 1 .. 5;
is scalar(grep { !same_klets($seq, $_, 2) } keys %unseeded), 0,
    'new processes return valid shuffles';
is scalar keys %unseeded, 5, 'five new processes are seeded differently';
is in_new_process($seeded), in_new_process($seeded),
    'new processes agree once given the same seed';
set_seed(7);
is shuffle($seq, 2), in_new_process($seeded), '... and agree with this process';

# a forked child starts from the state of its parent
SKIP: {
    skip 'no fork on this platform', 2 unless $Config{d_fork};

    require POSIX;
    set_seed(21);
    pipe my $read, my $write or die "pipe: $!";
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        close $read;
        print {$write} shuffle($seq, 2), ' ';
        set_seed(22);
        print {$write} shuffle($seq, 2);
        close $write;
        POSIX::_exit(0);
    }
    close $write;
    my ($inherited, $reseeded) = split ' ', do { local $/; <$read> };
    waitpid $pid, 0;

    is $inherited, shuffle($seq, 2), 'a forked child continues with the state of its parent';
    set_seed(22);
    is $reseeded, shuffle($seq, 2), 'a forked child can seed itself';
}

done_testing;
