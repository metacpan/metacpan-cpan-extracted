use strict;
use warnings;

use lazy;

use Capture::Tiny qw( capture );
use Test::More import => [qw( diag done_testing is_deeply like )];
use Test::RequiresInternet (
    'cpanmetadb.plackperl.org' => 80,
    'fastapi.metacpan.org'     => 443,
);

my ($cb) = grep { ref $_ eq 'CODE' } @INC;
my ( $stdout, $stderr, @result ) = capture { $cb->( undef, 'Local::404' ) };
my $like_ok = like( $stderr, qr{FAIL}, 'fake module not installed' );
my $is_ok
    = is_deeply( \@result, [], 'returns empty list after install attempt' );

unless ( $like_ok && $is_ok ) {
    diag 'STDOUT: ' . $stdout;
    diag 'STDERR: ' . $stderr;
}

done_testing();
