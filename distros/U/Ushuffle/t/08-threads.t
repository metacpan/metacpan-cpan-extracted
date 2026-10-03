use strict;
use warnings;

use Config;

BEGIN {
    if (!$Config{useithreads}) {
        print "1..0 # SKIP this perl has no thread support\n";
        exit 0;
    }
}

use threads;
use threads::shared;
use Test::More;
use Scalar::Util qw(blessed);

use FindBin;
use lib "$FindBin::Bin/lib";
use UshuffleTest;

use Ushuffle qw(shuffle set_seed);

# Threads share the library's single prepared sequence and its random number
# generator; the module serializes their use. Creating a thread must neither
# copy a shuffler into it nor free it twice.

my $seq      = 'ACACGUAGAUGGGGAUCGAUCGGAUUAGC';
my $shuffler = Ushuffle::Shuffler->new($seq, 2);
$shuffler->shuffle;

my @report = threads->create(
    { context => 'list' },
    sub {
        my $copied = blessed $shuffler ? 1 : 0;
        my $error  = eval { $shuffler->shuffle; 1 } ? '' : $@;

        my $own      = Ushuffle::Shuffler->new('UUGGCCAAUGCAUGCAGGCC', 3);
        my $own_bad  = grep { !same_klets('UUGGCCAAUGCAUGCAGGCC', $own->shuffle, 3) } 1 .. 20;
        my $func_bad = grep { !same_klets($seq, shuffle($seq, 2), 2) } 1 .. 20;
        return ($copied, $error, $own_bad, $func_bad);
    }
)->join;

my ($copied, $error, $own_bad, $func_bad) = @report;
is $copied, 0, 'a shuffler is not copied into a new thread';
like $error, qr/unblessed reference|undefined value/,
    'using the placeholder in the thread is an ordinary Perl error';
is $own_bad,  0, 'a thread can create and use its own shuffler';
is $func_bad, 0, 'a thread can use shuffle()';

isa_ok $shuffler, 'Ushuffle::Shuffler', 'the shuffler in the main thread';
is $shuffler->sequence, $seq, '... still has its sequence after the thread ended';
is scalar(grep { !same_klets($seq, $shuffler->shuffle, 2) } 1 .. 20), 0,
    '... and still gives valid shuffles';

# several threads, one after the other, while shufflers exist
for my $round (1 .. 5) {
    my $bad = threads->create(
        sub {
            my $own = Ushuffle::Shuffler->new($seq, 2);
            return scalar grep { !same_klets($seq, $own->shuffle, 2) } 1 .. 10;
        }
    )->join;
    is $bad + grep({ !same_klets($seq, $shuffler->shuffle, 2) } 1 .. 10), 0,
        "thread $round and the main thread in turn";
}

# threads running at the same time, each with its own sequence and let size
{
    my $go : shared = 0;
    my $worker = sub {
        my ($id) = @_;
        srand $id;
        my $own_seq  = random_sequence(40 + 7 * $id, 'ACGU');
        my $k        = 1 + $id % 3;
        my $shuffler = Ushuffle::Shuffler->new($own_seq, $k);
        {
            lock $go;
            cond_wait $go until $go;
        }
        my $bad = 0;
        for my $i (1 .. 3000) {
            my $out
                = $i % 3 == 0 ? shuffle($own_seq, $k)
                : $i % 3 == 1 ? $shuffler->shuffle
                :               Ushuffle::Shuffler->new($own_seq, $k)->shuffle;
            $bad++ unless same_klets($own_seq, $out, $k);
            set_seed($i) if $i % 500 == 0;
        }
        return $bad;
    };

    my @threads = map { threads->create($worker, $_) } 1 .. 6;
    {
        lock $go;
        $go = 1;
        cond_broadcast $go;
    }
    my $main_bad = grep { !same_klets($seq, $shuffler->shuffle, 2) } 1 .. 3000;
    my @bad      = map { $_->join } @threads;

    is "@bad",    '0 0 0 0 0 0', 'six threads shuffling at the same time';
    is $main_bad, 0,             'the main thread shuffling alongside them';
}

# the random number generator is one for all threads
{
    set_seed(9);
    my $here = join ' ', shuffle($seq, 2), shuffle($seq, 2);

    set_seed(9);
    my $there = threads->create(sub { join ' ', shuffle($seq, 2), shuffle($seq, 2) })->join;
    is $there, $here, 'a thread running alone draws from the generator seeded in the main thread';

    threads->create(sub { set_seed(9); 1 })->join;
    is join(' ', shuffle($seq, 2), shuffle($seq, 2)), $here,
        'a seed set in a thread applies to the main thread';
}

# a process in which only the threads load the module, one after the other
{
    my $code = <<'END';
use threads;
print join ' ', map {
    threads->create(sub {
        require Ushuffle;
        Ushuffle::set_seed(3) if $_[0] == 0;
        Ushuffle::shuffle('ACACGUAGAUGGGGAUCGAUCGGAUUAGC', 2);
    }, $_)->join
} 0 .. 2;
END
    my @inc = map {"-I$_"} grep { !ref } @INC;
    open my $fh, '-|', $^X, @inc, '-e', $code or die "cannot run $^X: $!";
    my $out = do { local $/; <$fh> };
    close $fh or die "child perl failed: $?";

    set_seed(3);
    is $out, join(' ', map { shuffle($seq, 2) } 0 .. 2),
        'loading the module in a later thread does not reseed the generator';
}

done_testing;
