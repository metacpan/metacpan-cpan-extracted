# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 13;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
{
    my $source = <<'EOT';
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
  <channel>
    <title>sample channel</title>
    <title xmlns="http://search.yahoo.com/mrss/">sample channel</title>
    <link>http://www.example.com/</link>
    <description>sample channel</description>
    <item>
      <guid isPermaLink="true">http://www.example.com/sample1.html</guid>
      <link>http://www.example.com/sample1.html</link>
      <title xmlns="http://search.yahoo.com/mrss/">sample item #1</title>
      </item>
    <item>
      <guid isPermaLink="true">http://www.example.com/sample2.html</guid>
      <link>http://www.example.com/sample2.html</link>
      <title>sample item #2 A</title>
      <title>sample item #2 B</title>
    </item>
    <item>
      <guid isPermaLink="true">http://www.example.com/sample3.html</guid>
      <link>http://www.example.com/sample3.html</link>
      <title>sample item #3 A</title>
      <title xmlns="http://search.yahoo.com/mrss/">sample item #3 B</title>
    </item>
  </channel>
</rss>
EOT
    &test_main( $source );
}
# ----------------------------------------------------------------
sub test_main {
    my $source = shift;
    my $feed = XML::FeedPP->new( $source );

    my $ftitle = $feed->title;
    is( $ftitle, 'sample channel', 'feed title' );
    my @ftitles = $feed->title;
    is( (scalar @ftitles), 2, 'num of feed titles' );

    my $item1 = $feed->get_item( 0 );
    my $ititle1 = $item1->title;
    is( $ititle1, 'sample item #1', '1: item title with xmlns' );
    my @ititles1 = $item1->title;
    is( (scalar @ititles1), 1, '1: num of item titles' );

    my $item2 = $feed->get_item( 1 );
    my $ititle2 = $item2->title;
    is( $ititle2, 'sample item #2 A', '2: item title by array' );
    my @ititles2 = $item2->title;
    is( (scalar @ititles2), 2, '2: num of item titles' );
    is( $ititles2[0], 'sample item #2 A', '2A: item title' );
    is( $ititles2[1], 'sample item #2 B', '2B: item title' );

    my $item3 = $feed->get_item( 2 );
    my $ititle3 = $item3->title;
    is( $ititle3, 'sample item #3 A', '3: item title with xmlns by array' );
    my @ititles3 = $item3->title;
    is( (scalar @ititles3), 2, '3: num of item titles' );
    is( $ititles3[0], 'sample item #3 A', '3A: item title' );
    is( $ititles3[1], 'sample item #3 B', '3B: item title with xmlns' );
}
# ----------------------------------------------------------------
