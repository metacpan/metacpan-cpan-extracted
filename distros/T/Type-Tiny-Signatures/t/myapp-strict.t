use lib 't/lib';

use Test::More;

use Type::Tiny;
use Type::Tiny::Signatures ':strict' => qw(MyApp::Types);

fun greeting (AllCaps $name) {
    return "hello, $name";
}

fun meeting (Int :$epoch = time) {
    return "our meeting is at $epoch";
}

is greeting('MARTIAN'), 'hello, MARTIAN';
ok ! eval { greeting('martian') };
ok $@;

is meeting(epoch => time), 'our meeting is at ' . time;
ok ! eval { meeting(epocj => time) };
ok $@;

ok 1 and done_testing;
