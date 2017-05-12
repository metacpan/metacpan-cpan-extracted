use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => 'Capture::Tiny 0.12 required'
        unless eval { require Capture::Tiny; Capture::Tiny->VERSION(0.12); 1 };
    plan tests => 3;
    Capture::Tiny->import(qw(capture_stderr));
}

for my $func (qw(try catch finally)) {
    is capture_stderr {
        system $^X, qw(-It/lib -we),
            qq{sub DESTROY { require TryUser; TryUser->test_$func }} .
             q{our $o; $o = bless []};
    }, '', "$func gets installed when loading Try::Tiny during global destruction";
}
