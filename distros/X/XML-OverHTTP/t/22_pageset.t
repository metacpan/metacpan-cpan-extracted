# ----------------------------------------------------------------
    use strict;
    use Test::More;
    require 't/MyAPI_env.pm.testing';
# ----------------------------------------------------------------
SKIP: {
    local $@;
    eval { require Data::Pageset; } unless defined $Data::Pageset::VERSION;
    if ( ! defined $Data::Pageset::VERSION ) {
        plan skip_all => 'Data::Pageset is not loaded.';
    }
    plan tests => 11;
    use_ok('XML::OverHTTP');

    my $api = MyAPI_env->new();
    ok( ref $api, 'api' );

#   my $ppset = 20;
    my $pager = $api->pageset();
    ok( ref $pager, 'page' );

    is( $pager->first_page,  1,  'first_page' );
    is( $pager->last_page,   1,  'last_page' );
    is( $pager->first,       1,  'first' );
    is( $pager->last,        1,  'last' );
    ok( ! defined $pager->previous_page, 'previous_page' );
    ok( ! defined $pager->next_page,     'next_page' );
#   is( $pager->pages_per_set, $ppset, 'pages_per_set' );
    ok( ! defined $pager->previous_set, 'previous_set' );
    ok( ! defined $pager->next_set,     'next_set' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
