use lib '.';
use Test::More tests => 2;

eval " use t::Sample::NotStrictError; ";

like(
    "$@",
    qr/^Global symbol "\$var" requires explicit package name/,
    "strict propogates when set_strict(1)"
);

eval " use t::Sample::NotStrict; ";

is( "$@", q{}, "Strict doesn't propogate when set_strict(0)" );

