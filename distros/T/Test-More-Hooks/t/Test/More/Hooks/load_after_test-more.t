use strict;
use warnings;

BEGIN {
    use Test::Simple tests => 2;
    use Test::Exception;
}

dies_ok (
    sub {
        require Test::More::Hooks;
        require Test::More;
    }, 'before load Test::More'
);

delete $INC{"Test/More.pm"};
delete $INC{"Test/More/Hooks.pm"};

lives_ok (
    sub {
        require Test::More;
        require Test::More::Hooks;
    }, 'after load Test::More'
);
