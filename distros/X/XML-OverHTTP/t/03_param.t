# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 9;
# ----------------------------------------------------------------
{
    use_ok('XML::OverHTTP');

    my $api = XML::OverHTTP->new( one => 1, two => 2 );
    $api->add_param( five => 5, six => 6 );

    is( $api->get_param( 'one' ), 1, 'get_param 1' );
    is( $api->get_param( 'two' ), 2, 'get_param 2' );
    is( $api->get_param( 'five' ), 5, 'get_param 5' );
    is( $api->get_param( 'six' ), 6, 'get_param 6' );

    my $query = $api->query_string();
    like( $query, qr/one=1/, 'new 1' );
    like( $query, qr/two=2/, 'new 2' );
    like( $query, qr/five=5/, 'add_param 5' );
    like( $query, qr/six=6/, 'add_param 6' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
