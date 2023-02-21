use strict;
use Test::More 0.98;

use Text::ANSI::Fold;

my $fold = Text::ANSI::Fold->new;

$fold->text = "122333444455555";
is_deeply($fold->text, "122333444455555", "setter/getter");

is_deeply([ $fold->chops(width => [ 1..3 ]) ], [ qw(1 22 333) ], "chops");
is($fold->text, "444455555", "getter");

$fold->text =~ s/^(4444)//;
is($1, "4444", "s///");
is($fold->text, "55555", "modify");
is($fold->retrieve(width => -1), "55555", "retrieve");
is($fold->text, undef, "empty");

done_testing;
