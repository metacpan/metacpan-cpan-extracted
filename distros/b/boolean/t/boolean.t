use Test::More tests => 61;
use strict;
use lib 'lib';

use boolean ':all';

ok true, 'true is defined and works';
ok !false, 'false is defined and works';
ok not(false), 'false works with not()';
ok not(not(true)), 'true works with not()';

ok isTrue(true), "isTrue works with true";
ok isFalse(false), "isFalse works false";

ok not(isTrue(false)), "isTrue not true with false";
ok not(isFalse(true)), "isFalse not true with true";

ok isBoolean(true), 'true isBoolean';
ok isBoolean(false), 'false isBoolean';

ok not(isBoolean(undef)), 'undef is not Boolean';
ok not(isBoolean("")), '"" is not Boolean';
ok not(isBoolean(0)), '0 is not Boolean';
ok not(isBoolean(1)), '1 is not Boolean';

ok true eq true, 'true eq true';
ok true == true, 'true == true';

ok false eq false, 'false eq false';
ok false == false, 'false == false';

ok not(true) == false, 'not(true) == false';
ok not(false) == true, 'not(false) == true';

ok !(true) == false, '!(true) == false';
ok !(false) == true, '!(false) == true';

ok isBoolean(isFalse(isFalse(undef))), 'boolean return values are boolean';
ok isBoolean(not(true)), 'not boolean returns boolean';
ok isBoolean(!(false)), '! boolean returns boolean';

# Test true in various contexts
my $t = true;

is ref($t), 'boolean', "ref(true) eq 'boolean'";

is "$t", "1", "true stringifies to '1'";

my $t1 = $t ? "true" : "false";
is $t1, "true", "Ternary works with true";

my $t2;
if ($t) {
    $t2 = "true";
}
else {
    $t2 = "false";
}
is $t2, "true", "'if' works with true";

ok $t eq 1, 'true eq 0';
ok $t == 1, 'true == 0';

# Test false in various contexts
my $f = false;

ok $f eq false, '$f eq false';
ok $f == false, '$f == false';

is ref($f), 'boolean', "ref(true) eq 'boolean'";

is "$f", "0", "false stringifies to '0'";

my $f1 = $f ? "true" : "false";
is $f1, "false", "Ternary works with false";

my $f2;
if ($f) {
    $f2 = "true";
}
else {
    $f2 = "false";
}
is $f2, "false", "'if' works with false";

ok $f eq 0, 'false eq 0';
ok $f == 0, 'false == 0';

# boolean()
eval "boolean()";
like $@, qr/Not enough arguments for boolean::boolean/,
    "boolean() has too few args (prototyped)";
eval "&boolean()";
like $@, qr/Not enough arguments for boolean::boolean/,
    "&boolean() has too few args (unprototyped)";
eval "boolean(1,2,3)";
like $@, qr/Too many arguments for boolean::boolean/,
    "boolean(1,2,3) has too many args (prototyped)";
eval "&boolean(1,2,3)";
like $@, qr/Too many arguments for boolean::boolean/,
    "&boolean(1,2,3) has too many args (unprototyped)";

my @t = (0);
ok isBoolean(boolean(42)), "boolean() returns boolean";
ok isBoolean(boolean(undef)), "boolean() works with undef";
ok isBoolean(boolean(())), "boolean works with ()";
ok isBoolean(boolean((0))), "boolean works with ()";
ok isBoolean(boolean(@t)), "boolean works with ()";

ok isTrue(boolean(42)), "boolean(42) isTrue";
ok isFalse(boolean(undef)), "boolean(undef) isFalse";
ok isFalse(boolean(())), "boolean(()) isFalse";
ok isFalse(boolean((0))), "boolean((0)) isFalse";
ok isFalse(boolean((1, 0))), "boolean((1, 0)) isFalse";
ok isTrue(boolean((0, 1))), "boolean((1, 0)) isTrue";
ok isTrue(boolean(@t)), "boolean on array with one false value isTrue";

# Other stuff
eval 'true(1)'; ok $@, "Can't pass values to true/false";
eval 'true(@main::array)'; ok $@, "Can't pass values to true/false";
eval 'true(())'; ok $@, "Can't pass values to true/false";
eval 'false(undef)'; ok $@, "Can't pass values to true/false";

ok true->isTrue, "true isTrue";
ok false->isFalse, "false isFalse";
