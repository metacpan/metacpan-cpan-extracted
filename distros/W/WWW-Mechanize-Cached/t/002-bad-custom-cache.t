use strict;
use warnings FATAL => 'all';

use Test::More;
use WWW::Mechanize::Cached ();

BEGIN {
    eval "use Test::Warn";
    plan skip_all => "Test::Warn required for testing invalid cache parms"
        if $@;
}

my $mech;

warning_like {
    $mech = WWW::Mechanize::Cached->new(
        cache     => { parm => 73 },
        autocheck => 1
    );
}
qr/cache param/, "Threw the right warning";

isa_ok(
    $mech, "WWW::Mechanize::Cached",
    "Even with a bad cache, still return a valid object"
);

done_testing();
