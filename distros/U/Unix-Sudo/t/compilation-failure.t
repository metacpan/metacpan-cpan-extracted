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
        qr/Your code died or didn't compile.* at $file line $line\b/,
        "Uncompilable code (call to non-existent sub) dies correctly"
    );

    ### Because we use eval { block } inside sudo() this causes
    ### a compilation error too early to catch. Bother.
    # {
    #     no strict;
    #     eval { sudo { $hlagh = "poing" }};
    #     like(
    #         $@,
    #         qr/Your code died or didn't compile.* at $file line $line\b/,
    #         "Uncompilable code (not strict-safe) dies correctly"
    #     );
    # }

    eval { sudo { 5/0 }};
    like(
        $@,
        qr/Your code died or didn't compile/,
        "Illegal code (divide by zero) dies correctly"
    );

    eval { sudo { die("Eat a bag of ... pineapples") }};
    like(
        $@,
        qr/Your code died or didn't compile/,
        "Dieing code dies correctly"
    );
};

done_testing();
