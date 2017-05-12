# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tie-StoredOrderHash.t'

#########################

use Test::More tests => 85;
BEGIN { use_ok('Tie::StoredOrderHash', 'ordered', 'is_ordered') };

#########################

{
    # Basic construction tests; insert/update/delete on initially-empty tied hash

    tie my %hash, 'Tie::StoredOrderHash';
    ok(tied %hash, 'tied hash successfully');

    is(@{[%hash]}, 0, 'no elements in new hash');

    ok(! exists($hash{nonexistent}), 'non-existent element does not exist in empty hash');
    ok(! defined($hash{other_nonexistent}), 'non-existent element is undefined in empty hash');

    $hash{one} = 1;
    ok(exists($hash{one}), 'existence works');
    ok(! exists($hash{nonexistent}), 'non-existent element does not exist in non-empty hash');

    is_deeply([ keys %hash ], [qw( one )], 'keys are (one)');
    is_deeply([ values %hash ], [qw( 1 )], 'values are (1)');

    $hash{two} = 2;
    is_deeply([ keys %hash ], [qw( one two )], 'keys are (one,two)');
    is_deeply([ values %hash ], [qw( 1 2 )], 'values are (1,2)');

    $hash{three} = 3;
    is_deeply([ keys %hash ], [qw( one two three )], 'keys are (one,two,three)');
    is_deeply([ values %hash ], [qw( 1 2 3 )], 'values are (1,2,3)');

    is($hash{two}, 2, 'stored element has expected value');

    $hash{one} = 'uno';
    is($hash{one}, 'uno', 're-stored first-element has expected value');
    is_deeply([ keys %hash ], [qw( two three one )], 'keys are (two,three,one)');
    is_deeply([ values %hash ], [qw( 2 3 uno )], 'values are (2,3,uno)');

    $hash{three} = 'tres';
    is($hash{three}, 'tres', 're-stored middle-element has expected value');
    is_deeply([ keys %hash ], [qw( two one three )], 'keys are (two,one,three)');
    is_deeply([ values %hash ], [qw( 2 uno tres )], 'values are (2,uno,tres)');

    $hash{three} = 'trie';
    is($hash{three}, 'trie', 're-stored end-element has expected value');
    is_deeply([ keys %hash ], [qw( two one three )], 'keys are (two,one,three)');
    is_deeply([ values %hash ], [qw( 2 uno trie )], 'values are (2,uno,trie)');

    delete $hash{nonexistent};
    is_deeply([ keys %hash ], [qw( two one three )], 'keys are (two,one,three) after bogus delete');
    is_deeply([ values %hash ], [qw( 2 uno trie )], 'values are (2,uno,trie) after bogus delete');

    delete $hash{one};
    is_deeply([ keys %hash ], [qw( two three )], 'keys are (two,three) after middle delete');
    is_deeply([ values %hash ], [qw( 2 trie )], 'values are (2,trie) after middle delete');

    $hash{one} = 'oneagain';
    is_deeply([ keys %hash ], [qw( two three one )], 'keys are (two,three,one) after re-insertion');
    is_deeply([ values %hash ], [qw( 2 trie oneagain )], 'values are (2,trie,oneagain) after re-insertion');

    delete $hash{two};
    is_deeply([ keys %hash ], [qw( three one )], 'keys are (three,one) after beginning delete');
    is_deeply([ values %hash ], [qw( trie oneagain )], 'values are (trie,oneagain) after beginning delete');

    $hash{two} = 'duus';
    is_deeply([ keys %hash ], [qw( three one two )], 'keys are (three,one,two) after re-insertion');
    is_deeply([ values %hash ], [qw( trie oneagain duus )], 'values are (trie,oneagain,duus) after re-insertion');

    delete $hash{two};
    is_deeply([ keys %hash ], [qw( three one )], 'keys are (three,one) after end delete');
    is_deeply([ values %hash ], [qw( trie oneagain )], 'values are (trie,oneagain) after end delete');

    delete $hash{three};
    is_deeply([ keys %hash ], [qw( one )], 'keys are (one) after beginning delete');
    is_deeply([ values %hash ], [qw( oneagain )], 'values are (oneagain) after beginning delete');

    delete $hash{one};
    is_deeply([ keys %hash ], [qw( )], 'keys are () after last delete');
    is_deeply([ values %hash ], [qw( )], 'values are () after last delete');

    $hash{a} = 'eh';
    is_deeply([ keys %hash ], [qw( a )], 'keys are (a) after insertion into emptied hash');
    is_deeply([ values %hash ], [qw( eh )], 'values are (eh) after insertion into emptied hash');

    $hash{c} = 'see';
    $hash{b} = 'bee';
    ok(exists $hash{a}, 'a exists');
    ok(exists $hash{b}, 'b exists');
    ok(exists $hash{c}, 'c exists');
    is_deeply([ keys %hash ], [qw( a c b )], 'keys are (a,c,b) after insertion');
    is_deeply([ values %hash ], [qw( eh see bee )], 'values are (eh,see,bee) after insertion');

    $hash{c} = 'see';
    is_deeply([ keys %hash ], [qw( a b c )], 'keys are (a,b,c) after update');
    is_deeply([ values %hash ], [qw( eh bee see )], 'values are (eh,bee,see) after update');

    is($hash{b}, 'bee', 'hash{b} is bee');
}

{
    # Initialisation of hash from list of keys and values

    tie my %hash, 'Tie::StoredOrderHash', qw( a 1 b 2 c 3 d 4 );

    is_deeply([ keys %hash ], [qw( a b c d )], 'keys are (a,b,c,d) after initialisation');
    is_deeply([ values %hash ], [qw( 1 2 3 4 )], 'values are (1,2,3,4) after initialisation');
}

{
    # Initialisation of hash from list of keys and values, with duplicated first/last key

    tie my %hash, 'Tie::StoredOrderHash', qw( a 1 b 2 c 3 a 4 );

    is_deeply([ keys %hash ], [qw( b c a )], 'keys are (b,c,a) after initialisation with duplicate keys');
    is_deeply([ values %hash ], [qw( 2 3 4 )], 'keys are (2,3,4) after initialisation with duplicate keys');
}

{
    # Initialisation of hash from list of keys and values, with duplicated first/middle key

    tie my %hash, 'Tie::StoredOrderHash', qw( a 1 b 2 a 3 c 4 );

    is_deeply([ keys %hash ], [qw( b a c )], 'keys are (b,a,c) after initialisation with duplicate keys');
    is_deeply([ values %hash ], [qw( 2 3 4 )], 'keys are (2,3,4) after initialisation with duplicate keys');
}

{
    # Initialisation of hash from list of keys and values, with duplicated middle/middle key

    tie my %hash, 'Tie::StoredOrderHash', qw( a 1 b 2 c 3 b 4 d 5 );

    is_deeply([ keys %hash ], [qw( a c b d )], 'keys are (a,c,b,d) after initialisation with duplicate keys');
    is_deeply([ values %hash ], [qw( 1 3 4 5 )], 'keys are (1,3,4,5) after initialisation with duplicate keys');
}

{
    # Modification of hash during iteration

    tie my %hash, 'Tie::StoredOrderHash', qw( a 1 b 2 c 3 );

    my $first_key = each %hash;
    is($first_key, 'a', 'first key from each is "a"');

    my ($second_key, $second_val) = each %hash;
    is($second_key, 'b', 'second key from each is "b"');
    is($second_val, '2', 'second value from each is "2"');

    $hash{d} = '4';
    $hash{e} = '5';
    my ($third_key, $third_val) = each %hash;
    is($third_key, 'c', 'third key from each is "c"');
    is($third_val, '3', 'third value from each is "3"');

    my ($fourth_key, $fourth_val) = each %hash;
    is($fourth_key, 'd', 'fourth key from each is "d"');
    is($fourth_val, '4', 'fourth value from each is "4"');

    $hash{a} = 6;
    my ($fifth_key, $fifth_val) = each %hash;
    is($fifth_key, 'e', 'fifth key from each is "e"');
    is($fifth_val, '5', 'fifth value from each is "5"');

    $hash{e} = 7;
    my ($sixth_key, $sixth_val) = each %hash;
    is($sixth_key, 'a', 'sixth key from each is "a" after modifying current element');
    is($sixth_val, '6', 'sixth value from each is "6" after modifying current element');

    my ($seventh_key, $seventh_val) = each %hash;
    is($seventh_key, 'e', 'seventh key from each is "e"');
    is($seventh_val, '7', 'seventh value from each is "7"');

    ok(! defined(each %hash), 'end of hash as expected');
}

{
    # Creation of hash using new() constructor

    my $hash = Tie::StoredOrderHash->new(one => 1, two => 2, three => 3);
    ok($hash, 'created tied hash object using new constructor');
    ok(tied(%$hash), 'created tied hash object');

    $hash->{five} = 5;
    $hash->{four} = 4;
    $hash->{six} = 6;
    $hash->{seven} = 7;
    $hash->{eight} = 8;

    is_deeply([ keys %$hash ], [qw( one two three five four six seven eight )], 'keys are (one,two,three,five,four,six,seven,eight) after update');
    is_deeply([ values %$hash ], [qw( 1 2 3 5 4 6 7 8 )], 'values are (1,2,3,5,4,6,7,8) after update');
}

{
    # Creation of hash using ordered()

    my $hash = ordered [ one => 1, two => 2, three => 3 ];

    is_deeply([ keys %$hash ], [qw( one two three )], 'keys are (one,two,three) after init');
    is_deeply([ values %$hash ], [qw( 1 2 3 )], 'values are (1,2,3) after init');
}

{
    # Creation of nested hashes using ordered()

    my $hash = ordered [
        one => 1,
        two => 2,
        three => ordered [
            a => 'aye',
            b => 'bee'
        ],
        four => 4,
        five => ordered [
            x => 'x',
            y => ordered [
                foo => 'bar'
            ],
            z => 'z'
        ],
        six => 6
    ];

    is_deeply([ keys %$hash ], [qw/ one two three four five six /], 'keys correct for outer level of nested hashes');
    is_deeply([ keys %{$hash->{five}} ], [qw/ x y z /], 'keys correct for inner level of nested hashes');
    is_deeply([ keys %{$hash->{five}->{y}} ], [qw/ foo /], 'keys correct for innermost level of nested hashes');
}

{
    # Testing of is_ordered()

    my $hash = ordered [ one => 1 ];
    ok(is_ordered($hash), 'is_ordered recognises ordered hash');
    ok(! is_ordered({}), 'is_ordered recognises regular boring non-ordered hash');
}

{
    # Regression test:
    # was a bug: retrieving a non-existent key messes up the internal structures if that key is subsequently stored.

    tie my %hash, 'Tie::StoredOrderHash';

    is($hash{foo}, undef, 'value of key foo is undef');
    $hash{foo} = "bar";

    is($hash{foo}, "bar", 'value of key "foo" is "bar"');
    is(keys %hash, 1, 'hash has 1 key');
}
