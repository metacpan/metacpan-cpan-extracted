use strict;
use Test::More;
use WebGPU::Direct;

if ( !WebGPU::Direct::XS::HAS_WAYLAND )
{
  plan skip_all => 'Test requires Wayland';
}

if ( !eval { WebGPU::Direct->new_window_wayland( 10, 10 ) } )
{
  plan skip_all => 'Test requires working Wayland';
}

use FindBin qw/$Bin/;
require "$Bin/show_frames.pm";

subtest 'Example Wayland' => sub
{
  my $xw     = 10;
  my $yh     = 10;
  my $window = WebGPU::Direct->new_window_wayland( $xw, $yh );

  test_frames( $window, $xw, $yh );
};

done_testing;
