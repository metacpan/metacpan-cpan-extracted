#!perl

use strict;
use warnings;

use Test::More qw[no_plan];

BEGIN {
    use_ok('UNIVERSAL::Object');
}

{
    package Counter;
    use strict;
    use warnings;

    use overload (
        '++' => 'inc',
        '--' => 'dec'
    );

    our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
    our %HAS; BEGIN {
        %HAS = (
            count => sub { 0 }
        )
    }

    sub count { $_[0]->{count} }

    sub inc { $_[0]->{count}++ }
    sub dec { $_[0]->{count}-- }
}

{
    my $c = Counter->new;
    isa_ok($c, 'Counter');

    is($c->count, 0, '... count is 0');

    $c++;
    is($c->count, 1, '... count is 1');

    $c->inc;
    is($c->count, 2, '... count is 2');

    $c--;
    is($c->count, 1, '... count is 1 again');

    $c->dec;
    is($c->count, 0, '... count is 0 again');
}


