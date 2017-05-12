package BadSigDie;

use strict;
use warnings;

# make sure this gets loaded before the compile
BEGIN {
    $SIG{__DIE__} = sub {
        my $error = shift;
        CORE::die($error) if $error =~ /syntax error/i;
        return 'bad sig die';
    };
}

# Unmatched right curly
}

1;
