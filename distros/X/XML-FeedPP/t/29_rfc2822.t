# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 11;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
=rfc2822
obs-zone        =       "UT" / "GMT" /          ; Universal Time
                                                ; North American UT
                                                ; offsets
                        "EST" / "EDT" /         ; Eastern:  - 5/ - 4
                        "CST" / "CDT" /         ; Central:  - 6/ - 5
                        "MST" / "MDT" /         ; Mountain: - 7/ - 6
                        "PST" / "PDT" /         ; Pacific:  - 8/ - 7

   EDT is semantically equivalent to -0400
   EST is semantically equivalent to -0500
   CDT is semantically equivalent to -0500
   CST is semantically equivalent to -0600
   MDT is semantically equivalent to -0600
   MST is semantically equivalent to -0700
   PDT is semantically equivalent to -0700
   PST is semantically equivalent to -0800
=cut
# ----------------------------------------------------------------
{
    my $rfc2822 = {
        '1200000000' => 'Thu, 10 Jan 2008 21:20:00 GMT',
        '1210000000' => 'Mon, 05 May 2008 15:06:40 UT',
        '1220000000' => 'Fri, 29 Aug 2008 08:53:20 EDT',
        '1230000000' => 'Tue, 23 Dec 2008 02:40:00 EST',
        '1240000000' => 'Fri, 17 Apr 2009 20:26:40 CDT',
        '1250000000' => 'Tue, 11 Aug 2009 14:13:20 CST',
        '1260000000' => 'Sat, 05 Dec 2009 08:00:00 MDT',
        '1270000000' => 'Wed, 31 Mar 2010 01:46:40 MST',
        '1280000000' => 'Sat, 24 Jul 2010 19:33:20 PDT',
        '1290000000' => 'Wed, 17 Nov 2010 13:20:00 PST',
    };
    my $w3cdtf = {
        '1200000000' => '2008-01-10T21:20:00Z',
        '1210000000' => '2008-05-05T15:06:40Z',
        '1220000000' => '2008-08-29T08:53:20-04:00',
        '1230000000' => '2008-12-23T02:40:00-05:00',
        '1240000000' => '2009-04-17T20:26:40-05:00',
        '1250000000' => '2009-08-11T14:13:20-06:00',
        '1260000000' => '2009-12-05T08:00:00-06:00',
        '1270000000' => '2010-03-31T01:46:40-07:00',
        '1280000000' => '2010-07-24T19:33:20-07:00',
        '1290000000' => '2010-11-17T13:20:00-08:00',
    };
    foreach my $key ( sort keys %$rfc2822 ) {
        my $input = $rfc2822->{$key};
        my $check = $w3cdtf->{$key};
        my $out   = XML::FeedPP::Util::rfc1123_to_w3cdtf( $input );
        $out =~ s/[\+\-]00:00$/Z/;
        my $name = ( $input =~ /(\w+)$/ )[0];
        is( $out, $check, $name );
    }
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
