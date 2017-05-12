# ----------------------------------------------------------------
    use strict;
    use Test::More;
    require 't/MyAPI_env.pm.testing';
# ----------------------------------------------------------------
SKIP: {
    local $@;
    eval { require Data::Page; } unless defined $Data::Page::VERSION;
    if ( ! defined $Data::Page::VERSION ) {
        plan skip_all => 'Data::Page is not loaded.';
    }
    plan tests => 10;
    use_ok('XML::OverHTTP');

    my $api = MyAPI_env->new();
    ok( ref $api, 'api' );

    my $pager = $api->page;
    ok( ref $pager, 'page' );

    is( $pager->first_page,  1,  'first_page' );
    is( $pager->last_page,   1,  'last_page' );
    is( $pager->first,       1,  'first' );
    is( $pager->last,        1,  'last' );
    ok( ! $pager->previous_page, 'previous_page' );
    ok( ! $pager->next_page,     'next_page' );
    is( $pager->skipped,     0,  'skipped' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
