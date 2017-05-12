use strict;
use Test::More tests => 10;
use re::engine::PCRE2;

my @w = split /(:)/, "a:b";
is(join("/", @w), "a/:/b", 'split /(:)/, "a:b"');
is(scalar @w, 3, "length 3");

@w = split " ", " foo bar  zar ";
is(join(":", @w), "foo:bar:zar", 'The " " special case: skip white');
is(scalar @w, 3, 'length 3');

# The /^/ special case
@w = split /^/, "a\nb\nc\n";
is(join(":", @w), "a\n:b\n:c\n", 'The /^/ special case');
is(scalar @w, 3, 'length 3');

@w = split /\s+/, "a b  c\t d";
is(join(":", @w), "a:b:c:d", 'The /\s+/ special case');
is(scalar @w, 4, 'length 4');

# / /, not a special case
@w = split / /, " x y ";
is(join(":", @w), ":x:y", '/ / no skip white');
is(scalar @w, 3, 'length 3');
