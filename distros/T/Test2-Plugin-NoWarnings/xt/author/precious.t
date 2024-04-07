use strict;
use warnings;

use Test::More;

use Capture::Tiny qw( capture );
use Encode qw( decode );
use FindBin qw( $Bin );

binmode $_, ':encoding(utf-8)'
    for map { Test::More->builder->$_ }
    qw( output failure_output todo_output );

chdir "$Bin/../.."
    or die "Cannot chdir to $Bin/../..: $!";

my ( $out, $err ) = capture { system(qw( precious lint -a )) };
$_ = decode( 'UTF-8', $_ ) for grep {defined} $out, $err;

is( $? >> 8, 0, 'precious lint -a exited with 0' )
    or diag($out);
is( $err, q{}, 'no output to stderr' );

done_testing();
