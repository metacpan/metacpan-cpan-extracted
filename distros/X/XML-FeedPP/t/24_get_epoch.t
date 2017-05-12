# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 27;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $epo0a = time();
    my $rfc1z = [
        'Sun, 21 Jan 2007 22:23:24',
        'Sun, 21 Jan 2007 22:23:24 +09:00',
        'Sun, 14 Jan 2007 13:12:11 +10:30',
        'Sun, 7 Jan 2007 8:09:10 -11:30',
    ];
    my $w3c2z = [
        '2007-01-21T20:19:18Z',
        '2007-01-21T20:19:18+09:00',
        '2007-01-28T12:11:10+09:30',
        '2007-02-04T05:06:07-08:30',
    ];
# ----------------------------------------------------------------
    my $w3c0a = &XML::FeedPP::Util::epoch_to_w3cdtf( $epo0a );
    my $epo0b = &XML::FeedPP::Util::w3cdtf_to_epoch( $w3c0a );
    is( $epo0b, $epo0a, "1: epoch-w3cdtf-epoch    $epo0a" );
# ----------------------------------------------------------------
    my $rfc0a = &XML::FeedPP::Util::epoch_to_rfc1123( $epo0a );
    my $epo0c = &XML::FeedPP::Util::rfc1123_to_epoch( $rfc0a );
    is( $epo0c, $epo0a, "1: epoch-rfc1123-epoch   $epo0a" );
# ----------------------------------------------------------------
    my $cnt = 2;
    foreach my $rfc1a ( @$rfc1z ) {
        my $epo1a = &XML::FeedPP::Util::rfc1123_to_epoch( $rfc1a );
        ok( $epo1a > 0, "$cnt: rfc1123-epoch         $rfc1a" );
        my $rfc1b = &XML::FeedPP::Util::epoch_to_rfc1123( $epo1a );
        my $epo1b = &XML::FeedPP::Util::rfc1123_to_epoch( $rfc1b );
        my $rfc1c = &XML::FeedPP::Util::epoch_to_rfc1123( $epo1b );
        is( $rfc1b, $rfc1c, "$cnt: rfc1123-epoch-rfc1123 $rfc1a" );
        $cnt ++;
    }
# ----------------------------------------------------------------
    foreach my $w3c2a ( @$w3c2z ) {
        my $epo2a = &XML::FeedPP::Util::w3cdtf_to_epoch( $w3c2a );
        ok( $epo2a > 0, "$cnt: w3cdtf-epoch          $w3c2a" );
        my $w3c2b = &XML::FeedPP::Util::epoch_to_w3cdtf( $epo2a );
        my $epo2b = &XML::FeedPP::Util::w3cdtf_to_epoch( $w3c2b );
        my $w3c2c = &XML::FeedPP::Util::epoch_to_w3cdtf( $epo2b );
        is( $w3c2b, $w3c2c, "$cnt: w3cdtf-epoch-w3cdtf   $w3c2a" );
        $cnt ++;
    }
# ----------------------------------------------------------------
    foreach my $rfc3a ( @$rfc1z ) {
        my $w3c3a = &XML::FeedPP::Util::get_w3cdtf( $rfc3a );
        my $epo3a = &XML::FeedPP::Util::get_epoch( $rfc3a );
        my $epo3b = &XML::FeedPP::Util::get_epoch( $w3c3a );
        is( $epo3b, $epo3a, "$cnt: rfc1123/w3cdtf-epoch $rfc3a" );
        $cnt ++;
    }
# ----------------------------------------------------------------
    foreach my $w3c4a ( @$w3c2z ) {
        my $rfc4a = &XML::FeedPP::Util::get_rfc1123( $w3c4a );
        my $epo4a = &XML::FeedPP::Util::get_epoch( $w3c4a );
        my $epo4b = &XML::FeedPP::Util::get_epoch( $rfc4a );
        is( $epo4b, $epo4a, "$cnt: rfc1123/w3cdtf-epoch $w3c4a" );
        $cnt ++;
    }
# ----------------------------------------------------------------


# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
