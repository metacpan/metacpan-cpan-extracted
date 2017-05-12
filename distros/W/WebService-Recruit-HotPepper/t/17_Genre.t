# ----------------------------------------------------------------
    use strict;
    use Test::More;
    use utf8;
# ----------------------------------------------------------------
{
    my $key = $ENV{HOTPEPPER_API_KEY} if exists $ENV{HOTPEPPER_API_KEY};
    plan skip_all => 'set HOTPEPPER_API_KEY env to test this' unless $key;
    plan tests => 9;
    &test_main( $key );
}
# ----------------------------------------------------------------
sub test_main {
    my $key = shift;

    use_ok('WebService::Recruit::HotPepper');
    my $api = WebService::Recruit::HotPepper->new();
    $api->key( $key );

    my $res = $api->Genre();
    ok ref $res;

    my $root = $res->root;
    ok ref $root;

    ok( $root->NumberOfResults, 'NumberOfResults' );
    ok( $root->APIVersion, 'APIVersion' );

    ok ref $root->Genre->[0];
    ok $root->Genre->[0]->GenreCD;
    ok $root->Genre->[0]->GenreName;
    is $@, '';
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
