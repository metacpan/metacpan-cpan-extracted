# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
    my $key = $ENV{JALAN_API_KEY} if exists $ENV{JALAN_API_KEY};
    plan skip_all => 'set JALAN_API_KEY env to test this' unless $key;
    plan tests => 23;
    &test_main( $key );
}
# ----------------------------------------------------------------
sub test_main {
    my $key = shift;

    use_ok('WebService::Recruit::Jalan');
    my $jalan = WebService::Recruit::Jalan->new();
    $jalan->key( $key );

    my $param = {
        l_area      =>  '010300',
        count       =>  '1',
        xml_ptn     =>  '1',
    };
    my $res = $jalan->OnsenSearch( %$param );
    ok( ref $res, 'OnsenSearch' );
#   warn $res->xml;

    my $root = $res->root;
    ok( ref $root, 'root' );

    ok( $root->NumberOfResults,                 'NumberOfResults' );
    ok( $root->DisplayPerPage,                  'DisplayPerPage' );
    ok( $root->DisplayFrom,                     'DisplayFrom' );
    ok( $root->APIVersion,                      'APIVersion' );
    ok( $root->Onsen,                           'Onsen' );
    ok( $root->Onsen->[0]->OnsenName,           'OnsenName' );
    ok( $root->Onsen->[0]->OnsenNameKana,       'OnsenNameKana' );
    ok( $root->Onsen->[0]->OnsenID,             'OnsenID' );
    ok( $root->Onsen->[0]->OnsenAddress,        'OnsenAddress' );
    ok( $root->Onsen->[0]->Area,                'Area' );
    ok( $root->Onsen->[0]->Area->Region,        'Region' );
    ok( $root->Onsen->[0]->Area->Prefecture,    'Prefecture' );
    ok( $root->Onsen->[0]->Area->LargeArea,     'LargeArea' );
    ok( $root->Onsen->[0]->Area->SmallArea,     'SmallArea' );
    ok( $root->Onsen->[0]->NatureOfOnsen,       'NatureOfOnsen' );
    ok( $root->Onsen->[0]->OnsenAreaName,       'OnsenAreaName' );
    ok( $root->Onsen->[0]->OnsenAreaNameKana,   'OnsenAreaNameKana' );
    ok( $root->Onsen->[0]->OnsenAreaID,         'OnsenAreaID' );
    ok( $root->Onsen->[0]->OnsenAreaURL,        'OnsenAreaURL' );
    ok( $root->Onsen->[0]->OnsenAreaCaption,    'OnsenAreaCaption' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
