use Test::More;
use Test::Exception;
use Data::Dumper;

BEGIN {
    use_ok 'Weaving::Tablet::Card';
}

dies_ok { Weaving::Tablet::Card->new } 'neither turns nor number of turns should die';
lives_ok { Weaving::Tablet::Card->new({number_of_turns => 10}) } 'handles hashref ok';
lives_ok { Weaving::Tablet::Card->new(number_of_turns => 10) } 'handles non-hashref ok';
lives_ok { Weaving::Tablet::Card->new(turns => '//\\//\\//\\//\\') } 'handles string turns ok';
lives_ok { Weaving::Tablet::Card->new(turns => [split(//, '\\\///\\\///')]) } 'handles arrayref turns ok';
lives_ok {Weaving::Tablet::Card->new(number_of_turns => 0) } 'empty card created';

my $card = Weaving::Tablet::Card->new(number_of_turns => 10);

is $card->number_of_turns, 10, 'number of cards';
is $card->number_of_holes, 4, 'number of holes';
is join('', @{$card->turns}), '//////////', 'turns are all forward';
is $card->threading->[0], 0, 'color 0 in hole 0';
is $card->threading->[1], 1, 'color 1 in hole 1';
is $card->threading->[2], 2, 'color 2 in hole 2';
is $card->threading->[3], 3, 'color 3 in hole 3';
is $card->SZ, 'S', 'S/Z';
is $card->start, 0, 'start position';
is_deeply $card->color, [qw/0 3 2 1 0 3 2 1 0 3/], 'colors';
is_deeply $card->twist, [qw/1 2 3 4 5 6 7 8 9 10/], 'twist';

$card->float_card;
is_deeply $card->floats, [[0,1], [1,2], [2,3], [3,4], [4,5], [5,6], [6,7], [7,8], [8,9], [9,10]], 'floats';

$card = Weaving::Tablet::Card->new(start => 'B', turns => '////\\\\///\\');
is $card->start, 1, 'start position by letter';
is_deeply $card->color, [qw/1 0 3 2 2 3 3 2 1 1/], 'colors';
is_deeply $card->twist, [qw/1 2 3 4 3 2 3 4 5 4/], 'twist';

$card->float_card;
is_deeply $card->floats, [[0,1], [1,2], [2,3], [3,5], [5,7], [7,8], [8,10]], 'floats';

$card->insert_picks(-1, '|');
is $card->turns->[0], '|', 'added float at start';
is $card->number_of_turns, 11, 'number of turns increased';
$card->insert_picks(5, '///\\\\\\');
is join('', @{$card->turns}), '|////\\///\\\\\\\\///\\', 'added turns in middle';
is $card->number_of_turns, 17, 'number of turns increased by six';
$card->delete_picks(0,1,2);
is $card->number_of_turns, 14, 'deleted three picks';
is join('', @{$card->turns}), '//\\///\\\\\\\\///\\', 'whacked three picks from beginning';

$card->set_threading([4,4,5,5]);
is_deeply $card->threading, [4,4,5,5], 'threading changed en masse';

#print Dumper($card->color, $card->turns);

done_testing();