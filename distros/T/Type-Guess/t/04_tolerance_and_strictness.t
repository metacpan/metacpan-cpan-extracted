use strict;
use warnings;
use Test::More;
use Type::Guess;

my $t;

Type::Guess->skip_empty(0);
$t = Type::Guess->new(1, 2, "", 3, 4);
is($t->type, "Int");

Type::Guess->skip_empty(1);
Type::Guess->tolerance(0.25);

$t = Type::Guess->new(1, 2, "", 3, 4);
is($t->type, "Int");

Type::Guess->tolerance(0);
$t = Type::Guess->new(1, 2, "", 3, 4);
is($t->type, "Str");

done_testing()
