use strict;
use Test::More;
use Test::Fatal;
use POSIX qw(setlocale LC_CTYPE);

SKIP: {
    my $loc_orig = setlocale(LC_CTYPE);
    if ( !defined $loc_orig || $loc_orig eq 'C' ) {
        my $loc_us = setlocale( LC_CTYPE, 'en_US.UTF-8' );
        skip "Unspported locale(en_US.UTF-8)", 1 unless defined $loc_us;
        $loc_orig = $loc_us;
    }
    subtest "Basic usage" => sub {
        use autolocale;
        $ENV{LANG} = "C";
        my $loc = setlocale(LC_CTYPE);
        is $loc, "C", 'autolocale enable';
        {
            local $ENV{LANG} = $loc_orig;
            $loc = setlocale(LC_CTYPE);
            is $loc, $loc_orig, 'in local scope';
        }
        $loc = setlocale(LC_CTYPE);
        is $loc, "C", "out of 'local' scope";
        no autolocale;
        $ENV{LANG} = $loc_orig;
        $loc = setlocale(LC_CTYPE);
        is $loc, "C", 'no autolocale';
        {
            use autolocale;
            $ENV{LANG} = $loc_orig;
            $loc = setlocale(LC_CTYPE);
            is $loc, $loc_orig, 'lexical use';
        }
        $ENV{LANG} = "C";
        $loc = setlocale(LC_CTYPE);
        is $loc, $loc_orig, 'out of lexical pragma';
    };

    subtest "Illegal usage" => sub {
        use autolocale;
        like exception {
            $ENV{"LANG"} = [];
        }, qr/^You must store scalar data to %ENV/;
    };

}

done_testing();
