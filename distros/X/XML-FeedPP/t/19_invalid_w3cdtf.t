# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 11;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $map = {
        # valid - http://www.w3.org/TR/NOTE-datetime
        "2001-02-03"                    =>  "2001-02-03T00:00:00Z",
        "2002-03-04T05:06Z"             =>  "2002-03-04T05:06:00Z",
        "2003-04-05T06:07+08:30"        =>  "2003-04-05T06:07:00+08:30",
        "2004-05-06T07:08:09Z"          =>  "2004-05-06T07:08:09Z",
        "2005-06-07T08:09:10-11:30"     =>  "2005-06-07T08:09:10-11:30",
        "2006-07-08T09:10:11.12Z"       =>  "2006-07-08T09:10:11Z",
        "2007-08-09T10:11:12.13+14:30"  =>  "2007-08-09T10:11:12+14:30",
        # invalid - http://portal.nifty.com/rss/headline.rdf
        "2000-01-02T03:04:05:+09:00"    =>  "2000-01-02T03:04:05+09:00",
	# invalid - http://www.cnc.co.jp/news/xml/rss.xml
	"2008-03-24T16:54:33 +0900"     =>  "2008-03-24T16:54:33+09:00",
    };
# ----------------------------------------------------------------
    my $rss = XML::FeedPP::RSS->new();
    foreach my $try ( sort keys %$map ) {
        my $url = "http://www.kawa.net/?date=$try";
        my $item3 = $rss->add_item( $url );
        $item3->pubDate( $try );
    }
    my $xml = $rss->to_string();
    my $rdf = XML::FeedPP::RDF->new();
    $rdf->merge( $xml );
    my $check = {};
    foreach my $item4 ( $rdf->get_item() ) {
        my $url = $item4->link();
        my $try = (split( /=/, $url ))[1];
        next unless defined $map->{$try};
        $check->{$try} ++;
        is( $item4->pubDate(), $map->{$try}, "RSS to RDF: $try" );
    }
    is( (scalar keys %$check), (scalar keys %$map), "RSS to RDF: checked" );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
