######################################################################
# Test suite for FrameGrab
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;

use Test::More;
use Sysadm::Install qw(slurp);
use File::Temp qw(tempfile);
use Log::Log4perl qw(:easy);

my $nof_tests = 6;
plan tests => $nof_tests;

my $canned = "canned";
$canned = "t/canned" unless -d $canned;
my $video = "$canned/plane.avi";

use Video::FrameGrab;

my($tmp_fh, $tmp_file) = tempfile(UNLINK => 1);

SKIP: {
    my $grabber;
    
    eval { $grabber = Video::FrameGrab->new( video => $video ); };

    if($@ =~ /Can't find mplayer/) {
        skip "Mplayer not installed -- skipping all tests", $nof_tests;
    } elsif( $@ ) {
        die $@;
    }

    my $rc = $grabber->snap("00:00:05");
    ok($rc, "frame at 5 secs");

    $rc = $grabber->snap("00:00:08");
    ok($rc, "frame at 8 secs");

    # Test video
    my $meta = $grabber->meta_data( $video );
    is($meta->{"length"}, "10.01", "meta data length");
    is($meta->{video_bitrate}, "144880", "meta data bitrate");

    my @stamps = $grabber->equidistant_snap_times(2);

    is($stamps[0], "00:00:03", "first stamp");
    is($stamps[1], "00:00:06", "second stamp");
};
