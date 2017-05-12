#!/usr/bin/perl

use lib 'lib', '../lib';

use strict;
use warnings;

use constant::boolean;
use Test::Mock::Class ':all';
use Test::Assert ':all';

require IO::File;

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

print "OK\n";
