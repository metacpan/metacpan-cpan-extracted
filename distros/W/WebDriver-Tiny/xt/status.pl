use strict;
use warnings;

sub {
    cmp_deeply shift->status, {
        build => { version => ignore },
        os    => {
            arch    => ignore,
            name    => ignore,
            version => ignore,
        },
    }, 'status';
};
