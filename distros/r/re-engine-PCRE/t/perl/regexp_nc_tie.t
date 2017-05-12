use Test::More tests => 12;
use re::engine::PCRE;

"hlagh" =~ /
    (?<a>.)
    (?<b>.)
    (?<a>.)
    .*
    (?<e>$)
/x;

# FETCH
is($+{a}, "h", "FETCH");
is($+{b}, "l", "FETCH");
is($-{a}[0], "h", "FETCH");
is($-{a}[1], "a", "FETCH");

# STORE
eval { $+{a} = "yon" };
ok(index($@, "read-only") != -1, "STORE");

# DELETE
eval { delete $+{a} };
ok(index($@, "read-only") != -1, "DELETE");

# CLEAR
eval { %+ = () };
ok(index($@, "read-only") != -1, "CLEAR");

# EXISTS
ok(exists $+{e}, "EXISTS");
ok(!exists $+{d}, "EXISTS");

# FIRSTKEY/NEXTKEY
is(join('|', sort keys %+), "a|b|e", "FIRSTKEY/NEXTKEY");

# SCALAR
is(scalar(%+), 3, "SCALAR");
is(scalar(%-), 3, "SCALAR");
