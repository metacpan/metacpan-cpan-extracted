use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use UshuffleTest;

use Ushuffle qw(shuffle set_seed);

sub error_of {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : $@;
}

my $seq = 'ACACGUAGAUGGGGA';

# a shuffler that must survive every failed call below
my $survivor = Ushuffle::Shuffler->new('UUGGCCAAUGCAUGCAGGCC', 2);
$survivor->shuffle;

for my $make (
    [ 'shuffle'       => sub { shuffle(@_) } ],
    [ 'Shuffler->new' => sub { Ushuffle::Shuffler->new(@_) } ],
    )
{
    my ($name, $call) = @$make;

    like error_of(sub { $call->(undef, 2) }), qr/sequence is undefined/,
        "$name: undefined sequence";
    like error_of(sub { $call->("AC\0GU", 2) }), qr/NUL byte/,
        "$name: NUL byte in sequence";
    like error_of(sub { $call->("\0", 1) }), qr/NUL byte/,
        "$name: sequence of one NUL byte";
    like error_of(sub { $call->("ACGU\0", 2) }), qr/NUL byte/,
        "$name: NUL byte at the end";
    like error_of(sub { $call->("AC\x{263A}GU", 2) }), qr/Wide character/,
        "$name: character above 255";
    like error_of(sub { $call->("AC\x{100}GU", 2) }), qr/Wide character/,
        "$name: character 256";

    for my $k (0, -1, -3, -2**40, 0.5, '0', '') {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        like error_of(sub { $call->($seq, $k) }), qr/k must be a positive integer/,
            "$name: k of '$k'";
    }
    like error_of(sub { $call->($seq, undef) }), qr/k must be a positive integer/,
        "$name: undefined k";
    {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        my $word = 'two';
        like error_of(sub { $call->($seq, $word) }), qr/k must be a positive integer/,
            "$name: k that is not a number";
        like "@warnings", qr/isn't numeric/, "$name: ... with the usual warning";
    }

    like error_of(sub { $call->() }),             qr/Usage: /, "$name: no arguments";
    like error_of(sub { $call->($seq) }),         qr/Usage: /, "$name: missing k";
    like error_of(sub { $call->($seq, 2, 3) }),   qr/Usage: /, "$name: one argument too many";

    # the k is checked before the sequence is looked at
    like error_of(sub { $call->(undef, 0) }), qr/k must be a positive integer/,
        "$name: bad k and bad sequence";

    # errors are reported for the calling Perl code
    like error_of(sub { $call->(undef, 2) }), qr/ at \Q${\ __FILE__}\E line \d+\.$/,
        "$name: error names this file";
}

# accepted forms of k
{
    is length shuffle($seq, '2'), length $seq, 'k as a string';
    ok same_klets($seq, shuffle($seq, 2.9), 2), 'fractional k is truncated';
    ok same_klets($seq, shuffle($seq, 2e0), 2), 'k in exponent notation';
    is(Ushuffle::Shuffler->new($seq, 2.9)->k, 2, 'shuffler reports the truncated k');
    is(Ushuffle::Shuffler->new($seq, '3')->k, 3, 'shuffler takes k as a string');

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    ok same_klets($seq, shuffle($seq, '2 lets'), 2), 'k with trailing text is used';
    like "@warnings", qr/isn't numeric/, '... with the usual warning';
}

like error_of(sub { my $out = 'a' x 15; Ushuffle::shuffle($seq, $out, 15, 2) }),
    qr/Usage: Ushuffle::shuffle\(sequence, k\)/,
    'the four-argument form of version 0.01 is rejected';
ok !Ushuffle->can('shuffle1') && !Ushuffle->can('shuffle2'),
    'shuffle1 and shuffle2 are gone';

like error_of(sub { set_seed() }),     qr/Usage: Ushuffle::set_seed\(seed\)/, 'set_seed without a seed';
like error_of(sub { set_seed(1, 2) }), qr/Usage: Ushuffle::set_seed\(seed\)/, 'set_seed with two seeds';

# methods called on something that is not a shuffler
for my $method (qw(shuffle sequence k)) {
    my $code = Ushuffle::Shuffler->can($method);
    like error_of(sub { $code->('not an object') }), qr/Ushuffle::Shuffler/,
        "$method on a plain string";
    like error_of(sub { no warnings 'uninitialized'; $code->(undef) }), qr/Ushuffle::Shuffler/,
        "$method on undef";
    like error_of(sub { $code->({}) }), qr/Ushuffle::Shuffler/,
        "$method on an unblessed reference";
    like error_of(sub { $code->(bless {}, 'Some::Other::Class') }), qr/Ushuffle::Shuffler/,
        "$method on an object of another class";
    like error_of(sub { $code->() }), qr/Usage: /, "$method without an object";
    like error_of(sub { $code->($survivor, 1) }), qr/Usage: /, "$method with an extra argument";
}
like error_of(sub { Ushuffle::Shuffler->shuffle }), qr/Ushuffle::Shuffler/,
    'shuffle called on the class';
like error_of(sub { no warnings; Ushuffle::Shuffler::new(undef, $seq, 2) }), qr/class name expected/,
    'new without a class name';
like error_of(sub { Ushuffle::Shuffler::new('', $seq, 2) }), qr/class name expected/,
    'new with an empty class name';
like error_of(sub { Ushuffle::Shuffler->no_such_method }), qr/Can't locate object method/,
    'unknown method';

# nothing above may have damaged the module or the live shuffler
is length shuffle($seq, 2), length $seq, 'shuffle still works after the errors';
is $survivor->sequence, 'UUGGCCAAUGCAUGCAGGCC', 'the shuffler kept its sequence';
is scalar(grep { !same_klets($survivor->sequence, $survivor->shuffle, 2) } 1 .. 20), 0,
    'the shuffler still gives valid shuffles';

done_testing;
