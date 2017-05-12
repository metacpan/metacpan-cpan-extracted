# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
    local $@;
    eval { require JSON::Syck; };
    plan skip_all => 'JSON::Syck is not loaded.' if $@;
    plan tests => 30;
    use_ok('XML::FeedPP');
    ok( defined $JSON::Syck::VERSION, "JSON::Syck $JSON::Syck::VERSION" );
}
# ----------------------------------------------------------------
    my $FEED_LIST = [qw(
        t/example/index-e.rdf  t/example/index-j.rdf
    )];
    my $UTF8_FLAG = undef;
    &test_main();
# ----------------------------------------------------------------
sub __decode_json {
    my $json = shift;
    1 if defined $JSON::Syck::ImplicitUnicode;          # dummy
    local $JSON::Syck::ImplicitUnicode = $UTF8_FLAG;
    JSON::Syck::Load($json);
}
# ----------------------------------------------------------------
sub test_main {
    my $tppopt = { utf8_flag => $UTF8_FLAG };
    my $dmpopt = { utf8_flag => $UTF8_FLAG, use_json_pp => 0, use_json_syck => 1 };
    foreach my $file ( @$FEED_LIST ) {
        my $feed = XML::FeedPP::RDF->new( $file, %$tppopt );
        ok( ref $feed, $file );

        my $title1 = $feed->title();
        like( $title1, qr/kawa.net/i, 'feed channel title is valid' );
        ok( ! utf8::is_utf8($title1), 'feed channel title is not utf8' );

        my $item = $feed->get_item(0);
        my $title2 = $item->title();
        like( $title2, qr/\S/i, 'feed item title is valid' );
        ok( ! utf8::is_utf8($title2), 'feed item title is not utf8' );

        my $json = $feed->call( DumpJSON => '', %$dmpopt );
        like( $json, qr/kawa.net/i, 'DumpJSON is valid' );
        ok( ! utf8::is_utf8($json), 'DumpJSON is not utf8' );

        my $data = __decode_json( $json );
        ok( ref $data, 'decode json' );

        my $title3 = $data->{'rdf:RDF'}->{channel}->{title};
        like( $title3, qr/kawa.net/i, 'json channel title is valid' );
        ok( ! utf8::is_utf8($title3), 'json channel title is not utf8' );

        my $title4 = $data->{'rdf:RDF'}->{item}->[0]->{title};
        like( $title4, qr/\St/i, 'json item title is valid' );
        ok( ! utf8::is_utf8($title4), 'json item title is not utf8' );

        is( $title3, $title1, 'same channel title' );
        is( $title4, $title2, 'same item title' );
    }
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
