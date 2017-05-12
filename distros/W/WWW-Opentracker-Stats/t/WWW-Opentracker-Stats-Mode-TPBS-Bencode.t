# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Opentracker-Stats.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('WWW::Opentracker::Stats::Mode::TPBS::Bencode') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $test_file = "t/stats-tpbs.ben";
my $test_struct = {
    'files' => {
        '5F79508974BA49620532832D75E6BC6F62B47F7B' => {
                                                        'incomplete' => '0',
                                                        'downloaded' => '1',
                                                        'complete' => '2'
                                                      },
        'D8E22D504F182C41C857EE1E5B2B5967FFC77364' => {
                                                        'incomplete' => '0',
                                                        'downloaded' => '1',
                                                        'complete' => '2'
                                                      },
        '9B5827C4C069B67A2E22096DA0B08674A3229099' => {
                                                        'incomplete' => '0',
                                                        'downloaded' => '1',
                                                        'complete' => '1'
                                                      },
        'DF86CE33ADAB5156B582F2005E8B3BDEE920EEB2' => {
                                                        'incomplete' => '0',
                                                        'downloaded' => '3',
                                                        'complete' => '1'
                                                      },
    },
};



{
    local $/ = undef;
    open (my $fd, '<', $test_file) or die "Unable to open file $test_file";
    my $payload = <$fd>;
    close $fd or die "Unable to close file $test_file";

    my $struct = WWW::Opentracker::Stats::Mode::TPBS::Bencode->decode_stats($payload);
    
    is(
        $struct->{'DF86CE33ADAB5156B582F2005E8B3BDEE920EEB2'}{'downloaded'},
        $test_struct->{'DF86CE33ADAB5156B582F2005E8B3BDEE920EEB2'}{'downloaded'}
    );
}


{
    my $empty_stats = "d5:filesdee";
    my $struct      = WWW::Opentracker::Stats::Mode::TPBS::Bencode->decode_stats($empty_stats);

    is(
        scalar keys %{$struct->{'files'}},
        0
    );
}
