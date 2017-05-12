# ----------------------------------------------------------------
    use strict;
    use Test::More;
    use utf8;
# ----------------------------------------------------------------
{
    my $key = $ENV{DOKOIKU_API_KEY} if exists $ENV{DOKOIKU_API_KEY};
    plan skip_all => 'set DOKOIKU_API_KEY env to test this' unless $key;
    plan tests => 13;
    &test_main( $key );
}
# ----------------------------------------------------------------
sub test_main {
    my $key = shift;

    use_ok('WebService::Recruit::Dokoiku');
    my $doko = WebService::Recruit::Dokoiku->new();
    $doko->key( $key );

    my $param = {
        name        =>  'リクルート+銀座',
    };
    my $res = $doko->getLandmark( %$param );
    ok( ref $res, 'getLandmark' );

    is( $res->param->name, $param->{name}, 'param name' );

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
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
