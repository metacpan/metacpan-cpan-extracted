use strict;
use Test::More;
use WebGPU::Direct;

if ( !WebGPU::Direct::XS::HAS_X11 )
{
  plan skip_all => 'Test requires X11';
}

if ( !eval { WebGPU::Direct->new_window_x11( 10, 10 ) } )
{
  plan skip_all => 'Test requires working Wayland';
}

use FindBin qw/$Bin/;
require "$Bin/show_frames.pm";

subtest 'Example X11' => sub
{
  my $xw     = 10;
  my $yh     = 10;
  my $window = WebGPU::Direct->new_window_x11( $xw, $yh );

  test_frames( $window, $xw, $yh );
};

subtest 'X11:Xlib passing' => sub
{
  my $display = eval { require X11::Xlib; X11::Xlib->new };

  if ( !defined $display )
  {
    note $@;
    plan skip_all => 'Test requires installed X11::Xlib';
  }

  X11::Xlib::on_error(sub { die explain(@_) } );

  my $xw     = 10;
  my $yh     = 10;
  my $window = $display->new_window( width => $xw, height => $yh );

  $window->show;

  test_frames( $window, $xw, $yh );
};

subtest 'X11:XCB passing' => sub
{
  my $conn = eval { require X11::XCB::Connection; X11::XCB::Connection->new };

  if ( !defined $conn )
  {
    note $@;
    plan skip_all => 'Test requires installed X11::XCB';
  }

  my $xw     = 10;
  my $yh     = 10;
  my $window = $conn->root->create_child(
    class            => X11::XCB::WINDOW_CLASS_INPUT_OUTPUT(),
    rect             => [ 0, 0, $xw, $yh ],
    background_color => '#FF00FF',
  );

  $window->map;

  test_frames( $window, $xw, $yh );
};

done_testing;
