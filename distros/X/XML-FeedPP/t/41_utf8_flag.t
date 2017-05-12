# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
    local $@;
    eval { require 5.008001; };
    plan skip_all => 'Perl 5.8.1 is required.' if $@;
}
{
    local $@;
    eval { require XML::TreePP; };
    plan skip_all => 'XML::TreePP is not loaded.' if $@;
}
{
    my $ver = ( $XML::TreePP::VERSION =~ /^(\d+\.\d+)/ )[0];
    my $chk = ( $ver >= 0.37 );
    plan skip_all => "XML::TreePP $XML::TreePP::VERSION < 0.37" unless $chk;

    plan tests => 20;
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
            <title>&#xA9;&#169;</title>
        </item>
        <item>
            <title>&#xEB;&#235;</title>
        </item>
        <item>
            <title>&#x3093;&#12435;</title>
        </item>
        <item>
            <title>&#x6F22;&#28450;</title>
        </item>
    </channel>
</rss>
EOT

    my $feedA = XML::FeedPP->new( $rss, xml_deref => 1, utf8_flag => 0 );
    my @itemA = $feedA->get_item;
    is( (scalar @itemA), 4, 'item count' );

    ok( ! utf8::is_utf8($itemA[0]->title), "is_octets: c" );
    ok( ! utf8::is_utf8($itemA[1]->title), "is_octets: e" );
    ok( ! utf8::is_utf8($itemA[2]->title), "is_octets: n" );
    ok( ! utf8::is_utf8($itemA[3]->title), "is_octets: k" );

    is( $itemA[0]->title, "\xC2\xA9" x 2, "string: c" );
    is( $itemA[1]->title, "\xC3\xAB" x 2, "string: e" );
    is( $itemA[2]->title, "\xE3\x82\x93" x 2, "string: n" );
    is( $itemA[3]->title, "\xE6\xBC\xA2" x 2, "string: k" );

    my $feedB = XML::FeedPP->new( $rss, xml_deref => 1, utf8_flag => 1 );
    my @itemB = $feedB->get_item;
    is( (scalar @itemB), 4, 'item count' );

    ok( utf8::is_utf8($itemB[0]->title), "is_utf8: c" );
    ok( utf8::is_utf8($itemB[1]->title), "is_utf8: e" );
    ok( utf8::is_utf8($itemB[2]->title), "is_utf8: n" );
    ok( utf8::is_utf8($itemB[3]->title), "is_utf8: k" );

    is( $itemB[0]->title, chr(0x00A9) x 2, "string: c" );
    is( $itemB[1]->title, chr(0x00EB) x 2, "string: e" );
    is( $itemB[2]->title, chr(0x3093) x 2, "string: n" );
    is( $itemB[3]->title, chr(0x6F22) x 2, "string: k" );
}
# ----------------------------------------------------------------
