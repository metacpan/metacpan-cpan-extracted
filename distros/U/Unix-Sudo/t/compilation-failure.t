use strict;
use warnings;
use Test::More;

use Unix::Sudo qw(sudo);

use lib 't/lib';
use sudosanity;

sudosanity::checks && do {
    my($file, $line) = (__FILE__, 1 + __LINE__);
    eval { sudo { non_existent() }};
    like(
        $@,
        qr/Your code didn't compile.* at $file line $line\b/,
        "Uncompilable code dies correctly"
    );
};

END { done_testing }
