package Test::Mock::Class::ExampleTest;

use Test::Unit::Lite;

use Moose;
extends 'Test::Unit::TestCase';

use constant::boolean;
use Test::Assert ':all';

use Test::Mock::Class ':all';

require IO::File;

sub test_mock_class {
    mock_class 'IO::File' => 'IO::File::Mock';

    my $io = IO::File::Mock->new;
    $io->mock_return( open => TRUE, args => [qr//, 'r'] );
    $io->mock_return( open => undef, args => [qr//, 'w'] );
    $io->mock_return_at( 0, getline => 'root:x:0:0:root:/root:/bin/bash' );
    $io->mock_expect_never( 'close' );

    # ok
    assert_true( $io->open('/etc/passwd', 'r') );

    # first line
    assert_matches( qr/^root:[^:]*:0:0:/, $io->getline );

    # eof
    assert_null( $io->getline );

    # access denied
    assert_false( $io->open('/etc/passwd', 'w') );

    # close was not called
    $io->mock_tally;
};

sub test_meta_mock_class {
    my $mock = mock_anon_class 'IO::File';
    my $io = $mock->new_object;
    $io->mock_return( open => TRUE, args => [qr//, 'r'] );
    $io->mock_return( open => undef, args => [qr//, 'w'] );
    $io->mock_return_at( 0, getline => 'root:x:0:0:root:/root:/bin/bash' );
    $io->mock_expect_never( 'close' );

    # ok
    assert_true( $io->open('/etc/passwd', 'r') );

    # first line
    assert_matches( qr/^root:[^:]*:0:0:/, $io->getline );

    # eof
    assert_null( $io->getline );

    # access denied
    assert_false( $io->open('/etc/passwd', 'w') );

    # close was not called
    $io->mock_tally;
};

1;
