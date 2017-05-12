# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 24;
    require 't/MyAPI_null.pm.testing';
    require 't/MyAPI_override.pm.testing';
# ----------------------------------------------------------------
{
    my $api = MyAPI_null->new();
    is( $api->http_method, 'GET', 'MyAPI_null http_method' );
    ok( ! $api->is_error, 'MyAPI_null is_error' );
    ok( ! $api->total_entries, 'MyAPI_null total_entries' );
    ok( ! $api->entries_per_page, 'MyAPI_null entries_per_page' );
    ok( ! $api->current_page, 'MyAPI_null current_page' );
    ok( ref $api->default_param, 'MyAPI_null default_param' );
    is( $api->attr_prefix, '', 'MyAPI_null attr_prefix' );
    ok( ! $api->elem_class, 'MyAPI_null elem_class' );
    ok( ref $api->force_array, 'MyAPI_null force_array' );
    ok( ! $api->query_class, 'MyAPI_null query_class' );
}
# ----------------------------------------------------------------
{
    my $api = MyAPI_override->new();
    is( $api->url, 'MyAPI_override::url', 'MyAPI_override url' );
    is( $api->http_method, 'MyAPI_override::http_method', 'MyAPI_override http_method' );
    is( $api->root_elem, 'MyAPI_override::root_elem', 'MyAPI_override root_elem' );
    is( $api->is_error, 'MyAPI_override::is_error', 'MyAPI_override is_error' );
    is( $api->total_entries, 'MyAPI_override::total_entries', 'MyAPI_override total_entries' );
    is( $api->entries_per_page, 'MyAPI_override::entries_per_page', 'MyAPI_override entries_per_page' );
    is( $api->current_page, 'MyAPI_override::current_page', 'MyAPI_override current_page' );
    ok( ref $api->default_param, 'MyAPI_override default_param ref' );
    ok( $api->default_param->{'MyAPI_override::default_param'}, 'MyAPI_override default_param value' );
    is( $api->attr_prefix, 'MyAPI_override::attr_prefix', 'MyAPI_override attr_prefix' );
    is( $api->elem_class, 'MyAPI_override::elem_class', 'MyAPI_override elem_class' );
    ok( ref $api->force_array, 'MyAPI_override force_array ref' );
    is( $api->force_array->[0], 'MyAPI_override::force_array', 'MyAPI_override force_array value' );
    is( $api->query_class, 'MyAPI_override::query_class', 'MyAPI_override query_class' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
