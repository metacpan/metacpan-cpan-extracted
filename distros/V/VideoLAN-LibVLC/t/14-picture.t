use strict;
use warnings;
use Test::More;
use FindBin;
use Scalar::Util 'weaken';
require Devel::Peek;
my $datadir= "$FindBin::Bin/data";

use_ok('VideoLAN::LibVLC') || BAIL_OUT;

my %info= (
	chroma => 'RGBA',
	width => 16,
	height => 10,
	pitch => 64,
	lines => 10,
);
my $picture= new_ok( 'VideoLAN::LibVLC::Picture', [\%info], 'new instance' );
is( $picture->width, 16, 'width' );
is( $picture->height, 10, 'height' );
is( $picture->chroma, 'RGBA', 'chroma' );
is( $picture->pitch(0), 64, 'plane[0]{pitch}' );
is( $picture->lines(0), 10, 'plane[0]{lines}' );
is( $picture->plane(1), undef, 'no plane 1' );
is( ref $picture->plane(0), 'SCALAR', 'plane 0 is scalar ref' );
is( length ${ $picture->plane(0) }, 640, 'pitch 64 * lines 10 = 640' );
weaken($picture);
is( $picture, undef, 'got cleaned up' )
	or Devel::Peek::Dump($picture);

done_testing;
