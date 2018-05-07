use strict;
use warnings;

use lazy;

use Capture::Tiny qw( capture );
use Test::More;
use Test::RequiresInternet (
    'cpanmetadb.plackperl.org' => 80,
    'fastapi.metacpan.org'     => 443,
);

my ($cb) = grep { ref $_ eq 'CODE' } @INC;
my ( $stdout, $stderr, @result ) = capture { $cb->( undef, 'Local::404' ) };
like( $stderr, qr{FAIL}, 'fake module not installed' );

done_testing();
