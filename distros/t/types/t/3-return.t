
use strict;
use Test::More tests => 8;
use types;
pass("started");


eval '
sub test1 {
    return 1;
}
my int $int = test1();
';
is($@, "", "int to int works");


eval '
sub test1 {
    1;
}
my int $int = test1();
';
is($@, "", "implicit works");

eval '
sub test1 {
    (1);
}
my int $int = test1();
';
is($@, "", "implicit list works");

eval '
sub test1 {
    return 1.5;
}
';
like($@, qr/Function main::test1 redefined with a different type \(was int now float\)/, "Different return type, illegal");

eval '
sub test2 {
    return "hi";
    return 1;
}
';
like($@, qr/Return type mismatch\: const int at \(.*?\)\:\d+ does not match return value string/, "Different return types, illegal");


eval '
sub test3 {
    return 1;
    return 1;
}
';
is($@,"", "Identical return values, yay!");

eval '
sub retfloat {
    return 1.5;
}
my int $int = retfloat();
';
like($@, qr/mismatch, can\'t sassign float \(main::retfloat\(\)\) to int \(\$int\) at/, "Returns float, cannot assign to int!");
