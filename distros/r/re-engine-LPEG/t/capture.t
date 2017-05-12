use strict;

use Test::More tests => 18;

use re::engine::LPEG;

unless ("aoeu 420 eek" =~ / {.}{.}{.}{.} %s {[0-9]+} /) {
    fail "didn't match";
} else {
    is($`, "");
    is($', " eek");
    is($&, "aoeu 420", '$&');

    is($1, "a", '$1 = a');
    is($2, "o", '$2 = o');
    is($3, "e", '$3 = e');
    is($4, "u", '$4 = u');
    is($5, "420", '$5 = 420');
    is($6, undef, '$6 = undef');
    is($640, undef, '$640 = undef');
}

unless ("aoeuhtns" =~ /{.}{.}{.}{.}/) {
    fail "didn't match";
} else {
    is($1, "a");
    is($2, "o");
    is($3, "e");
    is($4, "u");
    is($5, undef);
    is($6, undef);
    is($7, undef);
    is($8, undef);
}
