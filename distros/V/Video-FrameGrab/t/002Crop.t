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

my $nof_tests = 4;
plan tests => $nof_tests;

my $canned = "canned";
$canned = "t/canned" unless -d $canned;
my $snap = "$canned/croptest.jpg";

use Video::FrameGrab;

my($tmp_fh, $tmp_file) = tempfile(UNLINK => 1);

SKIP: {
    my $grabber;
    
    eval { $grabber = Video::FrameGrab->new( video => "otz",
                                             test_dont_snap => 1 ); };

    if($@ =~ /Can't find mplayer/) {
        skip "Mplayer not installed -- skipping all tests", $nof_tests;
    } elsif( $@ ) {
        die $@;
    }

    $grabber->{jpeg_data} = slurp $snap;

    my @crop = $grabber->cropdetect( "00:10:00", 
                                     { algorithm => "schilli" } );

    is($crop[0], 336, "crop w");
    is($crop[1], 358, "crop h");
    is($crop[2], 9, "crop x");
    is($crop[3], 63, "crop y");
};
