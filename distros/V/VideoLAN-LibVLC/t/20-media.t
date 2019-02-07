use strict;
use warnings;
use Test::More;
use FindBin;
my $datadir= "$FindBin::Bin/data";

use_ok('VideoLAN::LibVLC::Media') || BAIL_OUT;

my $vlc= new_ok( 'VideoLAN::LibVLC', [], 'new instance, no args' );
my $flare= new_ok( 'VideoLAN::LibVLC::Media', [ libvlc => $vlc, path => "$datadir/NASA-solar-flares-2017-04-02.mp4" ], 'new instance' );
$flare->parse;
isa_ok( $flare->metadata, 'HASH', 'metadata' );
note explain $flare->metadata;

done_testing;
