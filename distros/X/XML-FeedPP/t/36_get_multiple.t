# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 13;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
{
    my $rss = <<'EOT';
<rss version="2.0" xmlns:test="http://example.com/">
    <channel>
        <item test:iii="III">
            <test:aaa>AAA</test:aaa>
        </item>
        <item>
            <test:bbb ccc="CCC">BBB</test:bbb>
        </item>
        <item>
            <test:ddd eee="EEE" />
        </item>
        <item>
            <test:fff>FFF0</test:fff>
            <test:fff/>
            <test:fff ggg="GGG" />
            <test:fff hhh="HHH">FFF3</test:fff>
        </item>
    </channel>
</rss>
EOT
    &test_main( $rss );
}
# ----------------------------------------------------------------
sub test_main {
    my $source = shift;
    my $feed = XML::FeedPP->new( $source );
    ok( $feed, 'TESTING DEFAULT' );

    my $item0 = $feed->get_item( 0 );
    my $val0i = $item0->get( '@test:iii' );
    is( $val0i, 'III', '<item test:iii="III">' );
    my $val0a = $item0->get( 'test:aaa' );
    is( $val0a, 'AAA', '<test:aaa> value' );

    my $item1 = $feed->get_item( 1 );
    my $val1b = $item1->get( 'test:bbb' );
    my $val1c = $item1->get( 'test:bbb@ccc' );
    is( $val1b, 'BBB', '<test:bbb ccc="CCC"> value' );
    is( $val1c, 'CCC', '<test:bbb ccc="CCC"> attr' );

    my $item2 = $feed->get_item( 2 );
    my $val2e = $item2->get( 'test:ddd@eee' );
    is( $val2e, 'EEE', '<test:ddd eee="EEE" /> attr' );

    my $item3 = $feed->get_item( 3 );
    my @val3f = $item3->get( 'test:fff' );
    is( $val3f[0], 'FFF0', '<test:fff> 1st value' );
    is( $val3f[3], 'FFF3', '<test:fff> 4th value' );

    my $val3g = $item3->get( 'test:fff@ggg' );
    is( $val3g, 'GGG', '<test:fff ggg="GGG" /> scalar context' );
    my @val3g = $item3->get( 'test:fff@ggg' );
    is( $val3g[2], 'GGG', '<test:fff ggg="GGG" /> array context' );

    my $val3h = $item3->get( 'test:fff@hhh' );
    is( $val3h, 'HHH', '<test:fff hhh="HHH"> scalar context' );
    my @val3h = $item3->get( 'test:fff@hhh' );
    is( $val3h[3], 'HHH', '<test:fff hhh="HHH"> array context' );
}
# ----------------------------------------------------------------
