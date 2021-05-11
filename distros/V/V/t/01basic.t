#! perl -I.
use t::Test::abeltje;

require_ok( 'V' );

ok( $V::VERSION, '$V::VERSION is there' );

SKIP: {
    local $ENV{PERL5OPT} = -d 'blib' ? '-Mblib' : '-Mlib=lib';
    local *PIPE;
    my $out;
    if ( open PIPE, qq!$^X -MV |! ) {
        $out = do { local $/; <PIPE> };
        unless ( close PIPE ) {
            if ( open PIPE, qq!$^X -I. -e 'use V;' |! ) {
                $out = do { local $/; <PIPE> };
                skip "Error in pipe(2): $! [$?]", 1 unless close PIPE;
            } else {
                skip "Could not fork: $!", 1;
            }
            $out or skip "Error in pipe(1): $! [$?]", 1;
        }
    } else {
        skip "Could not fork: $!";
    }

    my( $version ) = $out =~ /^.+?([\d._]+)$/m;

    is( $version, $V::VERSION, "Version ok ($version)" );
}

abeltje_done_testing();
