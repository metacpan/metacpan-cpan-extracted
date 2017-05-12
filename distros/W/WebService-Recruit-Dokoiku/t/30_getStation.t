# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
    my $key = $ENV{DOKOIKU_API_KEY} if exists $ENV{DOKOIKU_API_KEY};
    plan skip_all => 'set DOKOIKU_API_KEY env to test this' unless $key;
    plan tests => 18;
    &test_main( $key );
}
# ----------------------------------------------------------------
sub test_main {
    my $key = shift;

    use_ok('WebService::Recruit::Dokoiku');
    my $doko = WebService::Recruit::Dokoiku->new();
    $doko->key( $key );

    my $param = {
        lat_jgd     =>   35.6686,
        lon_jgd     =>  139.7593,
    };
    my $res = $doko->getStation( %$param );
    ok( ref $res, 'getStation' );

    is( $res->param->lat_jgd, $param->{lat_jgd}, 'param lat_jgd' );
    is( $res->param->lon_jgd, $param->{lon_jgd}, 'param lon_jgd' );

    my $root = $res->root;
    ok( ref $root, 'root' );

    ok( $root->status ne '',    'status' );
    ok( $root->totalcount,      'totalcount' );
    ok( $root->pagenum,         'pagenum' );

    ok( ref $root->landmark,                'landmark' );
    ok( $root->landmark->[0]->code,         'code' );
    ok( $root->landmark->[0]->name,         'name' );
    ok( $root->landmark->[0]->dokopcurl,    'dokopcurl' );
    ok( $root->landmark->[0]->dokomburl,    'dokomburl' );
    ok( $root->landmark->[0]->dokomapurl,   'dokomapurl' );

    ok( $root->landmark->[0]->lat_jgd,  'lat_jgd' );
    ok( $root->landmark->[0]->lon_jgd,  'lon_jgd' );
    ok( $root->landmark->[0]->lat_tky,  'lat_tky' );
    ok( $root->landmark->[0]->lon_tky,  'lon_tky' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
