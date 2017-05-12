# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 14;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    &test_main();
# ----------------------------------------------------------------
sub test_main {
    my $feed = XML::FeedPP::RSS->new();

    my $link0 = 'http://www.example.com/';
    my $link1 = 'http://www.example.com/sample1.html';
    my $link2 = 'http://www.example.com/sample2.html';
    my $link3 = 'http://www.example.com/sample3.html';
    my $title0 = 'sample channel';
    my $title1 = 'sample item 1';
    my $title2 = 'sample item 2';
    my $title3 = 'sample item 3';

    $feed->title( $title0 );
    is( $feed->title, $title0, 'feed title' );

    $feed->link( $link0 );
    is( $feed->link, $link0, 'feed link' );

    # default when missing
    my $item1 = $feed->add_item( $link1 );
    is( $item1->link, $link1, 'item 1 link' );
    $item1->guid( $link1 );
    is( $item1->guid, $link1, 'guid without arguments' );
    is( $item1->{guid}->{-isPermaLink}, 'true', 'isPermaLink without arguments' );

    # old behavior
    my $item2 = $feed->add_item( $link2 );
    is( $item2->link, $link2, 'item 2 link' );
    $item2->guid( $link2, 'false' );
    is( $item2->guid, $link2, 'guid with an argument' );
    is( $item2->{guid}->{-isPermaLink}, 'false', 'isPermaLink with an argument' );

    # documented behavior
    my $item3 = $feed->add_item( $link3 );
    is( $item3->link, $link3, 'item 3 link' );
    $item3->guid( $link3, isPermaLink => 'false' );
    is( $item3->guid, $link3, 'guid with an argument' );
    is( $item3->{guid}->{-isPermaLink}, 'false', 'isPermaLink with arguments' );

    my $out = $feed->to_string();
    my $cnt = {};
    while ( $out =~ m#<guid isPermaLink="(\w+)">#g ) {
        $cnt->{$1} ||= 0;
        $cnt->{$1} ++;
    }
    is( $cnt->{true},  1, 'isPermaLink true 1' );
    is( $cnt->{false}, 2, 'isPermaLink false 2' );
}
# ----------------------------------------------------------------
