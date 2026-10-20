use strict;
use warnings;
use Test::More;
use Text::Table::Lite qw(generate_table);

for my $case (
    [ { rows => 'bad' }, qr/rows must be an ARRAY/ ],
    [ { rows => [['a']], border => 'bad' }, qr/unknown border style/ ],
    [ { rows => [['a']], align => 'left' }, qr/align must be an ARRAY/ ],
    [ { rows => [['a']], padding => -1 }, qr/padding must be/ ],
) {
    my ($args, $pattern) = @$case;
    my $ok = eval { generate_table(%$args); 1 };
    ok(!$ok, 'invalid input throws an error');
    like($@, $pattern, 'error explains invalid input');
}

done_testing;
