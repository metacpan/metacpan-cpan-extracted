use strict;
use warnings;
use Test::More;

use t::lib::Exceptions;

use Try::Lite;

subtest 'undef' => sub {
    my @wantarraies;
    try {
        push @wantarraies, wantarray;
        die;
    } (
        '*' => sub {
            push @wantarraies, wantarray;
        }
    );
    is_deeply \@wantarraies, [ undef, undef ];
};

subtest 'scalar' => sub {
    my @wantarraies;
    my $s = try {
        push @wantarraies, wantarray;
        die;
    } (
        '*' => sub {
            push @wantarraies, wantarray;
        }
    );
    is_deeply \@wantarraies, [ '', '' ];
};

subtest 'array' => sub {
    my @wantarraies;
    my @s = try {
        push @wantarraies, wantarray;
        die;
    } (
        '*' => sub {
            push @wantarraies, wantarray;
        }
    );
    is_deeply \@wantarraies, [ 1, 1 ];
};

done_testing;
