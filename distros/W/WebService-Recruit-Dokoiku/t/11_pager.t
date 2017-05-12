# ----------------------------------------------------------------
    use strict;
    use Test::More;
    use utf8;
# ----------------------------------------------------------------
{
    my $key = $ENV{DOKOIKU_API_KEY} if exists $ENV{DOKOIKU_API_KEY};
    plan skip_all => 'set DOKOIKU_API_KEY env to test this' unless $key;

    eval { require Data::Page; } unless defined $Data::Page::VERSION;
    plan skip_all => 'Data::Page is not loaded.' unless defined $Data::Page::VERSION;

    plan tests => 53;
    use_ok('WebService::Recruit::Dokoiku');
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

    my $doko = WebService::Recruit::Dokoiku->new();
    $doko->key( $key );
    $doko->pagesize( $size );

    my $param = {
        keyword     =>  'ATM',
        lat_jgd     =>  '35.6686',
        lon_jgd     =>  '139.7593',
        pagenum     =>  $page,
        radius      =>  1000,
    };
    my $res = $doko->searchPOI( %$param );
    ok( ref $res, "searchPOI" );

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

    my $hash = $res->page_param( $pager->next_page );
    is( $hash->{pagenum},  $page+1, "$disp page_param pagenum" );
    is( $hash->{pagesize}, $size,   "$disp page_param pagesize" );

    my $query = $res->page_query( $pager->first_page );
    like( $query, qr/ pagenum=1 /x,      "$disp page_query pagenum" );
    like( $query, qr/ pagesize=$size /x, "$disp page_query pagesize" );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
