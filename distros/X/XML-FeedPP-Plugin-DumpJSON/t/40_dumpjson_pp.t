# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
    plan skip_all => 'JSON.pm is not supported at the moment.' unless exists $ENV{USE_JSON_PP};
    local $@;
    eval { require JSON; };
    plan skip_all => 'JSON.pm is not loaded.' if $@;
    plan tests => 17;
    use_ok('XML::FeedPP');
    ok( defined $JSON::VERSION, "JSON $JSON::VERSION" );
    &test_main();
}
# ----------------------------------------------------------------
sub test_main {
    my $ftitle = "Title of the site";
    my $fdesc  = "Description of the site";
    my $fdate  = "Mon, 02 Jan 2006 03:04:05 +0600";
    my $fright = "Owner of the site";
    my $flink  = "http://www.kawa.net/";
    my $flang  = "ja";

    my $link1  = "http://www.perl.org/";
    my $link2  = "http://use.perl.org/";
    my $title1 = "The Perl Directory - perl.org";
    my $title2 = "use Perl: All the Perl that's Practical to Extract and Report";

    my $feeds = [
        [ 'rss'     =>  XML::FeedPP::RSS->new()  ],
        [ 'rdf:RDF' =>  XML::FeedPP::RDF->new()  ],
        [ 'feed'    =>  XML::FeedPP::Atom->new() ],
    ];

	my $opts = { use_json_syck => 0, use_json_pp => 1 };

    foreach my $pair ( @$feeds ) {
        my( $root, $feed ) = @$pair;
        $feed->title( $ftitle );
        $feed->description( $fdesc );
        $feed->pubDate( $fdate );
        $feed->copyright( $fright );
        $feed->link( $flink );
        $feed->language( $flang );

        my $item1 = $feed->add_item( $link1 );
        $item1->title( $title1 );

        my $item2 = $feed->add_item( $link2 );
        $item2->title( $title2 );

        my $json = $feed->call( DumpJSON => %$opts );
        like( $json, qr/\Q$flink\E/, 'channel link' );
        like( $json, qr/\Q$link1\E/, 'item link 1' );
        like( $json, qr/\Q$link2\E/, 'item link 2' );

        my $data = __decode_json($json);
        ok( ref $data->{$root}, "$root root element" );
        ok( $data->{$root}->{'-xmlns'} || $data->{$root}->{'-version'}, "$root xmlns or version" );
    }
}
# ----------------------------------------------------------------
sub __decode_json {
    my $data = shift;
    my $ver = ( $JSON::VERSION =~ /^([\d\.]+)/ )[0];
    if ( $ver < 1.99 ) {
		my $json = JSON->new();
		return $json->jsonToObj($data);
	}
	my $json = JSON->new();
#	$json->allow_singlequote(1);
#	$json->relaxed();
	$json->decode($data);
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
