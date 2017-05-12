use warnings;
use strict;
use Test::More;

BEGIN {
    eval "use Test::Warn";
    plan skip_all => "Test::Warn required to test warnings" if $@;
    plan tests => 3;
}

BEGIN {
    use FindBin;

    use lib "$FindBin::Bin/lib";
    use_ok( 'WWW::Mechanize::Pluggable' );
}

UNKNOWN_ALIAS: {
    my $m = WWW::Mechanize::Pluggable->new;
    isa_ok( $m, 'WWW::Mechanize::Pluggable' );

    warning_is {
        $m->agent_alias( "Blongo" );
    } 'Unknown agent alias "Blongo"', "Unknown aliases squawk appropriately";
}
