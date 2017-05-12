use strict;
use warnings;
use Test::More;

use t::lib::Exceptions;

use Try::Lite;

subtest 'no exception' => sub {
    subtest 'scalar' => sub {
        my $ret = try {
            qw/ foo bar baz /;
        } ('*' => sub {});
        is $ret, 'baz';
    };

    subtest 'array' => sub {
        my @ret = try {
            qw/ foo bar baz /;
        } ('*' => sub {});
        is_deeply \@ret, [qw/ foo bar baz /];
    };
};

subtest 'exception' => sub {
    subtest 'scalar' => sub {
        my $ret = try {
            die;
        } ( '*' => sub {
            qw/ foo bar baz /;
        } );
        is $ret, 'baz';
    };

    subtest 'array' => sub {
        my @ret = try {
            die;
        } ( '*' => sub {
            qw/ foo bar baz /;
        } );
        is_deeply \@ret, [qw/ foo bar baz /];
    };
};


subtest 'returns undef' => sub {
    subtest 'try' => sub {

        subtest 'scalar' => sub {
            my $scalar = try {
                undef;
            } (
                '*' => sub {
                }
            );
            is $scalar, undef;

            my $array = try {
                (undef, undef);
            } (
                '*' => sub {
                }
            );
            is $array, undef;
        };

        subtest 'array' => sub {
            my($scalar) = try {
                undef;
            } (
                '*' => sub {
                }
            );
            is $scalar, undef;

            my($array1, $array2) = try {
                (undef, 1);
            } (
                '*' => sub {
                }
            );
            is $array1, undef;
            is $array2, 1;
        };
    };

    subtest 'catch' => sub {

        subtest 'scalar' => sub {
            my $scalar = try {
                die;
            } (
                '*' => sub {
                    undef;
                }
            );
            is $scalar, undef;

            my $array = try {
                die;
            } (
                '*' => sub {
                    (undef, undef);
                }
            );
            is $array, undef;
        };

        subtest 'array' => sub {
            my($scalar) = try {
                die;
            } (
                '*' => sub {
                    undef;
                }
            );
            is $scalar, undef;

            my($array1, $array2) = try {
                die;
            } (
                '*' => sub {
                    (undef, 1);
                }
            );
            is $array1, undef;
            is $array2, 1;
        };
    };

};

done_testing;
