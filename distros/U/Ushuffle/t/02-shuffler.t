use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use UshuffleTest;

use Ushuffle qw(shuffle);

# the number of invalid results among $n shuffles
sub bad_shuffles {
    my ($shuffler, $n) = @_;
    my ($seq, $k) = ($shuffler->sequence, $shuffler->k);
    return scalar grep { !same_klets($seq, $shuffler->shuffle, $k) } 1 .. $n;
}

my $seq      = 'ACACGUAGAUGGGGA';
my $shuffler = Ushuffle::Shuffler->new($seq, 2);

isa_ok $shuffler, 'Ushuffle::Shuffler';
is $shuffler->sequence, $seq, 'sequence';
is $shuffler->k,        2,    'k';
is bad_shuffles($shuffler, 100), 0, '100 shuffles keep the dinucleotide counts';
is $shuffler->sequence, $seq, 'sequence is unchanged after shuffling';
is $shuffler->k,        2,    'k is unchanged after shuffling';

{
    my %seen;
    $seen{ $shuffler->shuffle }++ for 1 .. 50;
    cmp_ok scalar keys %seen, '>', 1, 'successive shuffles differ';
}

# what the methods return belongs to the caller
{
    my $sequence = $shuffler->sequence;
    $sequence =~ tr/ACGU/UGCA/;
    is $shuffler->sequence, $seq, 'changing the returned sequence does not change the shuffler';

    my $first = $shuffler->shuffle;
    my $copy  = $first;
    my $next  = $shuffler->shuffle;
    is $first, $copy, 'an earlier shuffle is not overwritten by the next one';
    ok !utf8::is_utf8($first),               'shuffles are byte strings';
    ok !utf8::is_utf8($shuffler->sequence), 'the sequence is a byte string';

    my @list = $shuffler->shuffle;
    is scalar @list, 1, 'one value in list context';
}

# the shuffler must not depend on the scalar it was created from
{
    my $other;
    {
        my $source = 'UUGGCCAAUGCAUGCAGGCC';
        $other = Ushuffle::Shuffler->new($source, 3);
        $source = 'x' x 20;
    }
    my @filler = map { 'Z' x 20 } 1 .. 1000;
    is $other->sequence, 'UUGGCCAAUGCAUGCAGGCC', 'keeps its own copy of the sequence';
    is bad_shuffles($other, 20), 0, 'shuffles after the source scalar is gone';
}

# every let size from 1 to beyond the length
{
    srand 2;
    my $in  = random_sequence(40, 'ACGU');
    my @bad = grep { bad_shuffles(Ushuffle::Shuffler->new($in, $_), 3) } 1 .. 45;
    is "@bad", '', 'all let sizes from 1 to beyond the length';
}

# degenerate sequences
is(Ushuffle::Shuffler->new('',  2)->shuffle, '',  'empty sequence');
is(Ushuffle::Shuffler->new('',  2)->sequence, '', 'empty sequence is reported');
is(Ushuffle::Shuffler->new('A', 1)->shuffle, 'A', 'single letter');
is(Ushuffle::Shuffler->new('ACGUACGU', 50)->shuffle, 'ACGUACGU', 'k above the length');
is(Ushuffle::Shuffler->new('ACGUACGU', 50)->k,       50,         '... reports the k it was given');
is(Ushuffle::Shuffler->new('ACGUACGU', 2**40)->shuffle, 'ACGUACGU', 'k beyond the range of a C int');

# several shufflers, of different lengths and let sizes, used in turn
{
    my @shufflers = (
        Ushuffle::Shuffler->new('ACGU' x 3,                       2),
        Ushuffle::Shuffler->new('AACCGGUUACGUAGCUAGCUAGGAUC' x 8, 3),
        Ushuffle::Shuffler->new('GAUUACA',                        1),
        Ushuffle::Shuffler->new('',                               2),
        Ushuffle::Shuffler->new('ACGUACGU',                       50),
        Ushuffle::Shuffler->new('AACCGGUUACGUAGCUAGCUAGGAUC' x 8, 2),
    );
    my $bad = 0;
    for my $round (1 .. 30) {
        $bad += bad_shuffles($_, 1 + $round % 3) for @shufflers;
        $bad++ unless same_klets('GGGGCCCCAAAAUUUUGCGC', shuffle('GGGGCCCCAAAAUUUUGCGC', 2), 2);
    }
    is $bad, 0, 'interleaved shufflers and shuffle() calls do not disturb each other';
}

# two shufflers for the same sequence are independent objects
{
    my $one = Ushuffle::Shuffler->new($seq, 2);
    my $two = Ushuffle::Shuffler->new($seq, 3);
    is bad_shuffles($one, 5) + bad_shuffles($two, 5) + bad_shuffles($one, 5), 0,
        'same sequence, different let sizes';
    is $one->k, 2, 'first keeps its k';
    is $two->k, 3, 'second keeps its k';
}

# a destroyed shuffler must not take the state of a live one with it
{
    my $keep = Ushuffle::Shuffler->new('ACGUUGCAACGGUUAC', 2);
    $keep->shuffle;
    {
        my $gone = Ushuffle::Shuffler->new('AAAACCCC', 2);
        $gone->shuffle;
    }
    is bad_shuffles($keep, 20), 0, 'unaffected by another shuffler being destroyed';

    my $gone = Ushuffle::Shuffler->new('ACGUUGCAACGGUUAC', 2);
    $gone->shuffle;
    undef $gone;
    my $new = Ushuffle::Shuffler->new('UUUUGGGGCCCCAAAAUGCA', 2);
    is bad_shuffles($new, 20), 0, 'a new shuffler after the active one was destroyed';
}

# many shufflers alive at once, used in an order unrelated to their creation
{
    srand 3;
    my @many = map { Ushuffle::Shuffler->new(random_sequence(5 + $_ % 40, 'ACGU'), 1 + $_ % 4) }
        1 .. 500;
    my $bad = 0;
    $bad += bad_shuffles($many[ rand @many ], 1) for 1 .. 3000;
    is $bad, 0, '500 shufflers used in random order';
    @many = ();
    is bad_shuffles($shuffler, 5), 0, 'the first shuffler still works after they are gone';
}

# creating and dropping shufflers repeatedly
{
    my $bad = 0;
    for (1 .. 2000) {
        my $temp = Ushuffle::Shuffler->new('ACGUACGGUCA', 2);
        $bad += bad_shuffles($temp, 1);
    }
    is $bad, 0, '2000 short-lived shufflers';
}

{
    @My::Shuffler::ISA = ('Ushuffle::Shuffler');
    my $sub = My::Shuffler->new($seq, 2);
    isa_ok $sub, 'My::Shuffler';
    isa_ok $sub, 'Ushuffle::Shuffler';
    is bad_shuffles($sub, 5), 0, 'subclass instance shuffles';

    my $from_sub = $sub->new('UUGGCCAAUGCAUGCAGGCC', 3);
    isa_ok $from_sub, 'My::Shuffler', 'new called on a subclass instance';
    my $from_obj = $shuffler->new('UUGGCCAAUGCAUGCAGGCC', 3);
    isa_ok $from_obj, 'Ushuffle::Shuffler', 'new called on an instance';
    is $from_obj->sequence, 'UUGGCCAAUGCAUGCAGGCC', '... takes the new sequence';
    is $from_obj->k, 3, '... and the new k';
    is bad_shuffles($from_obj, 5), 0, '... and shuffles';
    is $shuffler->sequence, $seq, '... leaving the original instance alone';
}

# an explicit DESTROY call must not lead to a double free
{
    my $doomed = Ushuffle::Shuffler->new($seq, 2);
    $doomed->shuffle;
    $doomed->DESTROY;
    ok !eval { $doomed->shuffle; 1 }, 'a method after an explicit DESTROY fails';
    like $@, qr/already been destroyed/, '... with a clear message';
    ok !eval { $doomed->sequence; 1 }, 'sequence after an explicit DESTROY fails';
    $doomed->DESTROY;
    pass 'DESTROY can be called again';
    undef $doomed;
    pass 'and the object can go out of scope';
    is bad_shuffles($shuffler, 5), 0, 'other shufflers are unaffected';
}

done_testing;
