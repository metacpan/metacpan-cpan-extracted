use Test::More;
use Test::Exception;
use Data::Dumper;

BEGIN {
    use_ok 'Weaving::Tablet';
}

lives_ok {Weaving::Tablet->new} 'create default pattern';

my $pattern = Weaving::Tablet->new;
is $pattern->number_of_cards, 20, 'default number of cards';
is $pattern->number_of_rows, 10, 'default number of rows';
lives_ok { $pattern->twist_pattern } 'twist_pattern lives';
lives_ok { $pattern->insert_pick } 'insert_pick() lives';
lives_ok { $pattern->insert_pick([-1, '/|/|/|/|/|/|/|/|/|/|']) } 'insert_pick([-1,...]) lives';
is $pattern->SZ->[0], 'S', 'card 0 is S';

done_testing();

#print $pattern->dump_pattern;