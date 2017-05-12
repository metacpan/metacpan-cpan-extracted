use warnings;
use strict;
use Test::More;

BEGIN {
    eval "use Test::Warn";
    plan skip_all => "Test::Warn required to test warn" if $@;
    plan tests => 6;
}

BEGIN {
    use FindBin;

    use lib "$FindBin::Bin/lib";
    use_ok( 'WWW::Mechanize::Pluggable' );
}

my $m = WWW::Mechanize::Pluggable->new;
isa_ok( $m, 'WWW::Mechanize::Pluggable' );

warning_like {
    $m->warn( "Something bad" );
} qr[Something bad.+line \d+], "Passes the message, and includes the line number";

warning_like {
    $m->quiet(1);
    $m->warn( "Something bad" );
} undef, "Quiets correctly";

my $hushed = WWW::Mechanize::Pluggable->new( quiet => 1 );
isa_ok( $hushed, "WWW::Mechanize::Pluggable" );
warning_like {
    $hushed->warn( "Something bad" );
} undef, "Quiets correctly";
