# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
    plan skip_all => 'JSON.pm is not supported at the moment.' unless exists $ENV{USE_JSON_PP};
    local $@;
    eval { require JSON; };
    plan skip_all => 'JSON.pm is not loaded.' if $@;
    plan tests => 62;
    use_ok('XML::FeedPP');
    ok( defined $JSON::VERSION, "JSON $JSON::VERSION" );
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
#   $json->allow_singlequote(1);
#   $json->relaxed();
    $json->decode($data);
}
# ----------------------------------------------------------------
    my $ftitle = "Title of the site";
    my $fdesc  = "Description of the site";
    my $fright = "Owner of the site";
    my $flink  = "http://www.kawa.net/";
    my $flang  = "ja";
    my $link1  = "http://www.perl.org/";
    my $link2  = "http://use.perl.org/";
    my $title1 = "The Perl Directory - perl.org";
    my $title2 = "use Perl: All the Perl that's Practical to Extract and Report";
# ----------------------------------------------------------------
    my $date110w = "2004-11-09T11:33:20Z";              # 1100000000
    my $date110h = "Tue, 09 Nov 2004 11:33:20 GMT";
    my $date111w = "2005-03-05T14:20:00+09:00";         # 1110000000
    my $date111h = "Sat, 05 Mar 2005 14:20:00 +0900";
    my $date112w = "2005-06-29T08:06:30-09:00";         # 1120000000
    my $date112h = "Wed, 29 Jun 2005 08:06:30 -0900";
# ----------------------------------------------------------------
    my $orig1key = 'kawanet:foo';
    my $orig1val = 'AAA';
    my $orig2key = 'kawanet:foo/kawanet:bar';
    my $orig2val = 'BBB';
    my $orig3key = 'kawanet:hoge@pomu';
    my $orig3val = 'CCC';
    my $mostslim = [ 'link' ];
# ----------------------------------------------------------------
    &test_slim();
    &test_more_slim();
# ----------------------------------------------------------------
sub test_slim {
    my $opt = {};
    $opt->{slim} = 1;
    $opt->{slim_element_add} = [ $orig1key, $orig2key, $orig3key ];
    $opt->{use_json_syck} = 0;
    $opt->{use_json_pp}   = 1;

    my $rssfeed = &init_feed( XML::FeedPP::RSS->new() );
    my $rssjson = $rssfeed->call( DumpJSON => %$opt );
    my $rssslim = __decode_json($rssjson);
    is( $rssslim->{rss}->{channel}->{link},    $flink,    'rss channel link' );
    is( $rssslim->{rss}->{channel}->{title},   $ftitle,   'rss channel title' );
    is( $rssslim->{rss}->{channel}->{pubDate}, $date110h, 'rss channel pubDate' );
    is( $rssslim->{rss}->{channel}->{item}->[0]->{link}, $link1, 'rss item0 link' );
    is( $rssslim->{rss}->{channel}->{item}->[1]->{link}, $link2, 'rss item1 link' );
    is( $rssslim->{rss}->{channel}->{item}->[0]->{title}, $title1, 'rss item0 title' );
    is( $rssslim->{rss}->{channel}->{item}->[1]->{title}, $title2, 'rss item1 title' );
    is( $rssslim->{rss}->{channel}->{item}->[0]->{pubDate}, $date111h, 'rss item0 pubDate' );
    is( $rssslim->{rss}->{channel}->{item}->[1]->{pubDate}, $date112h, 'rss item1 pubDate' );

    my $rdffeed = &init_feed( XML::FeedPP::RDF->new() );
    my $rdfjson = $rdffeed->call( DumpJSON => %$opt );
    my $rdfslim = __decode_json($rdfjson);
    is( $rdfslim->{'rdf:RDF'}->{channel}->{link},      $flink,    'rdf channel link' );
    is( $rdfslim->{'rdf:RDF'}->{channel}->{title},     $ftitle,   'rdf channel title' );
    is( $rdfslim->{'rdf:RDF'}->{channel}->{'dc:date'}, $date110w, 'rdf channel dc:date' );
    is( $rdfslim->{'rdf:RDF'}->{item}->[0]->{link}, $link1, 'rdf item0 link' );
    is( $rdfslim->{'rdf:RDF'}->{item}->[1]->{link}, $link2, 'rdf item1 link' );
    is( $rdfslim->{'rdf:RDF'}->{item}->[0]->{title}, $title1, 'rdf item0 title' );
    is( $rdfslim->{'rdf:RDF'}->{item}->[1]->{title}, $title2, 'rdf item1 title' );
    is( $rdfslim->{'rdf:RDF'}->{item}->[0]->{'dc:date'}, $date111w, 'rdf item0 dc:date' );
    is( $rdfslim->{'rdf:RDF'}->{item}->[1]->{'dc:date'}, $date112w, 'rdf item1 dc:date' );

    my $atomfeed = &init_feed( XML::FeedPP::Atom->new() );
    my $atomjson = $atomfeed->call( DumpJSON => %$opt );
    my $atomslim = __decode_json($atomjson);
    is( $atomslim->{feed}->{link},     $flink,    'atom channel link' );
    is( $atomslim->{feed}->{title},    $ftitle,   'atom channel title' );
    is( $atomslim->{feed}->{modified}, $date110w, 'atom channel modified' );
    is( $atomslim->{feed}->{entry}->[0]->{link}, $link1, 'atom item0 link' );
    is( $atomslim->{feed}->{entry}->[1]->{link}, $link2, 'atom item1 link' );
    is( $atomslim->{feed}->{entry}->[0]->{title}, $title1, 'atom item0 title' );
    is( $atomslim->{feed}->{entry}->[1]->{title}, $title2, 'atom item1 title' );
    is( $atomslim->{feed}->{entry}->[0]->{issued}, $date111w, 'atom item0 issued' );
    is( $atomslim->{feed}->{entry}->[1]->{issued}, $date112w, 'atom item1 issued' );

    is( $rssslim->{rss}->{channel}->{$orig1key},              $orig1val, 'rss channel orig' );
    is( $rssslim->{rss}->{channel}->{item}->[0]->{$orig2key}, $orig2val, 'rss item0 orig' );
    is( $rssslim->{rss}->{channel}->{item}->[1]->{$orig3key}, $orig3val, 'rss item1 orig' );
    is( $rdfslim->{'rdf:RDF'}->{channel}->{$orig1key},   $orig1val, 'rdf channel orig' );
    is( $rdfslim->{'rdf:RDF'}->{item}->[0]->{$orig2key}, $orig2val, 'rdf item0 orig' );
    is( $rdfslim->{'rdf:RDF'}->{item}->[1]->{$orig3key}, $orig3val, 'rdf item1 orig' );
    is( $atomslim->{feed}->{$orig1key},                  $orig1val, 'atom channel orig' );
    is( $atomslim->{feed}->{entry}->[0]->{$orig2key},    $orig2val, 'atom item0 orig' );
    is( $atomslim->{feed}->{entry}->[1]->{$orig3key},    $orig3val, 'atom item1 orig' );

    ok( ! exists $rssslim->{rss}->{'-xmlns'},         'rss channel xmlns' );
    ok( ! exists $rssslim->{rss}->{'-version'},       'rss channel version' );
    ok( ! exists $rdfslim->{'rdf:RDF'}->{'-xmlns'},   'rdf channel xmlns' );
    ok( ! exists $rdfslim->{'rdf:RDF'}->{'-version'}, 'rdf channel version' );
    ok( ! exists $atomslim->{feed}->{'-xmlns'},       'atom channel xmlns' );
    ok( ! exists $atomslim->{feed}->{'-version'},     'atom channel version' );
}
# ----------------------------------------------------------------
sub test_more_slim {
    my $opt = {};
    $opt->{slim_element} = $mostslim;
    $opt->{use_json_syck} = 0;
    $opt->{use_json_pp}   = 1;

    my $rssfeed = &init_feed( XML::FeedPP::RSS->new() );
    my $rssjson = $rssfeed->call( DumpJSON => %$opt );
    my $rssslim = __decode_json($rssjson);
    is( $rssslim->{rss}->{channel}->{link},              $flink, 'rss channel link' );
    is( $rssslim->{rss}->{channel}->{item}->[0]->{link}, $link1, 'rss item0 link' );
    is( $rssslim->{rss}->{channel}->{item}->[1]->{link}, $link2, 'rss item1 link' );
    ok( ! exists $rssslim->{rss}->{channel}->{title},              'rss channel title' );
    ok( ! exists $rssslim->{rss}->{channel}->{item}->[0]->{title}, 'rss item0 title' );
    ok( ! exists $rssslim->{rss}->{channel}->{item}->[1]->{title}, 'rss item1 title' );

    my $rdffeed = &init_feed( XML::FeedPP::RDF->new() );
    my $rdfjson = $rdffeed->call( DumpJSON => %$opt );
    my $rdfslim = __decode_json($rdfjson);
    is( $rdfslim->{'rdf:RDF'}->{channel}->{link},   $flink, 'rdf channel link' );
    is( $rdfslim->{'rdf:RDF'}->{item}->[0]->{link}, $link1, 'rdf item0 link' );
    is( $rdfslim->{'rdf:RDF'}->{item}->[1]->{link}, $link2, 'rdf item1 link' );
    ok( ! exists $rdfslim->{'rdf:RDF'}->{channel}->{title},   'rdf channel title' );
    ok( ! exists $rdfslim->{'rdf:RDF'}->{item}->[0]->{title}, 'rdf item0 title' );
    ok( ! exists $rdfslim->{'rdf:RDF'}->{item}->[1]->{title}, 'rdf item1 title' );

    my $atomfeed = &init_feed( XML::FeedPP::Atom->new() );
    my $atomjson = $atomfeed->call( DumpJSON => %$opt );
    my $atomslim = __decode_json($atomjson);
    is( $atomslim->{feed}->{link},               $flink, 'atom channel link' );
    is( $atomslim->{feed}->{entry}->[0]->{link}, $link1, 'atom item0 link' );
    is( $atomslim->{feed}->{entry}->[1]->{link}, $link2, 'atom item1 link' );
    ok( ! exists $atomslim->{feed}->{title},               'atom channel title' );
    ok( ! exists $atomslim->{feed}->{entry}->[0]->{title}, 'atom item0 title' );
    ok( ! exists $atomslim->{feed}->{entry}->[1]->{title}, 'atom item1 title' );
}
# ----------------------------------------------------------------
sub init_feed {
    my $feed = shift;
    $feed->title( $ftitle );
    $feed->description( $fdesc );
    $feed->pubDate( $date110w );
    $feed->copyright( $fright );
    $feed->link( $flink );
    $feed->language( $flang );

    my $item1 = $feed->add_item( $link1 );
    $item1->title( $title1 );
    $item1->pubDate( $date111w );

    my $item2 = $feed->add_item( $link2 );
    $item2->title( $title2 );
    $item2->pubDate( $date112h );

    $feed->set( $orig1key, $orig1val );
    $item1->set( $orig2key, $orig2val );
    $item2->set( $orig3key, $orig3val );

    $feed;
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
