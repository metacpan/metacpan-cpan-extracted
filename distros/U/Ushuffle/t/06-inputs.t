use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use UshuffleTest;

use Ushuffle qw(shuffle);

# The kinds of Perl values that can be passed as sequence and k.

my $seq = 'ACACGUAGAUGGGGAUCGAUCGGAUUAGC';

# both ways of handing over a sequence and a let size
my @interfaces = (
    [ 'shuffle'  => sub { shuffle($_[0], $_[1]) } ],
    [ 'Shuffler' => sub { Ushuffle::Shuffler->new($_[0], $_[1])->shuffle } ],
);

{
    package Counting;    # a tied scalar that counts how often it is read
    sub TIESCALAR { my ($class, $value) = @_; return bless { value => $value, reads => 0 }, $class }
    sub FETCH     { my ($self) = @_; $self->{reads}++; return $self->{value} }
    sub STORE     { die "the argument must not be written to\n" }
}

{
    package Stringy;     # an object that turns into a sequence
    use overload '""' => sub { $_[0]{seq} }, fallback => 1;
    sub new { my ($class, $seq) = @_; return bless { seq => $seq }, $class }
}

{
    package Numbery;     # an object that turns into a let size
    use overload '0+' => sub { $_[0]{k} }, fallback => 1;
    sub new { my ($class, $k) = @_; return bless { k => $k }, $class }
}

use constant CONSTANT_SEQ => 'ACACGUAGAUGGGGAUCGAUCGGAUUAGC';

for my $interface (@interfaces) {
    my ($name, $call) = @$interface;

    # read-only values
    ok same_klets($seq, $call->('ACACGUAGAUGGGGAUCGAUCGGAUUAGC', 2), 2), "$name: string literal";
    ok same_klets($seq, $call->(CONSTANT_SEQ, 2), 2), "$name: constant";
    is CONSTANT_SEQ, $seq, "$name: the constant is intact";
    {
        my $readonly = $seq;
        Internals::SvREADONLY($readonly, 1);
        ok same_klets($seq, $call->($readonly, 2), 2), "$name: read-only scalar";
        is $readonly, $seq, "$name: read-only scalar is intact";
    }

    # tied scalars are read once and never written
    {
        tie my $tied_seq, 'Counting', $seq;
        tie my $tied_k,   'Counting', 2;
        my $out = $call->($tied_seq, $tied_k);
        ok same_klets($seq, $out, 2), "$name: tied sequence and tied k";
        is tied($tied_seq)->{reads}, 1, "$name: tied sequence is fetched once";
        is tied($tied_k)->{reads},   1, "$name: tied k is fetched once";

        tie my $tied_undef, 'Counting', undef;
        ok !eval { $call->($tied_undef, 2); 1 }, "$name: tied scalar holding undef is rejected";
        like $@, qr/sequence is undefined/, "$name: ... as an undefined sequence";
        tie my $tied_nul, 'Counting', "AC\0GU";
        ok !eval { $call->($tied_nul, 2); 1 }, "$name: tied scalar holding a NUL byte is rejected";
    }

    # other magical values
    {
        'xxACGUACGAUCGGAUUAGCxx' =~ /x+([ACGU]+)x+/ or die 'no match';
        ok same_klets('ACGUACGAUCGGAUUAGC', $call->($1, 2), 2), "$name: capture variable";

        my $buffer = "NNNN${seq}NNNN";
        ok same_klets($seq, $call->(substr($buffer, 4, length $seq), 2), 2), "$name: substr";
        is $buffer, "NNNN${seq}NNNN", "$name: substr source is intact";

        my %hash  = (seq => $seq);
        my @array = ($seq);
        ok same_klets($seq, $call->($hash{seq}, 2), 2), "$name: hash element";
        ok same_klets($seq, $call->($array[0],  2), 2), "$name: array element";

        local $_ = $seq;
        ok same_klets($seq, $call->($_, 2), 2), "$name: \$_";
        is $_, $seq, "$name: \$_ is intact";
    }

    # objects with overloading
    {
        my $object = Stringy->new($seq);
        ok same_klets($seq, $call->($object, 2), 2), "$name: object that stringifies";
        isa_ok $object, 'Stringy', "$name: the object afterwards";
        ok same_klets($seq, $call->($seq, Numbery->new(3)), 3), "$name: object that numifies as k";
    }

    # numbers as sequences
    is length $call->(1234567890, 2), 10, "$name: integer as sequence";
    is length $call->(3.14159,    1), 7,  "$name: fraction as sequence";
    {
        my $number = 1122334455;
        my $out    = $call->($number, 2);
        ok same_klets('1122334455', $out, 2), "$name: numeric variable as sequence";
        is $number + 1, 1122334456, "$name: the variable is still a number";
    }

    # the internal encoding of a string must not matter
    {
        my $latin = "A\xE9CA\xE9GA\xE9C\xFFA\xFF";
        utf8::upgrade(my $upgraded = $latin);
        ok utf8::is_utf8($upgraded), "$name: test string is upgraded";
        my $out = $call->($upgraded, 2);
        ok same_klets($latin, $out, 2), "$name: upgraded string is shuffled by character";
        is $upgraded, $latin, "$name: upgraded input still compares equal";
        ok !utf8::is_utf8($out), "$name: result of an upgraded input is a byte string";

        utf8::upgrade(my $ascii = $seq);
        ok same_klets($seq, $call->($ascii, 2), 2), "$name: upgraded ASCII string";

        # a literal with non-ASCII characters under "use utf8" is a read-only
        # string whose internal form is UTF-8
        my $out_literal = do { use utf8; $call->("AéCAéGAéCÿAÿ", 2) };
        ok same_klets($latin, $out_literal, 2), "$name: read-only literal in UTF-8 form";

        utf8::upgrade(my $k = '2');
        ok same_klets($seq, $call->($seq, $k), 2), "$name: upgraded k";
    }

    # all byte values except NUL
    {
        my $bytes = join '', map { chr } 1 .. 255;
        my $in    = $bytes . reverse($bytes) . $bytes;
        for my $k (1, 2, 3) {
            ok same_klets($in, $call->($in, $k), $k), "$name: all 255 non-NUL bytes, k=$k";
        }
    }

    # the same scalar as sequence and as k
    {
        my $both = '3333333333';
        is $call->($both, $both), '3333333333', "$name: one scalar as sequence and k";
    }
}

# a shuffler built from a magical value keeps a plain copy
{
    tie my $tied, 'Counting', $seq;
    my $shuffler = Ushuffle::Shuffler->new($tied, 2);
    $shuffler->shuffle for 1 .. 10;
    is $shuffler->sequence, $seq, 'shuffler from a tied scalar reports the sequence';
    is tied($tied)->{reads}, 1, '... and never reads the tied scalar again';

    my $object   = Stringy->new($seq);
    my $from_obj = Ushuffle::Shuffler->new($object, 2);
    is $from_obj->sequence, $seq, 'shuffler from an object stores the string';
    ok !ref $from_obj->sequence, '... not the object';
}

done_testing;
