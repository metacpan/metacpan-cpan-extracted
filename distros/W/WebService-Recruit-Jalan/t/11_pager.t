# ----------------------------------------------------------------
    use strict;
    use Test::More;
    use utf8;
# ----------------------------------------------------------------
{
    my $key = $ENV{JALAN_API_KEY} if exists $ENV{JALAN_API_KEY};
    plan skip_all => 'set JALAN_API_KEY env to test this' unless $key;

    eval { require Data::Page; } unless defined $Data::Page::VERSION;
    plan skip_all => 'Data::Page is not loaded.' unless defined $Data::Page::VERSION;

    plan tests => 37;
    use_ok('WebService::Recruit::Jalan');
    &test_main( $key,  5, 4 );
    &test_main( $key, 10, 3 );
    &test_main( $key, 15, 2 );
    &test_main( $key, 20, 1 );
}
# ----------------------------------------------------------------
sub test_main {
    my $key  = shift;
    my $size = shift;
    my $page = shift;

    my $jalan = WebService::Recruit::Jalan->new();
    $jalan->key( $key );

    my $start = ($page-1) * $size + 1;
    my $param = {
        l_area  =>  '162600',
        start   =>  $start,
        count   =>  $size,
    };
    my $res = $jalan->HotelSearchLite( %$param );
    ok( ref $res, 'HotelSearchLite' );
#   warn $res->xml;

    my $pager = $res->page;
    ok( ref $pager, "page" );

    my $disp = $res->page_query( $page, $size );

    my $total = $pager->total_entries();
    ok( $total, "$disp total" );

    my $prev  = $page - 1 || undef;
    my $first = ($page-1) * $size + 1;
    my $last  = $page * $size;
    $last = $total if ( $last > $total );

    is( $pager->current_page,     $page,  "$disp current_page" );
    is( $pager->entries_per_page, $size,  "$disp entries_per_page" );
    is( $pager->first_page,       1,      "$disp first_page" );
    is( $pager->first,            $first, "$disp first" );
    is( $pager->last,             $last,  "$disp last" );
    is( $pager->previous_page,    $prev,  "$disp previous_page" );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
