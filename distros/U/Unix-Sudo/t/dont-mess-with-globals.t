use strict;
use warnings;
use Test::More;

BEGIN {
    $Data::Dumper::Deparse = 'lemon curry';
    $Data::Dumper::Indent  = 'spam';
}

use Unix::Sudo qw(sudo);

use lib 't/lib';
use sudosanity;

sudosanity::checks && do {
    my $scalar  = 11;
    my $code = sub { $scalar; };

    is(sudo { $code->() }, 11, "passed variables OK");

    is_deeply(
        [ $Data::Dumper::Deparse, $Data::Dumper::Indent ],
        [ 'lemon curry', 'spam' ],
        "didn't muck about with Data::Dumper globals"
    );
};

END { done_testing }
