# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 28;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $top  = "http://www.kawa.net/";
    my $links = [qw(
        http://www.kawa.net/xp/index-e.html
        http://www.kawa.net/xp/index-j.html
        http://kawa.at.webry.info/
        http://www.flickr.com/photos/u-suke/
    )];
# ----------------------------------------------------------------
    my $feeds = [
        XML::FeedPP::RSS->new(),
        XML::FeedPP::RDF->new(),
        XML::FeedPP::Atom->new(),
    ];
# ----------------------------------------------------------------
    foreach my $feed ( @$feeds ) {
        my $type = ref $feed;
        $feed->link( $top );
        foreach my $link ( @$links ) {
            $feed->add_item( $link );
        }
        my $cnt = scalar @$links;
        is( scalar $feed->get_item(), $cnt, "$type count $cnt" );

        my $remove1 = $feed->remove_item( 1 );
        is( $remove1->link(), $links->[1], "$type remove_item by num 1" );
        is( scalar $feed->get_item(), --$cnt, "$type count $cnt" );

        my $remove2 = $feed->remove_item( $links->[2] );
        is( $remove2->link(), $links->[2], "$type remove_item by link" );
        is( scalar $feed->get_item(), --$cnt, "$type count $cnt" );

        my $remove3 = $feed->remove_item( -1 );
        is( $remove3->link(), $links->[3], "$type remove_item by num -1" );
        is( scalar $feed->get_item(), --$cnt, "$type count $cnt" );

        my $rest = $feed->get_item(0);
        is( $rest->link(), $links->[0], "$type item rest" );
    }
# ----------------------------------------------------------------
    my $rdf = $feeds->[1];
    my $rdfli = $rdf->{'rdf:RDF'}->{channel}->{items}->{'rdf:Seq'}->{'rdf:li'};
    is( ref $rdfli, "ARRAY", "RDF rdf:li ARRAY" );
    is( scalar @$rdfli, 1, "RDF rdf:li count" );
    is( $rdfli->[0]->{'-rdf:resource'}, $links->[0], "RDF rdf:li link" );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
