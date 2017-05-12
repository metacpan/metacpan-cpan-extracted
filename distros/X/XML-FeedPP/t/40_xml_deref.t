# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
    local $@;
    eval { require XML::TreePP; };
    plan skip_all => 'XML::TreePP is not loaded.' if $@;
}
{
    my $ver = ( $XML::TreePP::VERSION =~ /^(\d+\.\d+)/ )[0];
    my $chk = ( $ver >= 0.37 );
    plan skip_all => "XML::TreePP $XML::TreePP::VERSION < 0.37" unless $chk;

    plan tests => 28;
    ok( $chk, 'XML::TreePP '.$ver );
    use_ok('XML::FeedPP');
    &test_main();
}
# ----------------------------------------------------------------
sub test_main {

    my $rss = <<'EOT';
<rss version="2.0">
    <channel>
        <item>
            <title>&#xA9;</title>
            <description>&#169;</description>
        </item>
        <item>
            <title>&#xEB;</title>
            <description>&#235;</description>
        </item>
        <item>
            <title>&#x3093;</title>
            <description>&#12435;</description>
        </item>
        <item>
            <title>&#x6F22;</title>
            <description>&#28450;</description>
        </item>
    </channel>
</rss>
EOT

    my $feedA = XML::FeedPP->new( $rss, xml_deref => 0 );
    my $cntA = $feedA->get_item;
    is( $cntA, 4, 'item count' );
    foreach my $item ( $feedA->get_item ) {
        my $title = $item->title;
        my $description = $item->description;
        ok( $title ne $description, 'no deref unmatch' );
        like( $title, qr/&#\w+;/, 'no deref title '.$title );
        like( $description, qr/&#\w+;/, 'no deref description '.$description );
    }

    my $feedB = XML::FeedPP->new( $rss, xml_deref => 1 );
    my $cntB = $feedB->get_item;
    is( $cntB, 4, 'item count' );
    foreach my $item ( $feedB->get_item ) {
        my $title = $item->title;
        my $description = $item->description;
        ok( $title eq $description, 'xml_deref match' );
        unlike( $title, qr/&#\w+;/, 'xml_deref title '.$title );
        unlike( $description, qr/&#\w+;/, 'xml_deref description '.$description );
    }
}
# ----------------------------------------------------------------
