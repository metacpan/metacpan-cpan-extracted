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
use Log::Log4perl qw(:easy);

#Log::Log4perl->easy_init($TRACE);

my $nof_tests = 8;
plan tests => $nof_tests;

my $canned = "canned";
$canned = "t/canned" unless -d $canned;
my $snap = "$canned/croptest-dark.jpg";

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

    is($crop[0], 352, "crop w");
    is($crop[1], 364, "crop h");
    is($crop[2], 0, "crop x");
    is($crop[3], 56, "crop y");

    my @images;

    for my $file (map { "$canned/croptest-$_.jpg" } qw(dark black 
                                                       black white1 
                                                       white2)) {
        my $img = Imager->new(channels => 4);
        $img->read( file => $file );
        push @images, $img;
    }

    $grabber = Video::FrameGrab->new( 
        video => "schtonk",
        test_dont_snap => 1,
    );
    @crop = $grabber->cropdetect_average( -1, { images => \@images });

    is($crop[0], 352, "crop w");
    is($crop[1], 369, "crop h");
    is($crop[2], 0, "crop x");
    is($crop[3], 53, "crop y");

    my $testimg = "$canned/croptest-dark.jpg";
    my $img = Imager->new();
    $img->read( file => $testimg );
    my $cropped = $img->crop(
        width  => $crop[0],
        height => $crop[1],
        left   => $crop[2],
        top    => $crop[3],
    );
    if(get_logger->is_trace) {
        $cropped->write( file => "cropped.jpg" );
    }
};
