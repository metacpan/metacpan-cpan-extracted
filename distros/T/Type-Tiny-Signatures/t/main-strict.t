use Test::More;

use Type::Tiny;
use Type::Tiny::Signatures ':strict';

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
ok ! eval { meeting(epocj => time) };
ok $@;

ok 1 and done_testing;
