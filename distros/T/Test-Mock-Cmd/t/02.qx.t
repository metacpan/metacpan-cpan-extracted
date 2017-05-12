use Test::More tests => 42;

use Test::Mock::Cmd::TestUtils;

use Test::Mock::Cmd::TestUtils::X;

BEGIN {
  SKIP: {
        skip '/bin/echo is required for these tests.', 12 if !-x '/bin/echo';

        my $scalar = qx(/bin/echo qx scalar);
        my @array  = qx(/bin/echo qx array);
        like( $scalar,   qr/qx scalar/, 'qx scalar before mocking' );
        like( $array[0], qr/qx array/,  'qx array before mocking' );

        my $scalara = `/bin/echo back ticks scalar`;
        my @arraya  = `/bin/echo back ticks array`;
        like( $scalara,   qr/back ticks scalar/, 'back ticks scalar before mocking' );
        like( $arraya[0], qr/back ticks array/,  'back ticks array before mocking' );

        my $scalarb = readpipe('/bin/echo readpipe scalar');
        my @arrayb  = readpipe('/bin/echo readpipe array');
        like( $scalarb,   qr/readpipe scalar/, 'readpipe scalar before mocking' );
        like( $arrayb[0], qr/readpipe array/,  'readpipe array before mocking' );

        my $scalarc = Test::Mock::Cmd::TestUtils::X::i_call_qx();
        my @arrayc  = Test::Mock::Cmd::TestUtils::X::i_call_qx();
        like( $scalarc,   qr/QX/, 'qx class scalar before mocking' );
        like( $arrayc[0], qr/QX/, 'qx class array before mocking' );

        my $scalard = Test::Mock::Cmd::TestUtils::X::i_call_backticks();
        my @arrayd  = Test::Mock::Cmd::TestUtils::X::i_call_backticks();
        like( $scalard,   qr/BT/, 'back ticks class scalar before mocking' );
        like( $arrayd[0], qr/BT/, 'back ticks class array before mocking' );

        my $scalare = Test::Mock::Cmd::TestUtils::X::i_call_readpipe('/bin/echo class readpipe scalar');
        my @arraye  = Test::Mock::Cmd::TestUtils::X::i_call_readpipe('/bin/echo class readpipe array');
        like( $scalare,   qr/readpipe scalar/, 'qx class scalar before mocking' );
        like( $arraye[0], qr/readpipe array/,  'qx class array before mocking' );
    }
}

use Test::Mock::Cmd sub {
    my ($cmd) = @_;
    return Test::Mock::Cmd::TestUtils::test_more_is_like_return_42( $cmd, $cmd, $cmd );
};

use Test::Mock::Cmd::TestUtils::Y;

diag("Testing Test::Mock::Cmd $Test::Mock::Cmd::VERSION");

SKIP: {
    skip '/bin/echo is required for these tests.', 30 if !-x '/bin/echo';

    my $scalar = qx(/bin/echo qx scalar);
    my @array  = qx(/bin/echo qx array);
    is( $scalar,   42, 'qx scalar after mocking' );
    is( $array[0], 42, 'qx array after mocking' );

    my $scalara = `/bin/echo back ticks scalar`;
    my @arraya  = `/bin/echo back ticks array`;
    is( $scalara,   42, 'back ticks scalar after mocking' );
    is( $arraya[0], 42, 'back ticks array after mocking' );

    my $scalarb = readpipe('/bin/echo readpipe scalar');
    my @arrayb  = readpipe('/bin/echo readpipe array');
    is( $scalarb,   42, 'readpipe scalar after mocking' );
    is( $arrayb[0], 42, 'readpipe array after mocking' );

    my $scalarc = Test::Mock::Cmd::TestUtils::Y::i_call_qx('/bin/echo class qx scalar');
    my @arrayc  = Test::Mock::Cmd::TestUtils::Y::i_call_qx('/bin/echo class qx array');
    is( $scalarc,   42, 'qx class scalar after mocking' );
    is( $arrayc[0], 42, 'qx class array after mocking' );

    my $scalard = Test::Mock::Cmd::TestUtils::Y::i_call_backticks('/bin/echo class back ticks scalar');
    my @arrayd  = Test::Mock::Cmd::TestUtils::Y::i_call_backticks('/bin/echo class back ticks array');
    is( $scalard,   42, 'back ticks class scalar after mocking' );
    is( $arrayd[0], 42, 'back ticks class array after mocking' );

    my $scalare = Test::Mock::Cmd::TestUtils::Y::i_call_readpipe('/bin/echo class readpipe scalar');
    my @arraye  = Test::Mock::Cmd::TestUtils::Y::i_call_readpipe('/bin/echo class readpipe array');
    is( $scalare,   42, 'qx class scalar after mocking' );
    is( $arraye[0], 42, 'qx class array after mocking' );

    my $scalarf = Test::Mock::Cmd::TestUtils::X::i_call_qx();
    my @arrayf  = Test::Mock::Cmd::TestUtils::X::i_call_qx();
    like( $scalarf,   qr/QX/, 'qx class scalar before mocking - not affected' );
    like( $arrayf[0], qr/QX/, 'qx class array before mocking- not affected' );

    my $scalarg = Test::Mock::Cmd::TestUtils::X::i_call_backticks();
    my @arrayg  = Test::Mock::Cmd::TestUtils::X::i_call_backticks();
    like( $scalarg,   qr/BT/, 'back ticks class scalar before mocking - not affected' );
    like( $arrayg[0], qr/BT/, 'back ticks class array before mocking - not affected' );

    my $scalarh = Test::Mock::Cmd::TestUtils::X::i_call_readpipe('/bin/echo class readpipe scalar');
    my @arrayh  = Test::Mock::Cmd::TestUtils::X::i_call_readpipe('/bin/echo class readpipe array');
    like( $scalarh,   qr/readpipe scalar/, 'qx class scalar before mocking - not affected' );
    like( $arrayh[0], qr/readpipe array/,  'qx class array before mocking - not affected' );
}
