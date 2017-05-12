# ----------------------------------------------------------------
    use strict;
    use Test::More;
    use utf8;
# ----------------------------------------------------------------
{
    my $key = $ENV{DOKOIKU_API_KEY} if exists $ENV{DOKOIKU_API_KEY};
    plan skip_all => 'set DOKOIKU_API_KEY env to test this' unless $key;
    plan tests => 22;
    &test_main( $key );
}
# ----------------------------------------------------------------
sub test_main {
    my $key = shift;

    use_ok('WebService::Recruit::Dokoiku');
    my $doko = WebService::Recruit::Dokoiku->new();
    $doko->key( $key );

    my $param = {
        format      =>  'xml',
        pagesize    =>  '3',
        keyword     =>  'ƒŠƒNƒ‹[ƒg',
        lat_jgd     =>  '35.6686',
        lon_jgd     =>  '139.7593',
        order       =>  '2',
    };
    my $res = $doko->searchPOI( %$param );
    ok( ref $res, 'searchPOI' );

    is( $res->param->format,   $param->{format},   'param format' );
    is( $res->param->pagesize, $param->{pagesize}, 'param pagesize' );

    my $root = $res->root;
    ok( ref $root, 'root' );

    ok( $root->status ne '',    'status' );
    ok( $root->totalcount,      'totalcount' );
    ok( $root->pagenum,         'pagenum' );

    ok( ref $root->poi->[0],            'poi' );
    ok( $root->poi->[0]->code,          'code' );
    ok( $root->poi->[0]->name,          'name' );
    ok( $root->poi->[0]->kana,          'kana' );
    ok( $root->poi->[0]->tel,           'tel' );
    ok( $root->poi->[0]->address,       'address' );
    ok( $root->poi->[0]->stationcode,   'stationcode' );
    ok( $root->poi->[0]->station,       'station' );
    ok( $root->poi->[0]->distance,      'distance' );
    ok( $root->poi->[0]->dokopcurl,     'dokopcurl' );
    ok( $root->poi->[0]->dokomburl,     'dokomburl' );
    ok( $root->poi->[0]->dokomapurl,    'dokomapurl' );
    ok( $root->poi->[0]->reviewrank,    'reviewrank' );
    ok( ref $root->poi->[0]->tag,       'tag' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
