use Test;
BEGIN { plan tests => 29 }

use XML::NodeFilter qw(:all);


# simple construction
my $filter = XML::NodeFilter->new();
ok($filter);

ok( $filter->what_to_show, SHOW_ALL );

my %show = $filter->what_to_show;

map { ok( $show{$_} == 1 ? 1 : 0 ) } ( keys %show );

$filter->what_to_show( SHOW_ELEMENT => 1, SHOW_TEXT => 1 );

%show = $filter->what_to_show;
map { ok(1) if $show{$_} == 1 } ( keys %show );

$filter->what_to_show( undef );
ok( $filter->what_to_show, SHOW_ALL );

$filter->what_to_show( SHOW_NONE );
ok( $filter->what_to_show, SHOW_NONE );


$filter->what_to_show( SHOW_ELEMENT | SHOW_TEXT );

my $showme = $filter->what_to_show;
%show = $filter->what_to_show;
map { ok(1) if $show{$_} == 1 } ( keys %show );

$filter->what_to_show( SHOW_ELEMENT | SHOW_TEXT | SHOW_NONE );

%show = $filter->what_to_show;
map { ok(1) if $show{$_} == 1 } ( keys %show );

my $tv = $filter->what_to_show;
ok( $tv, $showme );

ok( $filter->accept_node(), FILTER_ACCEPT );
ok( $filter->acceptNode(), FILTER_ACCEPT );

my $filter2 = XML::NodeFilter->new( -show => SHOW_ELEMENT | SHOW_TEXT );
$tv = $filter2->what_to_show;
ok( $tv, $showme );
ok( not defined $filter2->{-show} );

my $filter3 =  XML::NodeFilter->new( -show => {SHOW_ELEMENT=>1, SHOW_TEXT=>1} );

$tv = $filter3->what_to_show;
ok( $tv, $showme );
ok( not defined $filter3->{-show} );

