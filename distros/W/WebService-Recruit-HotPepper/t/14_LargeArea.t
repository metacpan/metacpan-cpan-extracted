# ----------------------------------------------------------------
    use strict;
    use Test::More;
    use utf8;
# ----------------------------------------------------------------
{
    my $key = $ENV{HOTPEPPER_API_KEY} if exists $ENV{HOTPEPPER_API_KEY};
    plan skip_all => 'set HOTPEPPER_API_KEY env to test this' unless $key;
    plan tests => 10;
    &test_main( $key );
}
# ----------------------------------------------------------------
sub test_main {
    my $key = shift;

    use_ok('WebService::Recruit::HotPepper');
    my $api = WebService::Recruit::HotPepper->new();
    $api->key( $key );

    my $res = $api->LargeArea();
    ok ref $res;

    my $root = $res->root;
    ok ref $root;

    ok( $root->NumberOfResults, 'NumberOfResults' );
    ok( $root->APIVersion, 'APIVersion' );

    ok ref $root->LargeArea->[0];
    ok $root->LargeArea->[0]->LargeAreaCD;
    ok $root->LargeArea->[0]->LargeAreaName;
    ok $root->LargeArea->[0]->ServiceAreaCD;
    is $@, '';
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
