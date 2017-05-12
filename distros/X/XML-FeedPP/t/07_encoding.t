# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 4;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
SKIP: {
    my $rss = XML::FeedPP::RSS->new();
    like( $rss->to_string( "UTF-8" ), 
          qr/<\?xml[^>]+encoding="UTF-8"/i, "RSS w/UTF-8" );

    eval { require Encode; };
    eval { require Jcode; } if ! defined $Encode::VERSION;
    if ( ! defined $Encode::VERSION && ! defined $Jcode::VERSION ) {
        skip( "Encode.pm or Jcode.pm is required: Shift_JIS", 2 );
    }

    my $atom = XML::FeedPP::Atom->new();
    like( $atom->to_string( "Shift_JIS" ), 
          qr/<\?xml[^>]+encoding="Shift_JIS/i, "Atom w/Shift_JIS" );

    if ( ! defined $Encode::VERSION ) {
        skip( "Encode.pm is required: ISO-8859-1", 1 );
    }

    my $rdf = XML::FeedPP::RDF->new();
    like( $rdf->to_string( "ISO-8859-1" ), 
          qr/<\?xml[^>]+encoding="ISO-8859-1"/i, "RDF w/ISO-8859-1" );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
