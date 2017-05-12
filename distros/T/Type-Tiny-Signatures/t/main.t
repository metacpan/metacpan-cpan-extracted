use Test::More;

use Type::Tiny;
use Type::Tiny::Signatures;

fun greeting (Str $name) {
    return "hello, $name";
}

fun meeting (Int :$epoch = time) {
    return "our meeting is at $epoch";
}

is greeting('martian'), 'hello, martian';
ok ! eval { greeting([]) };
ok $@;

is meeting(epoch => time), 'our meeting is at ' . time;
is meeting(epocj => time), 'our meeting is at ' . time;

ok 1 and done_testing;
