use strict;
use Test::More;
use WebGPU::Direct;

if ( !WebGPU::Direct::XS::HAS_WIN32 )
{
  plan skip_all => 'Test requires Windows';
}

use FindBin qw/$Bin/;
require "$Bin/show_frames.pm";

subtest 'Example win32' => sub
{
  my $xw     = 100;
  my $yh     = 100;
  my $window = WebGPU::Direct->new_window_win32( $xw, $yh );

  test_frames( $window, $xw, $yh );
};

done_testing;
