
# t/02basic.t

use Test::More tests => 4;

use WWW::CPAN ();

{
    my $c = WWW::CPAN->new();
    isa_ok( $c, 'WWW::CPAN' );

    can_ok( $c, 'fetch_distmeta' );
    can_ok( $c, 'search' );
    can_ok( $c, 'query' );
}

