# ----------------------------------------------------------------
    use strict;
    use Test::More;
    use utf8;
# ----------------------------------------------------------------
{
    my $key = $ENV{HOTPEPPER_API_KEY} if exists $ENV{HOTPEPPER_API_KEY};
    plan skip_all => 'set HOTPEPPER_API_KEY env to test this' unless $key;

    eval { require Data::Page; } unless defined $Data::Page::VERSION;
    plan skip_all => 'Data::Page is not loaded.' unless defined $Data::Page::VERSION;

    plan tests => 53;
    use_ok('WebService::Recruit::HotPepper');
    &test_main( $key,  1,  10, 1);
    &test_main( $key,  11, 10, 2);
    &test_main( $key,  41, 20, 3);
    &test_main( $key,  5,  10, 1);
}
# ----------------------------------------------------------------
sub test_main {
    my $key   = shift;
    my $start = shift;
    my $count = shift;
    my $is_page = shift;

    my $doko = WebService::Recruit::HotPepper->new();
    $doko->key( $key );
    $doko->Start( $start ) if $start;
    $doko->Count( $count ) if $count;

    my $sa_cd = 'SA11';
    my $param = {
        ServiceAreaCD => $sa_cd,
        Start         => $start,
        Count         => $count,
    };
    my $res = $doko->GourmetSearch( %$param );
    ok( ref $res, "GourmetSearch" );

    my $pager = $res->page;
    ok( ref $pager, "page" );
    my $page = $pager->current_page();

    my $disp = $res->page_query( $page, $count );

    my $total = $pager->total_entries();
    ok( $total, "$disp total" );

    my $prev  = $page - 1 || undef;
    my $first = ($page-1) * $count + 1;
    my $last  = $page * $count;
    $last = $total if ( $last > $total );

    is( $pager->current_page,     $is_page, "$disp current_page" );
    is( $pager->entries_per_page, $count,   "$disp entries_per_page" );
    is( $pager->first_page,       1,        "$disp first_page" );
    is( $pager->first,            $first,   "$disp first" );
    is( $pager->last,             $last,    "$disp last" );
    is( $pager->previous_page,    $prev,    "$disp previous_page" );

    my $hash = $res->page_param( $pager->next_page );
    if( $start eq '5' ){
        is( $hash->{Start},  11, "$disp page_param pagenum" );
    }else{
        is( $hash->{Start},  $start + $count, "$disp page_param pagenum" );
    }
    is( $hash->{Count}, $count,   "$disp page_param pagesize" );

    my $query = $res->page_query( $pager->first_page );
    like( $query, qr/ Start=1 /x,      "$disp page_query pagenum" );
    like( $query, qr/ Count=$count /x, "$disp page_query pagesize" );
}
# ----------------------------------------------------------------
1;
# ----------------------------------------------------------------
