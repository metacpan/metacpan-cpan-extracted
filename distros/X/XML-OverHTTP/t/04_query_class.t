# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 15;
    require 't/MyAPI_override.pm.testing';
# ----------------------------------------------------------------
{
    use_ok('XML::OverHTTP');

    my $api = MyAPI_override->new( one => 1, two => 2 );
    $api->add_param( five => 5, six => 6 );

    is( $api->param->one,  1, 'get 1' );
    is( $api->param->two,  2, 'get 2' );
    is( $api->param->five, 5, 'get 5' );
    is( $api->param->six,  6, 'get 6' );

	$api->param->one( 11 );
	$api->param->three( 33 );
	$api->param->four( 44 );
	$api->param->six( 66 );

    is( $api->param->one,   11, 'set 11' );
    is( $api->param->three, 33, 'set 33' );
    is( $api->param->four,  44, 'set 44' );
    is( $api->param->six,   66, 'set 66' );

    my $query = $api->query_string();
    like( $query, qr/one=11/, 'query_string 1' );
    like( $query, qr/two=2/, 'query_string 2' );
    like( $query, qr/three=33/, 'query_string 3' );
    like( $query, qr/four=44/, 'query_string 4' );
    like( $query, qr/five=5/, 'query_string 5' );
    like( $query, qr/six=66/, 'query_string 6' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
