# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
    my $key = $ENV{JALAN_API_KEY} if exists $ENV{JALAN_API_KEY};
    plan skip_all => 'set JALAN_API_KEY env to test this' unless $key;
    plan tests => 17;
    &test_main( $key );
}
# ----------------------------------------------------------------
sub test_main {
    my $key = shift;

    use_ok('WebService::Recruit::Jalan');
    my $jalan = WebService::Recruit::Jalan->new();
    $jalan->key( $key );

    my $param = {
        reg     =>  '40',
    };
    my $res = $jalan->AreaSearch( %$param );
    ok( ref $res, 'AreaSearch' );
#   warn $res->xml;

    my $root = $res->root;
    ok( ref $root, 'root' );

    ok( $root->APIVersion,              'APIVersion' );
    ok( $root->Area,                    'Area' );
    ok( $root->Area->Region,                    'Region' );
    ok( $root->Area->Region->[0]->cd,           'Region cd' );
    ok( $root->Area->Region->[0]->name,         'Region name' );
    ok( $root->Area->Region->[0]->Prefecture,                   'Prefecture' );
    ok( $root->Area->Region->[0]->Prefecture->[0]->cd,          'Prefecture cd' );
    ok( $root->Area->Region->[0]->Prefecture->[0]->name,        'Prefecture name' );
    ok( $root->Area->Region->[0]->Prefecture->[0]->LargeArea,               'LargeArea' );
    ok( $root->Area->Region->[0]->Prefecture->[0]->LargeArea->[0]->cd,      'LargeArea cd' );
    ok( $root->Area->Region->[0]->Prefecture->[0]->LargeArea->[0]->name,    'LargeArea name' );
    ok( $root->Area->Region->[0]->Prefecture->[0]->LargeArea->[0]->SmallArea,               'SmallArea' );
    ok( $root->Area->Region->[0]->Prefecture->[0]->LargeArea->[0]->SmallArea->[0]->cd,      'SmallArea cd' );
    ok( $root->Area->Region->[0]->Prefecture->[0]->LargeArea->[0]->SmallArea->[0]->name,    'SmallArea name' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
