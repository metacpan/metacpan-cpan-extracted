use warnings;
use strict;
use Test::More;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception required to test die" if $@;
    plan tests => 5;
}

BEGIN {
    use FindBin;

    use lib "$FindBin::Bin/lib";
    use_ok( 'WWW::Mechanize::Pluggable' );
}


CHECK_DEATH: {
    my $m = WWW::Mechanize::Pluggable->new;
    isa_ok( $m, 'WWW::Mechanize::Pluggable' );

    dies_ok {
        $m->die( "OH NO!  ERROR!" );
    } "Expecting to die";
}

CHECK_LIVING: {
    my $m = WWW::Mechanize::Pluggable->new( onerror => undef );
    isa_ok( $m, 'WWW::Mechanize::Pluggable' );

    lives_ok {
        $m->die( "OH NO!  ERROR!" );
    } "Expecting to die";
}
