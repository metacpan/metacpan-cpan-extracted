#This software is Copyright (c) 2017-2018 by faraco.
#
#This is free software, licensed under:
#
#  The MIT (X11) License

use strict;
use warnings;
use Test::More;

use_ok('Moo');
use_ok('Function::Parameters');
use_ok('WebService::Pixabay');
use_ok( 'LWP::Online', 'online' );
use_ok('WebService::Client');
use_ok( 'Data::Dumper', 'Dumper' );

my $true  = 1;
my $false = 0;

# change $AUTHOR TESTING value from $false to $true if you want to do advanced test.
my $AUTHOR_TESTING = $false;

SKIP:
{
    skip "installation testing", 1 unless $AUTHOR_TESTING;

    ok(
        my $pix = WebService::Pixabay->new(
            api_key => $ENV{PIXABAY_KEY}
        )
    );

  SKIP:
    {
        skip "No internet connection", 1 unless online();

        ok( my $img1 = $pix->image_search,
            " image_search method working fine" );
        ok( my $vid1 = $pix->video_search, "video_search method working fine" );

        cmp_ok( $pix->video_search( q => 'fire' )->{total},
            '>=', 0, "custom video_search method total key is bigger than 0" );

        cmp_ok( $pix->image_search( q => 'water' )->{total},
            '>=', 0, "custom image_search method total key is bigger than 0" );
    }
}

done_testing;
